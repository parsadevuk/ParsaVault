import 'package:cloud_firestore/cloud_firestore.dart';

class Holding {
  final String id;
  final String userId;
  final String symbol;
  final String assetName;
  final String assetType; // 'stock' or 'crypto'
  final double shares;
  final double averageBuyPrice;
  final DateTime lastUpdatedAt;

  const Holding({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.assetName,
    required this.assetType,
    required this.shares,
    required this.averageBuyPrice,
    required this.lastUpdatedAt,
  });

  Holding copyWith({
    String? id,
    String? userId,
    String? symbol,
    String? assetName,
    String? assetType,
    double? shares,
    double? averageBuyPrice,
    DateTime? lastUpdatedAt,
  }) {
    return Holding(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      shares: shares ?? this.shares,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  // ── Firestore ──────────────────────────────────────────────────────────────
  // Document ID in Firestore is the symbol; userId is implied by the collection path.

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'symbol': symbol,
      'assetName': assetName,
      'assetType': assetType,
      'shares': shares,
      'averageBuyPrice': averageBuyPrice,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  factory Holding.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    return Holding(
      id: data['id'] as String? ?? doc.id,
      userId: userId,
      symbol: data['symbol'] as String? ?? doc.id,
      assetName: data['assetName'] as String? ?? '',
      assetType: data['assetType'] as String? ?? 'stock',
      shares: (data['shares'] as num?)?.toDouble() ?? 0.0,
      averageBuyPrice: (data['averageBuyPrice'] as num?)?.toDouble() ?? 0.0,
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate() ??
          DateTime.now().toUtc(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double get totalCost => shares * averageBuyPrice;

  bool get isStock => assetType == 'stock';
  bool get isCrypto => assetType == 'crypto';
}
