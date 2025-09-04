import '../constants/app_config.dart';
import '../models/user.dart';

class LoginService {
  static User? _currentUser;

  // Authenticate user with provided credentials
  static Future<bool> authenticate(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Check credentials against default values
    if (username == AppConfig.defaultUsername &&
        password == AppConfig.defaultPassword) {
      _currentUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        loginTime: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      return true;
    }

    return false;
  }

  // Get current authenticated user
  static User? getCurrentUser() {
    return _currentUser;
  }

  // Check if user is currently logged in
  static bool isLoggedIn() {
    return _currentUser != null;
  }

  // Update last activity time
  static void updateLastActivity() {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(lastActivity: DateTime.now());
    }
  }

  // Logout user
  static void logout() {
    _currentUser = null;
  }

  // Get session duration
  static Duration? getSessionDuration() {
    return _currentUser?.sessionDuration;
  }

  // Check if user session is active
  static bool isSessionActive() {
    return _currentUser?.isActive ?? false;
  }

  // Validate session (check if user is still active)
  static bool validateSession() {
    if (_currentUser == null) return false;

    // Update activity and check if still active
    updateLastActivity();
    return isSessionActive();
  }
}
