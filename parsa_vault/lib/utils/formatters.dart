import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _compactCurrencyFormatter = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String currency(double value) {
    return _currencyFormatter.format(value);
  }

  static String compactCurrency(double value) {
    return _compactCurrencyFormatter.format(value);
  }

  static String price(double value) {
    if (value >= 1000) {
      return NumberFormat('\$#,##0.00').format(value);
    } else if (value >= 1) {
      return NumberFormat('\$#,##0.00').format(value);
    } else {
      return NumberFormat('\$0.0000').format(value);
    }
  }

  static String percentage(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String shares(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(value < 1 ? 6 : 4);
  }

  static String xp(int value) => '$value XP';

  static String date(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('EEEE, d MMMM').format(dt);
  }

  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('d MMM · h:mm a').format(dt);

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
