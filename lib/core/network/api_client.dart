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
    _dio.interceptors.add(_AuthInterceptor(_auth, _refresh));
  }

  Future<Response<T>> get<T>(String path) => _dio.get(path);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  /// Public — used for register/refresh (no auth header needed)
  Future<Response<T>> postPublic<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data,
          options: Options(headers: {'skipAuth': true}));

  // Single in-flight refresh so concurrent requests don't pile on /refresh.
  Future<bool>? _inFlightRefresh;

  Future<bool> _refresh() {
    final pending = _inFlightRefresh;
    if (pending != null) return pending;
    final fut = _doRefresh();
    _inFlightRefresh = fut;
    return fut.whenComplete(() => _inFlightRefresh = null);
  }

  Future<bool> _doRefresh() async {
    final rt = await _auth.getRefreshToken();
    if (rt == null) return false;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/refresh',
        data: {'refreshToken': rt},
        options: Options(headers: {'skipAuth': true}),
      );
      final data = res.data!;
      await _auth.saveTokens(
        idToken:      data['idToken']      as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on DioException {
      await _auth.clearAuth();
      return false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _auth;
  final Future<bool> Function() _refresh;
  _AuthInterceptor(this._auth, this._refresh);

  bool _isPublic(RequestOptions options) {
    if (options.headers.remove('skipAuth') != null) return true;
    return options.path.contains('/register') ||
           options.path.contains('/refresh')  ||
           options.path.contains('/health');
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {

    if (_isPublic(options)) return handler.next(options);

    var token = await _auth.getIdToken();
    if (token == null) {
      // Stale or missing — try a refresh before failing.
      if (await _refresh()) {
        token = await _auth.getIdToken();
      }
    }

    if (token == null) {
      return handler.reject(DioException(
        requestOptions: options,
        error: const AuthException('No authentication token found.'),
      ));
    }

    options.headers['Authorization'] = 'Bearer $token';
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;
    final alreadyRetried = req.extra['_retried'] == true;

    // 401 on a non-public request: try one refresh + retry, then surface auth error.
    if (status == 401 && !_isPublic(req) && !alreadyRetried) {
      if (await _refresh()) {
        final token = await _auth.getIdToken();
        if (token != null) {
          final retryOpts = Options(
            method: req.method,
            headers: {...req.headers, 'Authorization': 'Bearer $token'},
            contentType: req.contentType,
            responseType: req.responseType,
          );
          try {
            final resp = await Dio(BaseOptions(baseUrl: req.baseUrl)).request(
              req.path,
              data: req.data,
              queryParameters: req.queryParameters,
              options: retryOpts..extra = {...req.extra, '_retried': true},
            );
            return handler.resolve(resp);
          } on DioException catch (e) {
            return handler.reject(e);
          }
        }
      }
      return handler.reject(DioException(
        requestOptions: req,
        error: const AuthException('Session expired. Please re-enter your name.'),
      ));
    }

    if (status == 401) {
      return handler.reject(DioException(
        requestOptions: req,
        error: const AuthException('Session expired. Please re-enter your name.'),
      ));
    }

    handler.next(err);
  }
}
