import 'dart:math';
import '../../models/asset.dart';

class MarketService {
  static final _random = Random();

  // ── 20 Most Popular Stocks ─────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _stockData = [
    {'symbol': 'AAPL', 'name': 'Apple Inc', 'basePrice': 178.50},
    {'symbol': 'MSFT', 'name': 'Microsoft', 'basePrice': 415.20},
    {'symbol': 'GOOGL', 'name': 'Alphabet', 'basePrice': 175.80},
    {'symbol': 'AMZN', 'name': 'Amazon', 'basePrice': 228.40},
    {'symbol': 'NVDA', 'name': 'NVIDIA', 'basePrice': 875.30},
    {'symbol': 'META', 'name': 'Meta Platforms', 'basePrice': 565.70},
    {'symbol': 'TSLA', 'name': 'Tesla', 'basePrice': 245.60},
    {'symbol': 'NFLX', 'name': 'Netflix', 'basePrice': 785.40},
    {'symbol': 'AMD', 'name': 'AMD', 'basePrice': 162.30},
    {'symbol': 'INTC', 'name': 'Intel', 'basePrice': 22.80},
    {'symbol': 'DIS', 'name': 'Disney', 'basePrice': 89.50},
    {'symbol': 'PYPL', 'name': 'PayPal', 'basePrice': 65.20},
    {'symbol': 'UBER', 'name': 'Uber', 'basePrice': 74.30},
    {'symbol': 'SPOT', 'name': 'Spotify', 'basePrice': 425.60},
    {'symbol': 'SHOP', 'name': 'Shopify', 'basePrice': 95.40},
    {'symbol': 'CRM', 'name': 'Salesforce', 'basePrice': 312.80},
    {'symbol': 'BABA', 'name': 'Alibaba', 'basePrice': 84.20},
    {'symbol': 'BA', 'name': 'Boeing', 'basePrice': 175.40},
    {'symbol': 'JPM', 'name': 'JPMorgan Chase', 'basePrice': 245.80},
    {'symbol': 'V', 'name': 'Visa', 'basePrice': 345.20},
  ];

  // ── 20 Most Popular Cryptos ────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _cryptoData = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'basePrice': 67500.0},
    {'symbol': 'ETH', 'name': 'Ethereum', 'basePrice': 3550.0},
    {'symbol': 'BNB', 'name': 'Binance Coin', 'basePrice': 420.0},
    {'symbol': 'SOL', 'name': 'Solana', 'basePrice': 185.0},
    {'symbol': 'XRP', 'name': 'XRP', 'basePrice': 0.62},
    {'symbol': 'ADA', 'name': 'Cardano', 'basePrice': 0.48},
    {'symbol': 'DOGE', 'name': 'Dogecoin', 'basePrice': 0.165},
    {'symbol': 'AVAX', 'name': 'Avalanche', 'basePrice': 38.50},
    {'symbol': 'DOT', 'name': 'Polkadot', 'basePrice': 7.20},
    {'symbol': 'MATIC', 'name': 'Polygon', 'basePrice': 0.82},
    {'symbol': 'LINK', 'name': 'Chainlink', 'basePrice': 14.80},
    {'symbol': 'UNI', 'name': 'Uniswap', 'basePrice': 8.45},
    {'symbol': 'ATOM', 'name': 'Cosmos', 'basePrice': 9.20},
    {'symbol': 'LTC', 'name': 'Litecoin', 'basePrice': 82.50},
    {'symbol': 'BCH', 'name': 'Bitcoin Cash', 'basePrice': 425.0},
    {'symbol': 'XLM', 'name': 'Stellar', 'basePrice': 0.115},
    {'symbol': 'ALGO', 'name': 'Algorand', 'basePrice': 0.195},
    {'symbol': 'VET', 'name': 'VeChain', 'basePrice': 0.038},
    {'symbol': 'FIL', 'name': 'Filecoin', 'basePrice': 5.80},
    {'symbol': 'SAND', 'name': 'The Sandbox', 'basePrice': 0.42},
  ];

  /// Generate all 40 assets with randomized price history.
  List<Asset> generateAssets() {
    final assets = <Asset>[];

    for (final data in _stockData) {
      assets.add(_buildAsset(data, 'stock'));
    }
    for (final data in _cryptoData) {
      assets.add(_buildAsset(data, 'crypto'));
    }

    return assets;
  }

  Asset _buildAsset(Map<String, dynamic> data, String type) {
    final basePrice = (data['basePrice'] as num).toDouble();
    final history = _generatePriceHistory(basePrice);
    final openPrice = history.first.price;
    final currentPrice = history.last.price;
    final change24h = currentPrice - openPrice;
    final changePercent = (change24h / openPrice) * 100;

    return Asset(
      symbol: data['symbol'] as String,
      name: data['name'] as String,
      type: type,
      currentPrice: currentPrice,
      change24h: change24h,
      changePercent24h: changePercent,
      priceHistory: history,
    );
  }

  /// 48 points over 24 hours (every 30 min). Total swing 5–20%.
  List<PricePoint> _generatePriceHistory(double basePrice) {
    final now = DateTime.now();
    final points = <PricePoint>[];

    // Random starting offset: ±5% from base
    double price = basePrice * (1 + (_random.nextDouble() * 0.10 - 0.05));

    // Decide on a drift direction for the day (slightly bullish or bearish)
    final dailyDrift = (_random.nextDouble() * 0.20 - 0.10); // -10% to +10%

    for (int i = 47; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * 30));

      // Drift toward the daily target, plus random noise
      final driftStep = dailyDrift / 48;
      final noise = (_random.nextDouble() * 0.008) - 0.004; // ±0.4% noise
      price = price * (1 + driftStep + noise);

      // Hard clamp: never go outside 5–20% range from base
      price = price.clamp(basePrice * 0.80, basePrice * 1.20);

      points.add(PricePoint(timestamp: timestamp, price: price));
    }

    return points;
  }

  /// Tick an existing asset price by a small random amount (±0.5%).
  Asset tickPrice(Asset asset) {
    final change = (_random.nextDouble() * 0.010) - 0.005;
    final newPrice = (asset.currentPrice * (1 + change))
        .clamp(asset.priceHistory.first.price * 0.80,
            asset.priceHistory.first.price * 1.20);

    final openPrice = asset.priceHistory.first.price;
    final change24h = newPrice - openPrice;
    final changePercent = (change24h / openPrice) * 100;

    final newHistory = [
      ...asset.priceHistory.skip(1),
      PricePoint(timestamp: DateTime.now(), price: newPrice),
    ];

    return asset.copyWith(
      currentPrice: newPrice,
      change24h: change24h,
      changePercent24h: changePercent,
      priceHistory: newHistory,
    );
  }
}
