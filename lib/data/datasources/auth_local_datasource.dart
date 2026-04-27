import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  static const _uid          = 'auth_uid';
  static const _username     = 'auth_username';
  static const _token        = 'auth_token';
  static const _tokenAt      = 'auth_token_at'; // epoch ms
  static const _refreshToken = 'auth_refresh_token';

  // Refresh proactively when this many ms (or fewer) of expected lifetime remain.
  // Server-issued tokens last ~60 min; refresh once we cross the 50-min mark.
  static const _refreshAfterMs = 50 * 60 * 1000;

  Future<void> saveAuth({
    required String uid,
    required String username,
    required String idToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_uid,          uid),
      prefs.setString(_username,     username),
      prefs.setString(_token,        idToken),
      prefs.setString(_refreshToken, refreshToken),
      prefs.setInt(   _tokenAt,      DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  Future<void> saveTokens({
    required String idToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_token,        idToken),
      prefs.setString(_refreshToken, refreshToken),
      prefs.setInt(   _tokenAt,      DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  Future<String?> getUid() async =>
      (await SharedPreferences.getInstance()).getString(_uid);

  Future<String?> getUsername() async =>
      (await SharedPreferences.getInstance()).getString(_username);

  /// Returns the stored ID token only if it's still considered fresh.
  /// Callers that want to refresh-on-stale should use `getRefreshToken()`
  /// and call `/refresh` themselves.
  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_token);
    final issuedAt = prefs.getInt(_tokenAt) ?? 0;
    if (token == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - issuedAt;
    if (age > _refreshAfterMs) return null;
    return token;
  }

  Future<String?> getRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshToken);

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_uid),
      prefs.remove(_username),
      prefs.remove(_token),
      prefs.remove(_tokenAt),
      prefs.remove(_refreshToken),
    ]);
  }

  /// True if we have either a fresh ID token or a refresh token we can use.
  Future<bool> hasValidAuth() async {
    if ((await getIdToken()) != null) return true;
    return (await getRefreshToken()) != null;
  }
}
