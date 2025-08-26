import 'dart:convert';

class User {
  final String username;
  final String password;
  final DateTime? lastLoginTime;
  final bool isLoggedIn;

  const User({
    required this.username,
    required this.password,
    this.lastLoginTime,
    this.isLoggedIn = false,
  });

  // Create a copy of User with updated fields
  User copyWith({
    String? username,
    String? password,
    DateTime? lastLoginTime,
    bool? isLoggedIn,
  }) {
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  // Convert User to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'lastLoginTime': lastLoginTime?.millisecondsSinceEpoch,
      'isLoggedIn': isLoggedIn,
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      lastLoginTime: map['lastLoginTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginTime'])
          : null,
      isLoggedIn: map['isLoggedIn'] ?? false,
    );
  }

  // Convert to JSON string
  String toJson() => jsonEncode(toMap());

  // Create User from JSON string
  factory User.fromJson(String source) => User.fromMap(jsonDecode(source));

  // Default hardcoded user for your in-house team
  static const User defaultUser = User(
    username: 'TWAIPL',
    password: '1234',
  );

  // Validate login credentials
  bool validateCredentials(String inputUsername, String inputPassword) {
    return username.toLowerCase() == inputUsername.toLowerCase() && 
           password == inputPassword;
  }

  // Check if user session is still valid (optional for future use)
  bool isSessionValid({Duration sessionDuration = const Duration(hours: 8)}) {
    if (!isLoggedIn || lastLoginTime == null) return false;
    
    final now = DateTime.now();
    final sessionExpiry = lastLoginTime!.add(sessionDuration);
    
    return now.isBefore(sessionExpiry);
  }

  @override
  String toString() {
    return 'User(username: $username, isLoggedIn: $isLoggedIn, lastLoginTime: $lastLoginTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is User &&
      other.username == username &&
      other.password == password &&
      other.lastLoginTime == lastLoginTime &&
      other.isLoggedIn == isLoggedIn;
  }

  @override
  int get hashCode {
    return username.hashCode ^
      password.hashCode ^
      lastLoginTime.hashCode ^
      isLoggedIn.hashCode;
  }
}

// Extension for easy user operations
extension UserExtension on User {
  // Get display name (capitalize first letter)
  String get displayName {
    if (username.isEmpty) return '';
    return username[0].toUpperCase() + username.substring(1).toLowerCase();
  }

  // Get login status message
  String get statusMessage {
    if (!isLoggedIn) return 'Not logged in';
    if (lastLoginTime == null) return 'Logged in';
    
    final now = DateTime.now();
    final difference = now.difference(lastLoginTime!);
    
    if (difference.inMinutes < 1) return 'Just logged in';
    if (difference.inHours < 1) return 'Logged in ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Logged in ${difference.inHours}h ago';
    
    return 'Logged in ${difference.inDays}d ago';
  }
}