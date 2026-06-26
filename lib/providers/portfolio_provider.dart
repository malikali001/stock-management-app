import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_stock.dart';
import '../models/stock_price.dart';
import '../models/computed_stock.dart';
import '../models/sector.dart';
import '../models/signal.dart';
import '../services/psx_api_service.dart';
import '../services/storage_service.dart';
import '../services/signal_engine.dart';
import '../utils/sector_data.dart';

final psxApiServiceProvider = Provider<PsxApiService>((ref) => PsxApiService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  return PortfolioNotifier(ref);
});

class PortfolioState {
  final List<PortfolioStock> stocks;
  final Map<String, StockPrice> prices;
  final List<String> allSymbols;
  final MarketStats? marketStats;
  final bool isLoading;
  final String loadingMessage;
  final DateTime? lastUpdated;
  final int pricesLoaded;

  // Cached computed data — rebuilt only when state changes via _recompute()
  final List<ComputedStock> computedStocks;
  final List<SectorAllocation> sectorAllocations;
  final double totalInvested;
  final double totalCurrentValue;
  final double totalProfit;
  final double totalProfitPct;
  final double todayPnL;
  final int accumulateCount;
  final int bookProfitCount;
  final Set<String> portfolioSymbols;

  const PortfolioState({
    this.stocks = const [],
    this.prices = const {},
    this.allSymbols = const [],
    this.marketStats,
    this.isLoading = false,
    this.loadingMessage = '',
    this.lastUpdated,
    this.pricesLoaded = 0,
    this.computedStocks = const [],
    this.sectorAllocations = const [],
    this.totalInvested = 0,
    this.totalCurrentValue = 0,
    this.totalProfit = 0,
    this.totalProfitPct = 0,
    this.todayPnL = 0,
    this.accumulateCount = 0,
    this.bookProfitCount = 0,
    this.portfolioSymbols = const {},
  });

  PortfolioState copyWith({
    List<PortfolioStock>? stocks,
    Map<String, StockPrice>? prices,
    List<String>? allSymbols,
    MarketStats? marketStats,
    bool? isLoading,
    String? loadingMessage,
    DateTime? lastUpdated,
    int? pricesLoaded,
  }) {
    final newStocks = stocks ?? this.stocks;
    final newPrices = prices ?? this.prices;
    final needsRecompute = stocks != null || prices != null;

    if (!needsRecompute) {
      return PortfolioState(
        stocks: newStocks,
        prices: newPrices,
        allSymbols: allSymbols ?? this.allSymbols,
        marketStats: marketStats ?? this.marketStats,
        isLoading: isLoading ?? this.isLoading,
        loadingMessage: loadingMessage ?? this.loadingMessage,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        pricesLoaded: pricesLoaded ?? this.pricesLoaded,
        computedStocks: computedStocks,
        sectorAllocations: sectorAllocations,
        totalInvested: totalInvested,
        totalCurrentValue: totalCurrentValue,
        totalProfit: totalProfit,
        totalProfitPct: totalProfitPct,
        todayPnL: todayPnL,
        accumulateCount: accumulateCount,
        bookProfitCount: bookProfitCount,
        portfolioSymbols: portfolioSymbols,
      );
    }

    return _recompute(
      stocks: newStocks,
      prices: newPrices,
      allSymbols: allSymbols ?? this.allSymbols,
      marketStats: marketStats ?? this.marketStats,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pricesLoaded: pricesLoaded ?? this.pricesLoaded,
    );
  }

