import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ── Firestore ──────────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      'website': website,
      'cashBalance': cashBalance,
      'xp': xp,
      'level': level,
      'profilePicture': profilePicture,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      website: data['website'] as String?,
      passwordHash: '',
      cashBalance: (data['cashBalance'] as num?)?.toDouble() ?? 0.0,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      profilePicture: data['profilePicture'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
