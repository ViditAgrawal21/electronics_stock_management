class User {
  final String id;
  final String username;
  final DateTime loginTime;
  final DateTime? lastActivity;

  User({
    required this.id,
    required this.username,
    required this.loginTime,
    this.lastActivity,
  });

  // Check if user is currently active (within last 30 minutes)
  bool get isActive {
    if (lastActivity == null) return false;
    return DateTime.now().difference(lastActivity!).inMinutes <= 30;
  }

  // Get session duration
  Duration get sessionDuration {
    final endTime = lastActivity ?? DateTime.now();
    return endTime.difference(loginTime);
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      loginTime: DateTime.parse(
        json['loginTime'] ?? DateTime.now().toIso8601String(),
      ),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'loginTime': loginTime.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }

  // Copy with method
  User copyWith({
    String? id,
    String? username,
    DateTime? loginTime,
    DateTime? lastActivity,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      loginTime: loginTime ?? this.loginTime,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
