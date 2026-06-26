import 'package:psx_portfolio_tracker/models/portfolio_stock.dart';
import 'package:psx_portfolio_tracker/models/stock_price.dart';
import 'package:psx_portfolio_tracker/models/signal.dart';

class ComputedStock {
  final String id;
  final String symbol;
  final String name;
  final String sector;
  final double avgCost;
  final int qty;
  final double currentPrice;
  final double dayChange;
  final double dayChangePct;
  final double w52High;
  final double w52Low;
  final bool hasPrice;
  final double invested;
  final double currentValue;
  final double profit;
  final double profitPct;
  final double portfolioWeight;
  final Signal? signal;

  const ComputedStock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.avgCost,
    required this.qty,
    required this.currentPrice,
    required this.dayChange,
    required this.dayChangePct,
    required this.w52High,
    required this.w52Low,
    required this.hasPrice,
    required this.invested,
    required this.currentValue,
    required this.profit,
    required this.profitPct,
    required this.portfolioWeight,
    this.signal,
  });

  factory ComputedStock.compute({
    required PortfolioStock stock,
    required StockPrice price,
    required double totalPortfolioValue,
    Signal? signal,
  }) {
    final invested = stock.avgCost * stock.qty;
    final hasPrice = price.currentPrice > 0;
    final currentValue = hasPrice ? price.currentPrice * stock.qty : invested;
    final profit = currentValue - invested;
    final profitPct = invested > 0 ? (profit / invested) * 100 : 0.0;
    final portfolioWeight =
        totalPortfolioValue > 0 ? (currentValue / totalPortfolioValue) * 100 : 0.0;

    return ComputedStock(
      id: stock.id,
      symbol: stock.symbol,
      name: stock.name,
      sector: stock.sector,
      avgCost: stock.avgCost,
      qty: stock.qty,
      currentPrice: price.currentPrice,
      dayChange: price.dayChange,
      dayChangePct: price.dayChangePct,
      w52High: price.w52High,
      w52Low: price.w52Low,
      hasPrice: hasPrice,
      invested: invested,
      currentValue: currentValue,
      profit: profit,
      profitPct: profitPct,
      portfolioWeight: portfolioWeight,
      signal: signal,
    );
  }
}
