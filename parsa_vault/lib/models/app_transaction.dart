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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'symbol': symbol,
      'asset_name': assetName,
      'asset_type': assetType,
      'shares': shares,
      'price_at_time': priceAtTime,
      'total_amount': totalAmount,
      'xp_awarded': xpAwarded,
      'profit_or_loss': profitOrLoss,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      symbol: map['symbol'] as String?,
      assetName: map['asset_name'] as String?,
      assetType: map['asset_type'] as String?,
      shares: map['shares'] != null ? (map['shares'] as num).toDouble() : null,
      priceAtTime: map['price_at_time'] != null
          ? (map['price_at_time'] as num).toDouble()
          : null,
      totalAmount: (map['total_amount'] as num).toDouble(),
      xpAwarded: map['xp_awarded'] as int,
      profitOrLoss: map['profit_or_loss'] != null
          ? (map['profit_or_loss'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

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