  static PortfolioState _recompute({
    required List<PortfolioStock> stocks,
    required Map<String, StockPrice> prices,
    required List<String> allSymbols,
    required MarketStats? marketStats,
    required bool isLoading,
    required String loadingMessage,
    required DateTime? lastUpdated,
    required int pricesLoaded,
  }) {
    // 1. Total invested
    final totalInvested = stocks.fold<double>(0, (sum, s) => sum + s.avgCost * s.qty);

    // 2. Total current value
    double totalCurrentValue = 0;
    for (final s in stocks) {
      final price = prices[s.symbol];
      if (price != null && price.currentPrice > 0) {
        totalCurrentValue += price.currentPrice * s.qty;
      } else {
        totalCurrentValue += s.avgCost * s.qty;
      }
    }

    // 3. Today P&L
    double todayPnL = 0;
    for (final s in stocks) {
      final price = prices[s.symbol];
      if (price != null) {
        todayPnL += price.dayChange * s.qty;
      }
    }

    // 4. Computed stocks with signals
    final computedStocks = stocks.map((s) {
      final price = prices[s.symbol] ?? StockPrice.empty;
      final invested = s.avgCost * s.qty;
      final hasPrice = price.currentPrice > 0;
      final currentValue = hasPrice ? price.currentPrice * s.qty : invested;
      final profit = currentValue - invested;
      final profitPct = invested > 0 ? (profit / invested) * 100 : 0.0;
      final weight = totalCurrentValue > 0 ? (currentValue / totalCurrentValue) * 100 : 0.0;

      Signal? signal;
      if (hasPrice) {
        signal = SignalEngine.computeSignal(
          currentPrice: price.currentPrice,
          avgCost: s.avgCost,
          profitPct: profitPct,
          w52High: price.w52High,
          w52Low: price.w52Low,
          portfolioWeight: weight,
        );
      }

      return ComputedStock.compute(
        stock: s,
        price: price,
        totalPortfolioValue: totalCurrentValue,
        signal: signal,
      );
    }).toList();

    // 5. Sector allocations
    final Map<String, List<ComputedStock>> grouped = {};
    for (final cs in computedStocks) {
      grouped.putIfAbsent(cs.sector, () => []).add(cs);
    }
    final sectorAllocations = grouped.entries.map((e) {
      final info = SectorData.get(e.key);
      final sectorInvested = e.value.fold<double>(0, (s, c) => s + c.invested);
      final sectorValue = e.value.fold<double>(0, (s, c) => s + c.currentValue);
      final sectorProfit = sectorValue - sectorInvested;
      final sectorProfitPct = sectorInvested > 0 ? (sectorProfit / sectorInvested) * 100 : 0.0;
      final investPct = totalCurrentValue > 0 ? (sectorValue / totalCurrentValue) * 100 : 0.0;
      return SectorAllocation(
        key: e.key, name: info.name, icon: info.icon, color: info.color,
        invested: sectorInvested, currentValue: sectorValue, profit: sectorProfit,
        profitPct: sectorProfitPct, investPct: investPct, stocks: e.value,
      );
    }).toList()
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    // 6. Signal counts
    final accumulateCount = computedStocks.where((c) => c.signal != null && c.signal!.isBuySignal).length;
    final bookProfitCount = computedStocks.where((c) => c.signal != null && c.signal!.isSellSignal).length;

    final totalProfit = totalCurrentValue - totalInvested;
    final totalProfitPct = totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0.0;

    return PortfolioState(
      stocks: stocks,
      prices: prices,
      allSymbols: allSymbols,
      marketStats: marketStats,
      isLoading: isLoading,
      loadingMessage: loadingMessage,
      lastUpdated: lastUpdated,
      pricesLoaded: pricesLoaded,
      computedStocks: computedStocks,
      sectorAllocations: sectorAllocations,
      totalInvested: totalInvested,
      totalCurrentValue: totalCurrentValue,
      totalProfit: totalProfit,
      totalProfitPct: totalProfitPct,
      todayPnL: todayPnL,
      accumulateCount: accumulateCount,
      bookProfitCount: bookProfitCount,
      portfolioSymbols: stocks.map((s) => s.symbol).toSet(),
    );
  }
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final Ref ref;
  bool _isRefreshing = false;

  PortfolioNotifier(this.ref) : super(const PortfolioState());

