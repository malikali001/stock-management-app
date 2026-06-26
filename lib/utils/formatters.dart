import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _numberFormat = NumberFormat('#,##0.00');
  static final _intFormat = NumberFormat('#,##0');

  static String currency(double value) {
    if (value.abs() >= 1e9) {
      return '\u20A8${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value.abs() >= 1e6) {
      return '\u20A8${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1e3) {
      return '\u20A8${(value / 1e3).toStringAsFixed(1)}K';
    }
    return '\u20A8${_numberFormat.format(value)}';
  }

  static String currencyFull(double value) {
    return '\u20A8${_numberFormat.format(value)}';
  }

  static String currencyShort(double value) {
    if (value.abs() >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    return _numberFormat.format(value);
  }

  static String percent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String percentUnsigned(double value) {
    return '${value.toStringAsFixed(2)}%';
  }

  static String number(double value) {
    return _numberFormat.format(value);
  }

  static String integer(int value) {
    return _intFormat.format(value);
  }

  static String volume(int value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  static String changeArrow(double value) {
    return value >= 0 ? '\u25B2 +${value.toStringAsFixed(2)}%' : '\u25BC ${value.toStringAsFixed(2)}%';
  }

  static String time(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }
}
