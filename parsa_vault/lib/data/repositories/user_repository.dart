import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<User?> findById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc);
  }

  Future<User?> findByEmail(String email) async {
    final q = await _users
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return User.fromFirestore(q.docs.first);
  }

  Future<User?> findByUsername(String username) async {
    final q = await _users
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return User.fromFirestore(q.docs.first);
  }

  Future<User?> findByEmailOrUsername(String value) async {
    final lower = value.toLowerCase().trim();
    final byEmail = await findByEmail(lower);
    if (byEmail != null) return byEmail;
    return findByUsername(lower);
  }

  Future<bool> emailExists(String email) async =>
      (await findByEmail(email)) != null;

  Future<bool> usernameExists(String username) async =>
      (await findByUsername(username)) != null;

  Future<bool> anyUsersExist() async {
    final q = await _users.limit(1).get();
    return q.docs.isNotEmpty;
  }

  /// Returns all users ordered by XP descending (for leaderboard).
  Future<List<User>> getAllByXp() async {
    final q = await _users.orderBy('xp', descending: true).get();
    return q.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> insert(User user) async {
    await _users.doc(user.id).set(user.toFirestore());
  }

  Future<void> update(User user) async {
    await _users.doc(user.id).set(user.toFirestore());
  }

  Future<void> updateFinancials({
    required String userId,
    required double cashBalance,
    required int xp,
    required int level,
  }) async {
    await _users.doc(userId).update({
      'cashBalance': cashBalance,
      'xp': xp,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLastLogin(String userId) async {
    await _users.doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUsername(String userId, String username) async {
    await _users.doc(userId).update({
      'username': username.trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfilePicture(String userId, String? base64Image) async {
    await _users.doc(userId).update({
      'profilePicture': base64Image,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWebsite(String userId, String? website) async {
    await _users.doc(userId).update({
      'website':
          website?.trim().isNotEmpty == true ? website!.trim() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
