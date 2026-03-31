import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/holding.dart';

class HoldingRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _holdings(String userId) =>
      _db.collection('users').doc(userId).collection('holdings');

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<List<Holding>> findByUser(String userId) async {
    final q = await _holdings(userId)
        .orderBy('lastUpdatedAt', descending: true)
        .get();
    return q.docs.map((doc) => Holding.fromFirestore(doc, userId)).toList();
  }

  Future<Holding?> findByUserAndSymbol(String userId, String symbol) async {
    final doc = await _holdings(userId).doc(symbol).get();
    if (!doc.exists) return null;
    return Holding.fromFirestore(doc, userId);
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Upserts using symbol as the document ID.
  Future<void> upsert(Holding holding) async {
    await _holdings(holding.userId).doc(holding.symbol).set(holding.toFirestore());
  }

  Future<void> update(Holding holding) async {
    await _holdings(holding.userId)
        .doc(holding.symbol)
        .set(holding.toFirestore());
  }

  /// Deletes a holding by userId + symbol.
  Future<void> deleteBySymbol(String userId, String symbol) async {
    await _holdings(userId).doc(symbol).delete();
  }

  Future<void> deleteAllForUser(String userId) async {
    final batch = _db.batch();
    final q = await _holdings(userId).get();
    for (final doc in q.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
