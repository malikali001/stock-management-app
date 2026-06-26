import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SignalType {
  strongAccumulate,
  accumulate,
  leanAdd,
  hold,
  leanReduce,
  bookPartial,
  strongReduce,
}

class Signal {
  final SignalType type;
  final String label;
  final String badge;
  final Color color;
  final double score;
  final List<String> reasons;

  const Signal({
    required this.type,
    required this.label,
    required this.badge,
    required this.color,
    required this.score,
    required this.reasons,
  });

  bool get isBuySignal =>
      type == SignalType.strongAccumulate ||
      type == SignalType.accumulate ||
      type == SignalType.leanAdd;

  bool get isSellSignal =>
      type == SignalType.leanReduce ||
      type == SignalType.bookPartial ||
      type == SignalType.strongReduce;

  bool get isHold => type == SignalType.hold;

  static Signal fromScore(double score, List<String> reasons) {
    if (score <= -4) {
      return Signal(
        type: SignalType.strongAccumulate,
        label: 'STRONG ACCUMULATE',
        badge: 'STRONG ADD',
        color: AppColors.green,
        score: score,
        reasons: reasons,
      );
    } else if (score <= -2) {
      return Signal(
        type: SignalType.accumulate,
        label: 'ACCUMULATE',
        badge: 'ADD',
        color: AppColors.green,
        score: score,
        reasons: reasons,
      );
    } else if (score <= -0.5) {
      return Signal(
        type: SignalType.leanAdd,
        label: 'LEAN ADD',
        badge: 'LEAN ADD',
        color: AppColors.lightGreen,
        score: score,
        reasons: reasons,
      );
    } else if (score < 0.5) {
      return Signal(
        type: SignalType.hold,
        label: 'HOLD',
        badge: 'HOLD',
        color: AppColors.blue,
        score: score,
        reasons: reasons,
      );
    } else if (score < 2) {
      return Signal(
        type: SignalType.leanReduce,
        label: 'LEAN REDUCE',
        badge: 'LEAN SELL',
        color: AppColors.yellow,
        score: score,
        reasons: reasons,
      );
    } else if (score < 4) {
      return Signal(
        type: SignalType.bookPartial,
        label: 'BOOK PARTIAL',
        badge: 'BOOK PROFIT',
        color: AppColors.amber,
        score: score,
        reasons: reasons,
      );
    } else {
      return Signal(
        type: SignalType.strongReduce,
        label: 'STRONG REDUCE',
        badge: 'REDUCE',
        color: AppColors.red,
        score: score,
        reasons: reasons,
      );
    }
  }
}

class MarketSignal {
  final String label;
  final Color color;

  const MarketSignal({required this.label, required this.color});

  static MarketSignal? fromChange(double changePct) {
    if (changePct >= 5) {
      return const MarketSignal(label: 'MOMENTUM', color: AppColors.green);
    } else if (changePct >= 2) {
      return const MarketSignal(label: 'GAINING', color: AppColors.lightGreen);
    } else if (changePct <= -7) {
      return const MarketSignal(label: 'BIG DIP', color: AppColors.amber);
    } else if (changePct <= -4) {
      return const MarketSignal(label: 'PULLBACK', color: AppColors.yellow);
    }
    return null;
  }
}
