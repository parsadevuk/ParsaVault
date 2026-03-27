class PricePoint {
  final DateTime timestamp;
  final double price;

  const PricePoint({required this.timestamp, required this.price});
}

class Asset {
  final String symbol;
  final String name;
  final String type; // 'stock' or 'crypto'
  final double currentPrice;
  final double change24h;
  final double changePercent24h;
  final List<PricePoint> priceHistory;

  const Asset({
    required this.symbol,
    required this.name,
    required this.type,
    required this.currentPrice,
    required this.change24h,
    required this.changePercent24h,
    required this.priceHistory,
  });

  Asset copyWith({
    String? symbol,
    String? name,
    String? type,
    double? currentPrice,
    double? change24h,
    double? changePercent24h,
    List<PricePoint>? priceHistory,
  }) {
    return Asset(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      currentPrice: currentPrice ?? this.currentPrice,
      change24h: change24h ?? this.change24h,
      changePercent24h: changePercent24h ?? this.changePercent24h,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  bool get isStock => type == 'stock';
  bool get isCrypto => type == 'crypto';
  bool get isUp => changePercent24h >= 0;
}
