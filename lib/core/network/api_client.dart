import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../../data/datasources/auth_local_datasource.dart';

class ApiClient {
  late final Dio _dio;
  final AuthLocalDataSource _auth;

  ApiClient(this._auth) {
    _dio = Dio(BaseOptions(
      baseUrl:         ApiConstants.baseUrl,
      connectTimeout:  const Duration(seconds: 10),
      receiveTimeout:  const Duration(seconds: 15),
      contentType:     'application/json',
    ));
    _dio.interceptors.add(_AuthInterceptor(_auth));
  }

  Future<Response<T>> get<T>(String path) => _dio.get(path);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  /// Public — used for register (no auth header needed)
  Future<Response<T>> postPublic<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data,
          options: Options(headers: {'skipAuth': true}));
}

class _AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _auth;
  _AuthInterceptor(this._auth);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    
    // Phase 1: Research - Registration is the only public endpoint except health
    final bool isPublicEndpoint = options.path.contains('/register') || 
                                  options.path.contains('/health');

    if (!isPublicEndpoint) {
      final token = await _auth.getIdToken(); // Phase 2: Retrieve from Local DS
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        // Phase 3: Audit - Handle missing token before request leaves
        return handler.reject(DioException(
          requestOptions: options,
          error: const AuthException('No authentication token found.'),
        ));
      }
    }
    
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 401) {
      // Token expired — caller gets AuthException; UserBloc can clear & re-prompt
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: const AuthException('Session expired. Please re-enter your name.'),
      ));
      return;
    }
    handler.next(err);
  }
}
