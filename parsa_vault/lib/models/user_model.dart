class UserModel {
  final int? id;
  final String fullName;
  final String username;
  final String email;
  final String? website;
  final String passwordHash;
  final double cashBalance;
  final int xp;
  final int level;
  final String createdAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.website,
    required this.passwordHash,
    this.cashBalance = 10000.0,
    this.xp = 0,
    this.level = 1,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'website': website,
      'password_hash': passwordHash,
      'cash_balance': cashBalance,
      'xp': xp,
      'level': level,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      website: map['website'] as String?,
      passwordHash: map['password_hash'] as String,
      cashBalance: (map['cash_balance'] as num).toDouble(),
      xp: map['xp'] as int,
      level: map['level'] as int,
      createdAt: map['created_at'] as String,
    );
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? username,
    String? email,
    String? website,
    String? passwordHash,
    double? cashBalance,
    int? xp,
    int? level,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      website: website ?? this.website,
      passwordHash: passwordHash ?? this.passwordHash,
      cashBalance: cashBalance ?? this.cashBalance,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
