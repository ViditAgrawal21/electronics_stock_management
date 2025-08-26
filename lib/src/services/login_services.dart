import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling user authentication
/// Simple login service for in-house team with hardcoded credentials
class LoginService {
  // Hardcoded credentials for simplicity
  static const String _validUsername = 'TWAIPL';
  static const String _validPassword = '1234';
  
  // Keys for shared preferences
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';
  static const String _usernameKey = 'username';

  /// Authenticate user with provided credentials
  /// Returns true if credentials are valid, false otherwise
  Future<bool> login(String username, String password) async {
    try {
      // Validate credentials
      if (username.trim() == _validUsername && password == _validPassword) {
        // Save login state
        await _saveLoginState(username);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Check login status error: $e');
      return false;
    }
  }

  /// Get the current logged in username
  Future<String?> getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('Get username error: $e');
      return null;
    }
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastLoginKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Get last login time error: $e');
      return null;
    }
  }

  /// Logout user and clear stored data
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_usernameKey);
      // Keep last login time for reference
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// Save login state to shared preferences
  Future<void> _saveLoginState(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_usernameKey, username);
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Save login state error: $e');
    }
  }

  /// Validate username format (basic validation)
  bool isValidUsername(String username) {
    return username.trim().isNotEmpty && username.trim().length >= 3;
  }

  /// Validate password format (basic validation)
  bool isValidPassword(String password) {
    return password.isNotEmpty && password.length >= 4;
  }

  /// Clear all login data (for testing or reset purposes)
  Future<void> clearLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_lastLoginKey);
    } catch (e) {
      print('Clear login data error: $e');
    }
  }
}