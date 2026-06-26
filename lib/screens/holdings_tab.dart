import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/computed_stock.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_card.dart';
import '../widgets/stock_detail_sheet.dart';
import '../widgets/stock_form_sheet.dart';

enum SortMode { profitPct, value, dayChange }

class HoldingsTab extends ConsumerStatefulWidget {
  const HoldingsTab({super.key});

  @override
  ConsumerState<HoldingsTab> createState() => _HoldingsTabState();
}

class _HoldingsTabState extends ConsumerState<HoldingsTab> {
  SortMode _sortMode = SortMode.profitPct;
  String? _sectorFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portfolioProvider);
    var computed = state.computedStocks;

    // Filter
    if (_sectorFilter != null) {
      computed = computed.where((s) => s.sector == _sectorFilter).toList();
    }

    // Sort
    switch (_sortMode) {
      case SortMode.profitPct:
        computed.sort((a, b) => b.profitPct.compareTo(a.profitPct));
        break;
      case SortMode.value:
        computed.sort((a, b) => b.currentValue.compareTo(a.currentValue));
        break;
      case SortMode.dayChange:
        computed.sort((a, b) => b.dayChangePct.compareTo(a.dayChangePct));
        break;
    }

    final sectors = state.sectorAllocations;

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refreshAll(),
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('All Holdings (${state.stocks.length})',
                    style: AppTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.accent),
                  onPressed: () => _showAddForm(context),
                ),
              ],
            ),
          ),
          // Sort buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SortChip(
                  label: 'P&L%',
                  selected: _sortMode == SortMode.profitPct,
                  onTap: () => setState(() => _sortMode = SortMode.profitPct),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Value',
                  selected: _sortMode == SortMode.value,
                  onTap: () => setState(() => _sortMode = SortMode.value),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Day Change',
                  selected: _sortMode == SortMode.dayChange,
                  onTap: () => setState(() => _sortMode = SortMode.dayChange),
                ),
              ],
            ),
          ),
          // Sector filter chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _sectorFilter == null,
                  onTap: () => setState(() => _sectorFilter = null),
                ),
                ...sectors.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: '${s.icon} ${s.name}',
                      selected: _sectorFilter == s.key,
                      onTap: () =>
                          setState(() => _sectorFilter = s.key),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Stock list
          Expanded(
            child: computed.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _sectorFilter != null
                            ? 'No stocks in this sector.'
                            : 'Add your first stock to get started.',
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: computed.length,
                    itemBuilder: (context, index) {
                      final stock = computed[index];
                      return StockCard(
                        stock: stock,
                        showSignal: true,
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

  void _showAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StockFormSheet(),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.surface1,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.surface1,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
