import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/donut_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/stock_card.dart';
import '../widgets/stock_detail_sheet.dart';
import 'home_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioProvider);
    final computed = state.computedStocks;
    final sectors = state.sectorAllocations;
    final isProfit = state.totalProfit >= 0;
    final profitColor = isProfit ? AppColors.green : AppColors.red;

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refreshAll(),
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1F3A), Color(0xFF0F1628)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portfolio Value', style: AppTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(state.totalCurrentValue),
                  style: AppTheme.monoLarge.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    Formatters.changeArrow(state.totalProfitPct),
                    style: AppTheme.monoSmall.copyWith(color: profitColor),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _SummaryItem(
                      label: 'Total Invested',
                      value: Formatters.currency(state.totalInvested),
                    ),
                    _SummaryItem(
                      label: 'Total P&L',
                      value: Formatters.currency(state.totalProfit),
                      color: profitColor,
                    ),
                    _SummaryItem(
                      label: "Today's P&L",
                      value: Formatters.currency(state.todayPnL),
                      color: state.todayPnL >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // API status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isLoading ? AppColors.amber : AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.isLoading
                            ? state.loadingMessage
                            : '${state.pricesLoaded} prices loaded \u00B7 ${state.lastUpdated != null ? Formatters.time(state.lastUpdated!) : ""}',
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Insights
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                InsightCard(
                  icon: '\u{1F7E2}',
                  value: '${state.accumulateCount}',
                  label: 'Accumulate',
                  color: AppColors.green,
                ),
                const SizedBox(width: 10),
                InsightCard(
                  icon: '\u{1F7E1}',
                  value: '${state.bookProfitCount}',
                  label: 'Book Profit',
                  color: AppColors.amber,
                ),
                const SizedBox(width: 10),
                InsightCard(
                  icon: '\u{1F4CA}',
                  value: '${state.stocks.length}',
                  label: 'Holdings',
                ),
                const SizedBox(width: 10),
                InsightCard(
                  icon: '\u{1F3F7}\uFE0F',
                  value: '${sectors.length}',
                  label: 'Sectors',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sector Allocation
          if (sectors.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Sector Allocation', style: AppTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 16),
                DonutChart(sectors: sectors, size: 150),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: sectors
                        .take(7)
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(s.name,
                                        style: AppTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text(
                                    Formatters.percentUnsigned(s.investPct),
                                    style: AppTheme.monoTiny,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Top Holdings
          if (computed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Top Holdings', style: AppTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ...(computed.toList()
                ..sort((a, b) => b.currentValue.compareTo(a.currentValue)))
              .take(4)
              .map(
                (stock) => StockCard(
                  stock: stock,
                  showSignal: true,
                  onTap: () => _showDetail(context, stock),
                ),
              ),
          if (computed.length > 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton(
                onPressed: () {
                  final scaffold =
                      context.findAncestorStateOfType<HomeScreenState>();
                  scaffold?.switchTab(1);
                },
                child: Text(
                  'View all ${computed.length} holdings \u2192',
                  style: AppTheme.bodyMedium.copyWith(color: AppColors.accent),
                ),
              ),
            ),
          ], // end if computed.isNotEmpty
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, dynamic stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StockDetailSheet(stock: stock),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.monoTiny.copyWith(
              color: color ?? AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}