  Future<void> init() async {
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.init();
      final stocks = storage.loadPortfolio();
      state = state.copyWith(stocks: stocks);
      await refreshAll();
    } catch (e) {
      debugPrint('Portfolio init error: $e');
      // App still launches with default/empty state
    }
  }

  Future<void> refreshAll() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      state = state.copyWith(isLoading: true, loadingMessage: 'Fetching market data...');

      final api = ref.read(psxApiServiceProvider);

      // Fetch symbols and market stats in parallel
      final results = await Future.wait([
        api.fetchSymbols(),
        api.fetchMarketStats(),
      ]);

      final symbols = results[0] as List<String>;
      final stats = results[1] as MarketStats?;

      // Only overwrite symbols if we got data (don't wipe cache on network failure)
      state = state.copyWith(
        allSymbols: symbols.isNotEmpty ? symbols : null,
        marketStats: stats,
      );

      // Fetch prices for each portfolio stock
      final newPrices = Map<String, StockPrice>.from(state.prices);
      int loaded = 0;

      for (final stock in state.stocks) {
        state = state.copyWith(
          loadingMessage: 'Fetching ${stock.symbol}...',
        );

        final tickData = await api.fetchTickData(stock.symbol);
        if (tickData != null) {
          newPrices[stock.symbol] = tickData;
          loaded++;
        }
      }

      // Update prices once after all ticks fetched (not per-stock)
      state = state.copyWith(prices: Map.from(newPrices), pricesLoaded: loaded);

      // Fetch 52-week data
      for (final stock in state.stocks) {
        state = state.copyWith(
          loadingMessage: 'Loading 52-week data for ${stock.symbol}...',
        );

        final w52 = await api.fetch52WeekData(stock.symbol);
        final existing = newPrices[stock.symbol];
        if (existing != null && (w52.high > 0 || w52.low > 0)) {
          newPrices[stock.symbol] = existing.copyWith(
            w52High: w52.high,
            w52Low: w52.low,
          );
        }
      }

      // Final update with all 52-week data at once
      state = state.copyWith(
        isLoading: false,
        loadingMessage: '',
        lastUpdated: DateTime.now(),
        prices: Map.from(newPrices),
        pricesLoaded: loaded,
      );
    } catch (e) {
      debugPrint('Portfolio refreshAll error: $e');
      state = state.copyWith(isLoading: false, loadingMessage: '');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> addStock(PortfolioStock stock) async {
    final updated = [...state.stocks, stock];
    state = state.copyWith(stocks: updated);
    await ref.read(storageServiceProvider).savePortfolio(updated);

    // Fetch price for new stock
    try {
      final api = ref.read(psxApiServiceProvider);
      final tickData = await api.fetchTickData(stock.symbol);
      if (tickData != null) {
        final newPrices = Map<String, StockPrice>.from(state.prices);
        newPrices[stock.symbol] = tickData;

        final w52 = await api.fetch52WeekData(stock.symbol);
        if (w52.high > 0 || w52.low > 0) {
          newPrices[stock.symbol] = newPrices[stock.symbol]!.copyWith(
            w52High: w52.high,
            w52Low: w52.low,
          );
        }

        state = state.copyWith(
          prices: newPrices,
          pricesLoaded: state.pricesLoaded + 1,
        );
      }
    } catch (e) {
      debugPrint('addStock price fetch error: $e');
    }
  }

  Future<void> updateStock(PortfolioStock stock) async {
    final updated =
        state.stocks.map((s) => s.id == stock.id ? stock : s).toList();
    state = state.copyWith(stocks: updated);
    await ref.read(storageServiceProvider).savePortfolio(updated);
  }

  Future<void> removeStock(String id) async {
    final updated = state.stocks.where((s) => s.id != id).toList();
    state = state.copyWith(stocks: updated);
    await ref.read(storageServiceProvider).savePortfolio(updated);
  }
}
