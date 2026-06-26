import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/computed_stock.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/sector_data.dart';
import 'range_bar.dart';
import 'signal_badge.dart';
import 'stock_form_sheet.dart';

class StockDetailSheet extends ConsumerStatefulWidget {
  final ComputedStock stock;

  const StockDetailSheet({super.key, required this.stock});

  @override
  ConsumerState<StockDetailSheet> createState() => _StockDetailSheetState();
}

class _StockDetailSheetState extends ConsumerState<StockDetailSheet> {
  bool _confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final sectorInfo = SectorData.get(stock.sector);
    final isProfit = stock.profit >= 0;
    final profitColor = isProfit ? AppColors.green : AppColors.red;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: sectorInfo.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        stock.symbol.length >= 3
                            ? stock.symbol.substring(0, 3)
                            : stock.symbol,
                        style: AppTheme.bodyLarge.copyWith(
                          color: sectorInfo.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.symbol, style: AppTheme.displayMedium),
                        Text(stock.name, style: AppTheme.bodyMedium),
                        Text('${sectorInfo.icon} ${sectorInfo.name}',
                            style: AppTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Signal Banner
              if (stock.signal != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: stock.signal!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: stock.signal!.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SignalBadge(signal: stock.signal!, large: true),
                          const SizedBox(width: 10),
                          Text(
                            'Long-term Signal',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...stock.signal!.reasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('\u2022 ',
                                  style: AppTheme.bodyMedium
                                      .copyWith(color: stock.signal!.color)),
                              Expanded(
                                  child:
                                      Text(r, style: AppTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // 52-Week Range Bar
              if (stock.w52High > stock.w52Low && stock.w52High > 0) ...[
                RangeBar(
                  low: stock.w52Low,
                  high: stock.w52High,
                  current: stock.currentPrice,
                  avgCost: stock.avgCost,
                ),
                const SizedBox(height: 16),
              ],
              // Current Price
              Row(
                children: [
                  Text(
                    stock.hasPrice
                        ? Formatters.currencyFull(stock.currentPrice)
                        : '\u2014',
                    style: AppTheme.monoLarge,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (stock.dayChange >= 0
                              ? AppColors.green
                              : AppColors.red)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${stock.dayChange >= 0 ? "+" : ""}${stock.dayChange.toStringAsFixed(2)} (${stock.dayChangePct.toStringAsFixed(2)}%)',
                      style: AppTheme.monoSmall.copyWith(
                        color: stock.dayChange >= 0
                            ? AppColors.green
                            : AppColors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats Grid
              _StatsGrid(stock: stock, profitColor: profitColor),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface1,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      onPressed: () {
                        final parentContext = Navigator.of(context).context;
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (parentContext.mounted) {
                            showModalBottomSheet(
                              context: parentContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) =>
                                  StockFormSheet(editStock: stock),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _confirmDelete
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.warning_amber, size: 18),
                            label: const Text('Confirm Remove'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.red.withValues(alpha: 0.2),
                              foregroundColor: AppColors.red,
                            ),
                            onPressed: () {
                              ref
                                  .read(portfolioProvider.notifier)
                                  .removeStock(stock.id);
                              Navigator.pop(context);
                            },
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface1,
                              foregroundColor: AppColors.red,
                            ),
                            onPressed: () =>
                                setState(() => _confirmDelete = true),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ComputedStock stock;
  final Color profitColor;

  const _StatsGrid({required this.stock, required this.profitColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatCell(label: 'Invested', value: Formatters.currency(stock.invested)),
              _StatCell(
                  label: 'Current',
                  value: Formatters.currency(stock.currentValue)),
              _StatCell(
                label: 'P&L',
                value: Formatters.currency(stock.profit),
                color: profitColor,
              ),
              _StatCell(
                label: 'Return',
                value: Formatters.percent(stock.profitPct),
                color: profitColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCell(label: 'Shares', value: '${stock.qty}'),
              _StatCell(
                  label: 'Avg Cost',
                  value: Formatters.currencyFull(stock.avgCost)),
              _StatCell(
                  label: 'Portfolio%',
                  value: Formatters.percentUnsigned(stock.portfolioWeight)),
              _StatCell(
                  label: '52W Range',
                  value: stock.w52High > 0
                      ? '${stock.w52Low.toStringAsFixed(0)}-${stock.w52High.toStringAsFixed(0)}'
                      : '\u2014'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCell({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.monoTiny.copyWith(
              color: color ?? AppColors.textPrimary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTheme.bodySmall.copyWith(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
