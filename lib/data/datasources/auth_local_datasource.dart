import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  static const _uid      = 'auth_uid';
  static const _username = 'auth_username';
  static const _token    = 'auth_token';
  static const _tokenAt  = 'auth_token_at'; // epoch ms

  Future<void> saveAuth({
    required String uid,
    required String username,
    required String idToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_uid,      uid),
      prefs.setString(_username, username),
      prefs.setString(_token,    idToken),
      prefs.setInt(   _tokenAt,  DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  Future<String?> getUid() async =>
      (await SharedPreferences.getInstance()).getString(_uid);

  Future<String?> getUsername() async =>
      (await SharedPreferences.getInstance()).getString(_username);

  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token  = prefs.getString(_token);
    final issuedAt = prefs.getInt(_tokenAt) ?? 0;
    if (token == null) return null;
    // Treat token as expired after 50 min (server expires at ~60 min)
    final age = DateTime.now().millisecondsSinceEpoch - issuedAt;
    if (age > const Duration(minutes: 50).inMilliseconds) {
      return null; // signal caller to re-register
    }
    return token;
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_uid),
      prefs.remove(_username),
      prefs.remove(_token),
      prefs.remove(_tokenAt),
    ]);
  }

  Future<bool> hasValidAuth() async =>
      (await getIdToken()) != null;
}