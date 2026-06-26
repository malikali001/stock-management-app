import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/computed_stock.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_card.dart';
import '../widgets/stock_detail_sheet.dart';

enum SignalFilter { all, accumulate, bookProfit, hold }

class SignalsTab extends ConsumerStatefulWidget {
  const SignalsTab({super.key});

  @override
  ConsumerState<SignalsTab> createState() => _SignalsTabState();
}

class _SignalsTabState extends ConsumerState<SignalsTab> {
  SignalFilter _filter = SignalFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portfolioProvider);
    final computed = state.computedStocks;

    final withSignals = computed.where((c) => c.signal != null).toList();
    final accumulate = withSignals.where((c) => c.signal!.isBuySignal).toList();
    final bookProfit =
        withSignals.where((c) => c.signal!.isSellSignal).toList();
    final hold = withSignals.where((c) => c.signal!.isHold).toList();

    List<ComputedStock> filtered;
    switch (_filter) {
      case SignalFilter.all:
        filtered = withSignals;
        break;
      case SignalFilter.accumulate:
        filtered = accumulate;
        break;
      case SignalFilter.bookProfit:
        filtered = bookProfit;
        break;
      case SignalFilter.hold:
        filtered = hold;
        break;
    }

    // Sort by signal score (most actionable first)
    filtered.sort((a, b) => (a.signal?.score ?? 0).compareTo(b.signal?.score ?? 0));

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refreshAll(),
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Long-Term Signals', style: AppTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Based on 52-week range, cost basis, and portfolio weight.',
              style: AppTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          // Signal category cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CategoryCard(
                  label: 'All',
                  count: withSignals.length,
                  color: AppColors.textSecondary,
                  selected: _filter == SignalFilter.all,
                  onTap: () => setState(() => _filter = SignalFilter.all),
                ),
                const SizedBox(width: 8),
                _CategoryCard(
                  label: '\u{1F7E2} Add',
                  count: accumulate.length,
                  color: AppColors.green,
                  selected: _filter == SignalFilter.accumulate,
                  onTap: () =>
                      setState(() => _filter = SignalFilter.accumulate),
                ),
                const SizedBox(width: 8),
                _CategoryCard(
                  label: '\u{1F7E1} Book',
                  count: bookProfit.length,
                  color: AppColors.amber,
                  selected: _filter == SignalFilter.bookProfit,
                  onTap: () =>
                      setState(() => _filter = SignalFilter.bookProfit),
                ),
                const SizedBox(width: 8),
                _CategoryCard(
                  label: '\u{1F535} Hold',
                  count: hold.length,
                  color: AppColors.blue,
                  selected: _filter == SignalFilter.hold,
                  onTap: () => setState(() => _filter = SignalFilter.hold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filtered stock list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No signals available yet.\nAdd stocks and wait for price data.',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final stock = filtered[index];
                      return StockCard(
                        stock: stock,
                        showSignal: true,
                        showReasons: true,
                        onTap: () => _showDetail(context, stock),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, ComputedStock stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StockDetailSheet(stock: stock),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: AppTheme.monoMedium.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
