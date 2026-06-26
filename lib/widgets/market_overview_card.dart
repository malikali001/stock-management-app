import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/psx_api_service.dart';
import '../utils/formatters.dart';

class MarketOverviewCard extends StatelessWidget {
  final MarketStats stats;

  const MarketOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface2, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PSX Market Today', style: AppTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'Gainers',
                value: '${stats.gainers}',
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Losers',
                value: '${stats.losers}',
                color: AppColors.red,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Unchanged',
                value: '${stats.unchanged}',
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoItem(label: 'Symbols', value: '${stats.symbolCount}'),
              _InfoItem(label: 'Volume', value: Formatters.volume(stats.totalVolume)),
              _InfoItem(
                  label: 'Value', value: Formatters.currencyShort(stats.totalValue)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTheme.monoMedium.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.monoSmall),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }
}
