import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_transaction.dart';

class TransactionRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _txns(String userId) =>
      _db.collection('users').doc(userId).collection('transactions');

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<List<AppTransaction>> findByUser(String userId) async {
    final q =
        await _txns(userId).orderBy('timestamp', descending: true).get();
    return q.docs.map((doc) => AppTransaction.fromFirestore(doc)).toList();
  }

  /// Fetches [limit] transactions ordered by newest first.
  /// Pass [after] (returned from a previous call) to get the next page.
  Future<({List<AppTransaction> items, DocumentSnapshot? cursor})> findPaged(
    String userId, {
    int limit = 40,
    DocumentSnapshot? after,
  }) async {
    Query<Map<String, dynamic>> q = _txns(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (after != null) q = q.startAfterDocument(after);
    final snap = await q.get();
    return (
      items: snap.docs.map((d) => AppTransaction.fromFirestore(d)).toList(),
      cursor: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<int> getXpForPeriod(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final q = await _txns(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return q.docs.fold<int>(
      0,
      (total, doc) =>
          total + ((doc.data()['xpAwarded'] as num?)?.toInt() ?? 0),
    );
  }

  Future<bool> hasAnyTrades(String userId) async {
    final q = await _txns(userId)
        .where('type', whereIn: ['buy', 'sell'])
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> insert(AppTransaction tx) async {
    await _txns(tx.userId).doc(tx.id).set(tx.toFirestore());
  }

  Future<void> deleteAllForUser(String userId) async {
    final batch = _db.batch();
    final q = await _txns(userId).get();
    for (final doc in q.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
