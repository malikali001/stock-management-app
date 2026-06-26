import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/portfolio_stock.dart';

class StorageService {
  static const _boxName = 'portfolio';
  static const _key = 'stocks';
  static const _uuid = Uuid();
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  List<PortfolioStock> loadPortfolio() {
    final raw = _box.get(_key);
    if (raw == null) return _defaultStocks();

    try {
      final List<dynamic> list = json.decode(raw as String);
      final stocks = list
          .map((e) => PortfolioStock.fromJson(e as Map<String, dynamic>))
          .toList();
      if (stocks.isEmpty) return _defaultStocks();
      return stocks;
    } catch (e) {
      return _defaultStocks();
    }
  }

  Future<void> savePortfolio(List<PortfolioStock> stocks) async {
    final jsonStr = json.encode(stocks.map((s) => s.toJson()).toList());
    await _box.put(_key, jsonStr);
  }

  static String generateId() => _uuid.v4();

  List<PortfolioStock> _defaultStocks() {
    return [
      PortfolioStock(id: generateId(), symbol: 'HBL', name: 'Habib Bank Ltd', sector: 'banking', avgCost: 125.50, qty: 500),
      PortfolioStock(id: generateId(), symbol: 'MCB', name: 'MCB Bank Ltd', sector: 'banking', avgCost: 198.00, qty: 300),
      PortfolioStock(id: generateId(), symbol: 'UBL', name: 'United Bank Ltd', sector: 'banking', avgCost: 145.00, qty: 200),
      PortfolioStock(id: generateId(), symbol: 'OGDC', name: 'Oil & Gas Dev Co', sector: 'energy', avgCost: 89.50, qty: 1000),
      PortfolioStock(id: generateId(), symbol: 'PPL', name: 'Pakistan Petroleum', sector: 'energy', avgCost: 72.00, qty: 800),
      PortfolioStock(id: generateId(), symbol: 'PSO', name: 'Pakistan State Oil', sector: 'energy', avgCost: 210.00, qty: 150),
      PortfolioStock(id: generateId(), symbol: 'LUCK', name: 'Lucky Cement', sector: 'cement', avgCost: 620.00, qty: 100),
      PortfolioStock(id: generateId(), symbol: 'DGKC', name: 'DG Khan Cement', sector: 'cement', avgCost: 78.00, qty: 600),
      PortfolioStock(id: generateId(), symbol: 'EFERT', name: 'Engro Fertilizer', sector: 'fertilizer', avgCost: 85.00, qty: 700),
      PortfolioStock(id: generateId(), symbol: 'FFC', name: 'Fauji Fertilizer', sector: 'fertilizer', avgCost: 110.00, qty: 400),
      PortfolioStock(id: generateId(), symbol: 'SYS', name: 'Systems Ltd', sector: 'tech', avgCost: 380.00, qty: 200),
      PortfolioStock(id: generateId(), symbol: 'TRG', name: 'TRG Pakistan', sector: 'tech', avgCost: 95.00, qty: 500),
      PortfolioStock(id: generateId(), symbol: 'SEARL', name: 'Searle Company', sector: 'pharma', avgCost: 58.00, qty: 600),
      PortfolioStock(id: generateId(), symbol: 'INDU', name: 'Indus Motor Co', sector: 'auto', avgCost: 1280.00, qty: 50),
    ];
  }
}
