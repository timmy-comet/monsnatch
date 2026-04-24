abstract class ApiConstants {
  /// Change this one line to switch environments.
  /// Local dev : 'http://localhost:4001'
  /// Cloudflare : 'https://taste-truth-landscape-levy.trycloudflare.com'
  static const String baseUrl ='https://robot-olive-architectural-information.trycloudflare.com';

  /// WebSocket base — same host, protocol swapped https → wss
  static String get wsBaseUrl =>
      baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
}