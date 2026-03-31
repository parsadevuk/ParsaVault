import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransaction {
  final String id;
  final String userId;
  final String type; // 'buy', 'sell', 'deposit', 'withdraw'
  final String? symbol;
  final String? assetName;
  final String? assetType;
  final double? shares;
  final double? priceAtTime;
  final double totalAmount;
  final int xpAwarded;
  final double? profitOrLoss;
  final DateTime timestamp;

  const AppTransaction({
    required this.id,
    required this.userId,
    required this.type,
    this.symbol,
    this.assetName,
    this.assetType,
    this.shares,
    this.priceAtTime,
    required this.totalAmount,
    required this.xpAwarded,
    this.profitOrLoss,
    required this.timestamp,
  });

  // ── Firestore ──────────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'symbol': symbol,
      'assetName': assetName,
      'assetType': assetType,
      'shares': shares,
      'priceAtTime': priceAtTime,
      'totalAmount': totalAmount,
      'xpAwarded': xpAwarded,
      'profitOrLoss': profitOrLoss,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AppTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppTransaction(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      symbol: data['symbol'] as String?,
      assetName: data['assetName'] as String?,
      assetType: data['assetType'] as String?,
      shares: (data['shares'] as num?)?.toDouble(),
      priceAtTime: (data['priceAtTime'] as num?)?.toDouble(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      xpAwarded: (data['xpAwarded'] as num?)?.toInt() ?? 0,
      profitOrLoss: (data['profitOrLoss'] as num?)?.toDouble(),
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get isBuy => type == 'buy';
  bool get isSell => type == 'sell';
  bool get isDeposit => type == 'deposit';
  bool get isWithdraw => type == 'withdraw';
  bool get isTrade => isBuy || isSell;

  String get typeLabel {
    switch (type) {
      case 'buy':
        return 'BUY';
      case 'sell':
        return 'SELL';
      case 'deposit':
        return 'DEPOSIT';
      case 'withdraw':
        return 'WITHDRAW';
      default:
        return type.toUpperCase();
    }
  }
}
