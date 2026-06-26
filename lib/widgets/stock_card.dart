import 'package:flutter/material.dart';
import '../models/computed_stock.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/sector_data.dart';
import 'signal_badge.dart';
import 'sparkline.dart';

class StockCard extends StatelessWidget {
  final ComputedStock stock;
  final VoidCallback? onTap;
  final bool showSignal;
  final bool showReasons;
  final bool showRangeBar;

  const StockCard({
    super.key,
    required this.stock,
    this.onTap,
    this.showSignal = false,
    this.showReasons = false,
    this.showRangeBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final sectorInfo = SectorData.get(stock.sector);
    final isProfit = stock.profit >= 0;
    final profitColor = isProfit ? AppColors.green : AppColors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface2, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                // Symbol icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sectorInfo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      stock.symbol.length >= 3
                          ? stock.symbol.substring(0, 3)
                          : stock.symbol,
                      style: AppTheme.bodySmall.copyWith(
                        color: sectorInfo.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name and symbol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(stock.symbol, style: AppTheme.titleMedium),
                          if (showSignal && stock.signal != null) ...[
                            const SizedBox(width: 8),
                            SignalBadge(signal: stock.signal!),
                          ],
                        ],
                      ),
                      Text(
                        stock.name,
                        style: AppTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Sparkline
                if (stock.hasPrice && stock.w52High > 0)
                  MiniSparkline(
                    current: stock.currentPrice,
                    high: stock.w52High,
                    low: stock.w52Low,
                    avgCost: stock.avgCost,
                    color: profitColor,
                  ),
                const SizedBox(width: 10),
                // Price and P&L
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stock.hasPrice
                          ? Formatters.currencyFull(stock.currentPrice)
                          : '\u2014',
                      style: AppTheme.monoSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: profitColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        Formatters.percent(stock.profitPct),
                        style: AppTheme.monoTiny.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stats row
            Row(
              children: [
                _MiniStat(label: 'Invested', value: Formatters.currency(stock.invested)),
                _MiniStat(label: 'Current', value: Formatters.currency(stock.currentValue)),
                _MiniStat(
                  label: 'P&L',
                  value: Formatters.currency(stock.profit),
                  color: profitColor,
                ),
                _MiniStat(label: 'Qty', value: '${stock.qty}'),
              ],
            ),
            // Optional: signal reasons
            if (showReasons && stock.signal != null && stock.signal!.reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stock.signal!.reasons
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('\u2022 ',
                                    style: AppTheme.bodySmall
                                        .copyWith(color: stock.signal!.color)),
                                Expanded(
                                  child:
                                      Text(r, style: AppTheme.bodySmall),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.monoTiny.copyWith(
              color: color ?? AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 1),
          Text(label,
              style: AppTheme.bodySmall.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
