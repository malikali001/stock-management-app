import 'package:flutter/material.dart';
import 'computed_stock.dart';

class SectorAllocation {
  final String key;
  final String name;
  final String icon;
  final Color color;
  final double invested;
  final double currentValue;
  final double profit;
  final double profitPct;
  final double investPct;
  final List<ComputedStock> stocks;

  const SectorAllocation({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.invested,
    required this.currentValue,
    required this.profit,
    required this.profitPct,
    required this.investPct,
    required this.stocks,
  });
}
