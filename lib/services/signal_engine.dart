import '../models/signal.dart';

class SignalEngine {
  SignalEngine._();

  static Signal computeSignal({
    required double currentPrice,
    required double avgCost,
    required double profitPct,
    required double w52High,
    required double w52Low,
    required double portfolioWeight,
  }) {
    double score = 0;
    final reasons = <String>[];

    // Factor 1: 52-Week Position
    if (w52High > w52Low && w52High > 0) {
      final w52Range = w52High - w52Low;
      final w52Position = (currentPrice - w52Low) / w52Range;
      final pctile = (w52Position * 100).round();
      final pctFromPeak =
          ((1 - currentPrice / w52High) * 100).toStringAsFixed(1);

      if (w52Position < 0.25) {
        score -= 3;
        reasons.add(
            'Near 52-week low \u2014 $pctFromPeak% below yearly high. Accumulation zone.');
      } else if (w52Position < 0.40) {
        score -= 1.5;
        reasons.add(
            'In lower range of 52-week band (${pctile}th percentile).');
      } else if (w52Position > 0.90) {
        score += 3;
        reasons.add(
            'Near 52-week high \u2014 only $pctFromPeak% from peak. Consider profit booking.');
      } else if (w52Position > 0.75) {
        score += 1.5;
        reasons
            .add('In upper 52-week range (${pctile}th percentile).');
      } else {
        reasons
            .add('Mid-range of 52-week band (${pctile}th percentile).');
      }
    } else {
      reasons.add('52-week data unavailable.');
    }

    // Factor 2: Distance from Cost Basis
    if (profitPct < -20) {
      score -= 2.5;
      reasons.add(
          '${profitPct.toStringAsFixed(1)}% below cost \u2014 strong averaging opportunity if thesis intact.');
    } else if (profitPct < -10) {
      score -= 1.5;
      reasons.add(
          '${profitPct.toStringAsFixed(1)}% below cost. Consider averaging down.');
    } else if (profitPct > 60) {
      score += 2;
      reasons.add(
          '${profitPct.toStringAsFixed(1)}% gain \u2014 consider booking partial profits.');
    } else if (profitPct > 35) {
      score += 1;
      reasons.add(
          'Healthy ${profitPct.toStringAsFixed(1)}% return. Let winners run.');
    } else if (profitPct > 10) {
      reasons.add(
          'Moderate ${profitPct.toStringAsFixed(1)}% gain \u2014 hold and monitor.');
    } else {
      reasons.add('Near cost basis. Wait for clarity.');
    }

    // Factor 3: Portfolio Concentration
    if (portfolioWeight > 20) {
      score += 2;
      reasons.add(
          '\u26A0\uFE0F ${portfolioWeight.toStringAsFixed(1)}% of portfolio \u2014 overweight. Consider trimming.');
    } else if (portfolioWeight > 12) {
      score += 0.5;
      reasons.add(
          '${portfolioWeight.toStringAsFixed(1)}% of portfolio \u2014 slightly heavy.');
    } else if (portfolioWeight < 3 && profitPct > 0) {
      score -= 0.5;
      reasons.add(
          'Only ${portfolioWeight.toStringAsFixed(1)}% \u2014 small position. Room to add.');
    }

    // Factor 4: Trend Direction
    if (w52High > 0 && w52Low > 0) {
      final w52Mid = (w52High + w52Low) / 2;
      if (currentPrice > w52Mid * 1.1) {
        reasons.add('Above 52-week midpoint \u2014 uptrend intact.');
      } else if (currentPrice < w52Mid * 0.9) {
        score -= 0.5;
        reasons.add(
            'Below 52-week midpoint \u2014 verify fundamentals.');
      }
    }

    return Signal.fromScore(score, reasons);
  }
}
