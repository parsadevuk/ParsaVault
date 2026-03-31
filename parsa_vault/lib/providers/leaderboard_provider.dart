import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

/// Streams all users ordered by XP descending — updates live.
final leaderboardProvider = StreamProvider<List<User>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('xp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
});
