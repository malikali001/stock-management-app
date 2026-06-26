import 'package:flutter/material.dart';
import '../models/signal.dart';
import '../theme/app_theme.dart';

class SignalBadge extends StatelessWidget {
  final Signal signal;
  final bool large;

  const SignalBadge({super.key, required this.signal, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(large ? 6 : 4),
      ),
      child: Text(
        signal.badge,
        style: (large ? AppTheme.labelMedium : AppTheme.bodySmall).copyWith(
          color: signal.color,
          fontWeight: FontWeight.w600,
          fontSize: large ? 13 : 10,
        ),
      ),
    );
  }
}

class MarketSignalBadge extends StatelessWidget {
  final MarketSignal signal;

  const MarketSignalBadge({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        signal.label,
        style: AppTheme.bodySmall.copyWith(
          color: signal.color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
