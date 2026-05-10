import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyLoggedIn = 'is_logged_in';
  static const _keySessionUser = 'session_username';
  static const _keyStoredUser = 'stored_username';
  static const _keyStoredPass = 'stored_password';

  // Returns prefs with default credentials seeded if first launch.
  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyStoredUser)) {
      await prefs.setString(_keyStoredUser, 'user');
    }
    if (!prefs.containsKey(_keyStoredPass)) {
      await prefs.setString(_keyStoredPass, 'user');
    }
    return prefs;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await _prefs();
    final storedUser = prefs.getString(_keyStoredUser) ?? 'user';
    final storedPass = prefs.getString(_keyStoredPass) ?? 'user';
    if (username == storedUser && password == storedPass) {
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keySessionUser, username);
      return true;
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionUser) ?? 'user';
  }

  Future<bool> changePassword(String current, String newPass) async {
    final prefs = await _prefs();
    final stored = prefs.getString(_keyStoredPass) ?? 'user';
    if (current != stored) return false;
    await prefs.setString(_keyStoredPass, newPass);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keySessionUser);
  }
}
