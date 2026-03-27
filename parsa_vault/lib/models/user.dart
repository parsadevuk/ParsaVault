class User {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? website;
  final String passwordHash;
  final double cashBalance;
  final int xp;
  final int level;
  final String? profilePicture; // base64 encoded image
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.website,
    required this.passwordHash,
    required this.cashBalance,
    required this.xp,
    required this.level,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? website,
    bool clearWebsite = false,
    String? passwordHash,
    double? cashBalance,
    int? xp,
    int? level,
    String? profilePicture,
    bool clearProfilePicture = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      website: clearWebsite ? null : (website ?? this.website),
      passwordHash: passwordHash ?? this.passwordHash,
      cashBalance: cashBalance ?? this.cashBalance,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      profilePicture:
          clearProfilePicture ? null : (profilePicture ?? this.profilePicture),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'website': website,
      'password_hash': passwordHash,
      'cash_balance': cashBalance,
      'xp': xp,
      'level': level,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      website: map['website'] as String?,
      passwordHash: map['password_hash'] as String,
      cashBalance: (map['cash_balance'] as num).toDouble(),
      xp: map['xp'] as int,
      level: map['level'] as int,
      profilePicture: map['profile_picture'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
    );
  }

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
