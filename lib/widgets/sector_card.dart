import 'package:flutter/material.dart';
import '../models/sector.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'progress_bar.dart';
import 'signal_badge.dart';

class SectorCard extends StatefulWidget {
  final SectorAllocation sector;

  const SectorCard({super.key, required this.sector});

  @override
  State<SectorCard> createState() => _SectorCardState();
}

class _SectorCardState extends State<SectorCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sector;
    final isProfit = s.profit >= 0;
    final profitColor = isProfit ? AppColors.green : AppColors.red;

    final accumCount =
        s.stocks.where((c) => c.signal != null && c.signal!.isBuySignal).length;
    final bookCount =
        s.stocks.where((c) => c.signal != null && c.signal!.isSellSignal).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface2, width: 0.5),
      ),
      child: Column(
        children: [
          // Main content
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(s.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: AppTheme.titleMedium),
                            Text('${s.stocks.length} stocks',
                                style: AppTheme.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.percent(s.profitPct),
                            style: AppTheme.monoSmall.copyWith(color: profitColor),
                          ),
                          Text(
                            Formatters.currency(s.profit),
                            style: AppTheme.monoTiny.copyWith(color: profitColor),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      _StatItem(
                          label: 'Invested', value: Formatters.currency(s.invested)),
                      _StatItem(
                          label: 'Current',
                          value: Formatters.currency(s.currentValue)),
                      _StatItem(
                          label: 'Portfolio',
                          value: Formatters.percentUnsigned(s.investPct)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Signal summary
                  if (accumCount > 0 || bookCount > 0)
                    Row(
                      children: [
                        if (accumCount > 0)
                          _SignalCount(
                            icon: '\u{1F7E2}',
                            count: accumCount,
                            label: 'accumulate',
                          ),
                        if (accumCount > 0 && bookCount > 0)
                          const SizedBox(width: 12),
                        if (bookCount > 0)
                          _SignalCount(
                            icon: '\u{1F7E1}',
                            count: bookCount,
                            label: 'book profit',
                          ),
                      ],
                    ),
                  if (accumCount > 0 || bookCount > 0)
                    const SizedBox(height: 10),
                  // Progress bar
                  PortfolioProgressBar(
                    percent: s.investPct,
                    color: s.color,
                  ),
                ],
              ),
            ),
          ),
          // Expanded stock list
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.surface2),
            ...s.stocks.map((stock) {
              final stockProfit = stock.profit >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stock.symbol, style: AppTheme.bodyLarge),
                          Text(stock.name,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (stock.signal != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SignalBadge(signal: stock.signal!),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stock.hasPrice
                              ? Formatters.currencyFull(stock.currentPrice)
                              : '\u2014',
                          style: AppTheme.monoSmall,
                        ),
                        Text(
                          Formatters.percent(stock.profitPct),
                          style: AppTheme.monoTiny.copyWith(
                            color: stockProfit ? AppColors.green : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTheme.monoTiny),
          const SizedBox(height: 1),
          Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _SignalCount extends StatelessWidget {
  final String icon;
  final int count;
  final String label;

  const _SignalCount(
      {required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$icon $count $label',
      style: AppTheme.bodySmall.copyWith(fontSize: 11),
    );
  }
}
