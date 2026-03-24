import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String alphaVantageApiKey = 'YOUR_ALPHA_VANTAGE_API_KEY';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String coinbaseBaseUrl = 'https://api.coinbase.com/v2';

  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  Future<double?> fetchStockPrice(String symbol) async {
    try {
      final uri = Uri.parse(
        '$alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageApiKey',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = data['Global Quote'];
        if (quote != null && quote['05. price'] != null) {
          return double.tryParse(quote['05. price']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchStockQuote(String symbol) async {
    try {
      final uri = Uri.parse(
        '$alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageApiKey',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = data['Global Quote'];
        if (quote != null) {
          final price = double.tryParse(quote['05. price'] ?? '');
          final change = double.tryParse(quote['09. change'] ?? '');
          final changePercent =
              double.tryParse((quote['10. change percent'] ?? '').replaceAll('%', ''));
          return {
            'price': price,
            'change': change,
            'changePercent': changePercent,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<double?> fetchCryptoPrice(String symbol) async {
    try {
      final uri = Uri.parse('$coinbaseBaseUrl/prices/$symbol-USD/spot');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['amount'] != null) {
          return double.tryParse(data['data']['amount']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchCryptoQuote(String symbol) async {
    try {
      final spotUri = Uri.parse('$coinbaseBaseUrl/prices/$symbol-USD/spot');
      final buyUri = Uri.parse('$coinbaseBaseUrl/prices/$symbol-USD/buy');

      final responses = await Future.wait([
        http.get(spotUri),
        http.get(buyUri),
      ]);

      if (responses[0].statusCode == 200) {
        final spotData = json.decode(responses[0].body);
        final price = double.tryParse(spotData['data']?['amount'] ?? '');

        double? changePercent;
        if (responses[1].statusCode == 200) {
          final buyData = json.decode(responses[1].body);
          final buyPrice = double.tryParse(buyData['data']?['amount'] ?? '');
          if (price != null && buyPrice != null && buyPrice != 0) {
            changePercent = ((price - buyPrice) / buyPrice) * 100;
          }
        }

        return {
          'price': price,
          'change': null,
          'changePercent': changePercent ?? 0.0,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<double>?> fetchStockIntraday(String symbol) async {
    try {
      final uri = Uri.parse(
        '$alphaVantageBaseUrl?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=60min&apikey=$alphaVantageApiKey',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timeSeries = data['Time Series (60min)'] as Map<String, dynamic>?;
        if (timeSeries != null) {
          final prices = timeSeries.entries
              .take(24)
              .map((e) => double.tryParse(e.value['4. close'] ?? '') ?? 0.0)
              .toList()
              .reversed
              .toList();
          return prices;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sample stock list
  static List<Map<String, String>> get popularStocks => [
        {'symbol': 'AAPL', 'name': 'Apple Inc.'},
        {'symbol': 'GOOGL', 'name': 'Alphabet Inc.'},
        {'symbol': 'MSFT', 'name': 'Microsoft Corp.'},
        {'symbol': 'AMZN', 'name': 'Amazon.com Inc.'},
        {'symbol': 'TSLA', 'name': 'Tesla Inc.'},
        {'symbol': 'META', 'name': 'Meta Platforms'},
        {'symbol': 'NVDA', 'name': 'NVIDIA Corp.'},
        {'symbol': 'NFLX', 'name': 'Netflix Inc.'},
        {'symbol': 'JPM', 'name': 'JPMorgan Chase'},
        {'symbol': 'V', 'name': 'Visa Inc.'},
      ];

  // Sample crypto list
  static List<Map<String, String>> get popularCryptos => [
        {'symbol': 'BTC', 'name': 'Bitcoin'},
        {'symbol': 'ETH', 'name': 'Ethereum'},
        {'symbol': 'SOL', 'name': 'Solana'},
        {'symbol': 'DOGE', 'name': 'Dogecoin'},
        {'symbol': 'ADA', 'name': 'Cardano'},
        {'symbol': 'XRP', 'name': 'Ripple'},
        {'symbol': 'DOT', 'name': 'Polkadot'},
        {'symbol': 'AVAX', 'name': 'Avalanche'},
        {'symbol': 'MATIC', 'name': 'Polygon'},
        {'symbol': 'LINK', 'name': 'Chainlink'},
      ];
}
