import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../services/psx_api_service.dart';
import '../models/signal.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/market_overview_card.dart';
import '../widgets/signal_badge.dart';

class MarketTab extends ConsumerStatefulWidget {
  const MarketTab({super.key});

  @override
  ConsumerState<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends ConsumerState<MarketTab> {
  bool _showGainers = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portfolioProvider);
    final stats = state.marketStats;
    final portfolioSymbols = state.portfolioSymbols;

    List<MarketMover> movers;
    if (stats != null) {
      movers = _showGainers ? stats.topGainers : stats.topLosers;
    } else {
      movers = [];
    }

    // Filter out portfolio stocks
    final nonPortfolio =
        movers.where((m) => !portfolioSymbols.contains(m.symbol)).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refreshAll(),
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Market Overview', style: AppTheme.titleLarge),
          ),
          if (stats != null) MarketOverviewCard(stats: stats),
          if (stats == null && !state.isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Market data unavailable. Pull to refresh.',
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showGainers = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _showGainers
                            ? AppColors.green.withValues(alpha: 0.15)
                            : AppColors.surface1,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Text(
                          '\u{1F7E2} Top Gainers',
                          style: AppTheme.bodyMedium.copyWith(
                            color: _showGainers
                                ? AppColors.green
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showGainers = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showGainers
                            ? AppColors.red.withValues(alpha: 0.15)
                            : AppColors.surface1,
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Text(
                          '\u{1F534} Top Losers',
                          style: AppTheme.bodyMedium.copyWith(
                            color: !_showGainers
                                ? AppColors.red
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (nonPortfolio.isEmpty && stats != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'All top movers are in your portfolio!',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ),
          ...nonPortfolio.map((mover) => _OpportunityCard(mover: mover)),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final MarketMover mover;

  const _OpportunityCard({required this.mover});

  @override
  Widget build(BuildContext context) {
    final isGain = mover.change >= 0;
    final color = isGain ? AppColors.green : AppColors.red;
    final signal = MarketSignal.fromChange(mover.changePercent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface2, width: 0.5),
      ),
      child: Row(
        children: [
          // Symbol
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                mover.symbol.length >= 3
                    ? mover.symbol.substring(0, 3)
                    : mover.symbol,
                style: AppTheme.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(mover.symbol, style: AppTheme.titleMedium),
                    if (signal != null) ...[
                      const SizedBox(width: 8),
                      MarketSignalBadge(signal: signal),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Vol: ${Formatters.volume(mover.volume)}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currencyFull(mover.price),
                style: AppTheme.monoSmall,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isGain ? "+" : ""}${mover.changePercent.toStringAsFixed(2)}%',
                  style: AppTheme.monoTiny.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
