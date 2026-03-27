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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'symbol': symbol,
      'asset_name': assetName,
      'asset_type': assetType,
      'shares': shares,
      'average_buy_price': averageBuyPrice,
      'last_updated_at': lastUpdatedAt.toIso8601String(),
    };
  }

  factory Holding.fromMap(Map<String, dynamic> map) {
    return Holding(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      symbol: map['symbol'] as String,
      assetName: map['asset_name'] as String,
      assetType: map['asset_type'] as String,
      shares: (map['shares'] as num).toDouble(),
      averageBuyPrice: (map['average_buy_price'] as num).toDouble(),
      lastUpdatedAt: DateTime.parse(map['last_updated_at'] as String),
    );
  }

  double get totalCost => shares * averageBuyPrice;

  bool get isStock => assetType == 'stock';
  bool get isCrypto => assetType == 'crypto';
}
