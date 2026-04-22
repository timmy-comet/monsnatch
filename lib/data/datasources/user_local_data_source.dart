import 'package:shared_preferences/shared_preferences.dart';

class UserLocalDataSource {
  static const _keyName = 'username';
  static const _keyGuest = 'is_guest';

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();

    // mock data, pls replace
    return prefs.getString(_keyName);
  }

  Future<bool> getIsGuest() async {
    final prefs = await SharedPreferences.getInstance();

    // mock data, pls replace
    return prefs.getBool(_keyGuest) ?? true;
  }

  Future<void> saveUser(String username) async {
    final prefs = await SharedPreferences.getInstance();

    // mock data, pls replace
    await prefs.setString(_keyName, username);
    await prefs.setBool(_keyGuest, true);
  }
}