import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../models/stock_price.dart';

class MarketStats {
  final int totalVolume;
  final double totalValue;
  final int totalTrades;
  final int symbolCount;
  final int gainers;
  final int losers;
  final int unchanged;
  final List<MarketMover> topGainers;
  final List<MarketMover> topLosers;

  const MarketStats({
    required this.totalVolume,
    required this.totalValue,
    required this.totalTrades,
    required this.symbolCount,
    required this.gainers,
    required this.losers,
    required this.unchanged,
    required this.topGainers,
    required this.topLosers,
  });
}

class MarketMover {
  final String symbol;
  final double change;
  final double changePercent;
  final double price;
  final int volume;
  final double value;

  const MarketMover({
    required this.symbol,
    required this.change,
    required this.changePercent,
    required this.price,
    required this.volume,
    required this.value,
  });
}

/// Parses a numeric cell that may contain commas, a `%` suffix, or be empty.
double _num(String s) {
  if (s.isEmpty) return 0.0;
  return double.tryParse(s.replaceAll(',', '').replaceAll('%', '').trim()) ?? 0.0;
}

/// Parses an integer cell that may contain commas.
int _int(String s) {
  if (s.isEmpty) return 0;
  final clean = s.replaceAll(',', '').trim();
  return int.tryParse(clean) ?? (double.tryParse(clean)?.toInt() ?? 0);
}

double _numDyn(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return _num(value);
  return 0.0;
}

/// PSX market data, backed by the official PSX Data Portal (dps.psx.com.pk).
///
/// This is PSX's own public portal — free, no API key, no auth. It supersedes
/// the previous psxterminal.com integration (whose price/kline endpoints began
/// returning HTTP 403 "Access denied").
///
/// Endpoints used:
///   GET /symbols                  -> JSON array of {symbol, name, sectorName, ...}
///   GET /market-watch             -> HTML table of EVERY symbol's live snapshot
///                                    (one request covers all live prices + stats)
///   GET /timeseries/eod/{SYMBOL}  -> JSON [[ts, close, volume, prevClose], ...]
///                                    ~5 years of daily history in a single call
class PsxApiService {
  static const _baseUrl = 'https://dps.psx.com.pk';
  static const _timeout = Duration(seconds: 20);
  final http.Client _client;

  // In-memory snapshot of the latest /market-watch parse, keyed by symbol.
  // Populated by fetchMarketStats() and reused by fetchTickData() so the
  // per-stock refresh loop costs zero extra network requests.
  Map<String, StockPrice> _liveSnapshot = {};
  MarketStats? _lastStats;

  PsxApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<String>> fetchSymbols() async {
    try {
      final response =
          await _client.get(Uri.parse('$_baseUrl/symbols')).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      if (decoded is! List) return [];

      return decoded
          .where((e) {
            // Drop debt instruments (TFCs/bonds) — this is an equity tracker.
            if (e is Map && e['isDebt'] == true) return false;
            return true;
          })
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['symbol'] ?? e['name'] ?? '').toString();
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('PSX API fetchSymbols error: $e');
      return [];
    }
  }

  Future<MarketStats?> fetchMarketStats() async {
    final ok = await _refreshMarketWatch();
    return ok ? _lastStats : null;
  }

  /// Fetches and parses /market-watch once, refreshing both the live price
  /// snapshot and the aggregated market stats. Returns true on success.
  Future<bool> _refreshMarketWatch() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/market-watch'))
          .timeout(_timeout);
      if (response.statusCode != 200) return false;

      final document = html_parser.parse(response.body);
      final rows = document.querySelectorAll('tr');

      final Map<String, StockPrice> snapshot = {};
      final List<MarketMover> movers = [];
      int gainers = 0, losers = 0, unchanged = 0;
      int totalVolume = 0;
      double totalValue = 0;

      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        // Columns: symbol, sector, listed, ldcp, open, high, low, close,
        //          change, percentChange, volume, [order book...]
        if (cells.length < 11) continue;

        String cell(int i) => cells[i].text.trim();

        final symbol = cell(0);
        if (symbol.isEmpty) continue;

        final high = _num(cell(5));
        final low = _num(cell(6));
        final close = _num(cell(7));
        final change = _num(cell(8));
        final changePct = _num(cell(9)); // already a percentage, e.g. "3.92%"
        final volume = _int(cell(10));

        if (close <= 0) continue;

        final value = close * volume; // traded value not exposed; price×vol proxy

        snapshot[symbol] = StockPrice(
          currentPrice: close,
          dayChange: change,
          dayChangePct: changePct,
          dayHigh: high,
          dayLow: low,
          volume: volume,
          w52High: 0,
          w52Low: 0,
        );

        if (change > 0) {
          gainers++;
        } else if (change < 0) {
          losers++;
        } else {
          unchanged++;
        }
        totalVolume += volume;
        totalValue += value;

        movers.add(MarketMover(
          symbol: symbol,
          change: change,
          changePercent: changePct,
          price: close,
          volume: volume,
          value: value,
        ));
      }

      if (snapshot.isEmpty) return false;

      movers.sort((a, b) => b.changePercent.compareTo(a.changePercent));
      final topGainers = movers.take(10).toList();
      final topLosers =
          movers.reversed.take(10).where((m) => m.changePercent < 0).toList();

      _liveSnapshot = snapshot;
      _lastStats = MarketStats(
        totalVolume: totalVolume,
        totalValue: totalValue,
        totalTrades: 0, // not exposed by the portal
        symbolCount: snapshot.length,
        gainers: gainers,
        losers: losers,
        unchanged: unchanged,
        topGainers: topGainers,
        topLosers: topLosers,
      );
      return true;
    } catch (e) {
      debugPrint('PSX API _refreshMarketWatch error: $e');
      return false;
    }
  }

  /// Live price for a single symbol, served from the cached /market-watch
  /// snapshot. Triggers a snapshot refresh only if one hasn't been loaded yet.
  Future<StockPrice?> fetchTickData(String symbol) async {
    if (_liveSnapshot.isEmpty) {
      await _refreshMarketWatch();
    }
    return _liveSnapshot[symbol];
  }

  /// 52-week high/low derived from ~1 year of daily closing prices.
  ///
  /// The EOD series has no per-day high/low, so we use closing prices — the
  /// standard basis for a long-term 52-week range. One request returns the full
  /// multi-year history; we window it to the most recent ~52 weeks.
  Future<({double high, double low})> fetch52WeekData(String symbol) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/timeseries/eod/$symbol'))
          .timeout(_timeout);
      if (response.statusCode != 200) return (high: 0.0, low: 0.0);

      final decoded = json.decode(response.body);
      final data = (decoded is Map && decoded['data'] is List)
          ? decoded['data'] as List
          : (decoded is List ? decoded : null);
      if (data == null || data.isEmpty) return (high: 0.0, low: 0.0);

      // Rows are newest-first: [timestamp, close, volume, prevClose].
      const oneYearSeconds = 365 * 24 * 60 * 60;
      final first = data.first;
      final newestTs =
          (first is List && first.isNotEmpty) ? _numDyn(first[0]).toInt() : 0;
      final cutoff = newestTs - oneYearSeconds;

      double maxHigh = 0;
      double minLow = double.infinity;

      for (final row in data) {
        if (row is! List || row.length < 2) continue;
        final ts = _numDyn(row[0]).toInt();
        if (newestTs > 0 && ts < cutoff) continue; // older than ~52 weeks
        final close = _numDyn(row[1]);
        if (close <= 0) continue;
        if (close > maxHigh) maxHigh = close;
        if (close < minLow) minLow = close;
      }

      if (minLow == double.infinity) minLow = 0;
      return (high: maxHigh, low: minLow);
    } catch (e) {
      debugPrint('PSX API fetch52WeekData($symbol) error: $e');
      return (high: 0.0, low: 0.0);
    }
  }
}
