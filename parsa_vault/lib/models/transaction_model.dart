class TransactionModel {
  final int? id;
  final int userId;
  final String symbol;
  final String name;
  final String type; // 'buy' or 'sell'
  final double shares;
  final double pricePerShare;
  final double totalValue;
  final String createdAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.type,
    required this.shares,
    required this.pricePerShare,
    required this.totalValue,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'symbol': symbol,
      'name': name,
      'type': type,
      'shares': shares,
      'price_per_share': pricePerShare,
      'total_value': totalValue,
      'created_at': createdAt,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      shares: (map['shares'] as num).toDouble(),
      pricePerShare: (map['price_per_share'] as num).toDouble(),
      totalValue: (map['total_value'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }
}
