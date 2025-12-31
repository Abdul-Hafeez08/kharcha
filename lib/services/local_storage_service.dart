import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyRole = 'role'; // 'admin' or 'user'
  static const String _keyAdminEmail = 'adminEmail';
  static const String _keyUserId = 'userId';

  // Save Admin Login (actually Firebase handles persistence, but we can store role hint)
  // For Admin, Firebase Auth persistence is usually sufficient for the session,
  // but let's store role to distinguish from "User Login" in our hybrid app.
  Future<void> setAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, 'admin');
  }

  // Save User Login
  Future<void> saveUserLogin(String adminEmail, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, 'user');
    await prefs.setString(_keyAdminEmail, adminEmail);
    await prefs.setString(_keyUserId, userId);
  }

  // Get User Data
  Future<Map<String, String>?> getUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyRole) == 'user') {
      return {
        'adminEmail': prefs.getString(_keyAdminEmail) ?? '',
        'userId': prefs.getString(_keyUserId) ?? '',
      };
    }
    return null;
  }

  // Check Role
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // Clear All (Logout)
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
