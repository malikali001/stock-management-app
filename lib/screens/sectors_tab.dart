import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/sector_card.dart';

class SectorsTab extends ConsumerWidget {
  const SectorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioProvider);
    final sectors = state.sectorAllocations;

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refreshAll(),
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Sector Breakdown', style: AppTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${sectors.length} sectors across ${state.stocks.length} holdings',
              style: AppTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          if (sectors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Add stocks to see sector breakdown.',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ),
          ...sectors.map((s) => SectorCard(sector: s)),
        ],
      ),
    );
  }
}
