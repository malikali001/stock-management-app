import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class RangeBar extends StatelessWidget {
  final double low;
  final double high;
  final double current;
  final double? avgCost;

  const RangeBar({
    super.key,
    required this.low,
    required this.high,
    required this.current,
    this.avgCost,
  });

  @override
  Widget build(BuildContext context) {
    if (high <= low || high <= 0) {
      return const SizedBox.shrink();
    }

    final range = high - low;
    final currentPos = ((current - low) / range).clamp(0.0, 1.0);
    final costPos =
        avgCost != null ? ((avgCost! - low) / range).clamp(0.0, 1.0) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('52-Week Range', style: AppTheme.bodySmall),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background bar
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Filled portion
                  Positioned(
                    top: 10,
                    left: 0,
                    child: Container(
                      height: 6,
                      width: width * currentPos,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.green.withValues(alpha: 0.6),
                            currentPos > 0.75
                                ? AppColors.amber
                                : AppColors.green,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Cost marker (triangle)
                  if (costPos != null)
                    Positioned(
                      top: 18,
                      left: width * costPos - 5,
                      child: Text(
                        '\u25B2',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.amber.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  // Current price dot
                  Positioned(
                    top: 7,
                    left: width * currentPos - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Formatters.currency(low), style: AppTheme.monoTiny),
            Text(Formatters.currency(high), style: AppTheme.monoTiny),
          ],
        ),
      ],
    );
  }
}
