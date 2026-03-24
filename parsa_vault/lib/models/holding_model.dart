class HoldingModel {
  final int? id;
  final int userId;
  final String symbol;
  final String name;
  final double shares;
  final double averageBuyPrice;

  HoldingModel({
    this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.shares,
    required this.averageBuyPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'symbol': symbol,
      'name': name,
      'shares': shares,
      'average_buy_price': averageBuyPrice,
    };
  }

  factory HoldingModel.fromMap(Map<String, dynamic> map) {
    return HoldingModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      shares: (map['shares'] as num).toDouble(),
      averageBuyPrice: (map['average_buy_price'] as num).toDouble(),
    );
  }

  HoldingModel copyWith({
    int? id,
    int? userId,
    String? symbol,
    String? name,
    double? shares,
    double? averageBuyPrice,
  }) {
    return HoldingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      shares: shares ?? this.shares,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
    );
  }
}
