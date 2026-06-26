import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MiniSparkline extends StatelessWidget {
  final double current;
  final double high;
  final double low;
  final double avgCost;
  final Color color;

  const MiniSparkline({
    super.key,
    required this.current,
    required this.high,
    required this.low,
    required this.avgCost,
    this.color = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    if (high <= low || high <= 0) {
      return SizedBox(
        width: 50,
        height: 30,
        child: Center(
          child: Container(
            height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return SizedBox(
      width: 50,
      height: 30,
      child: CustomPaint(
        painter: _SparklinePainter(
          current: current,
          high: high,
          low: low,
          avgCost: avgCost,
          color: color,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final double current;
  final double high;
  final double low;
  final double avgCost;
  final Color color;

  _SparklinePainter({
    required this.current,
    required this.high,
    required this.low,
    required this.avgCost,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final range = high - low;
    if (range <= 0) return;

    final currentY = size.height - ((current - low) / range) * size.height;
    final costY = size.height - ((avgCost - low) / range) * size.height;

    // Simple area representation
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, costY.clamp(0, size.height))
      ..quadraticBezierTo(
        size.width * 0.3,
        (costY + currentY) / 2,
        size.width * 0.6,
        currentY.clamp(0, size.height),
      )
      ..lineTo(size.width, currentY.clamp(0, size.height))
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fillPaint);

    // Line on top
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePath = Path()
      ..moveTo(0, costY.clamp(0, size.height))
      ..quadraticBezierTo(
        size.width * 0.3,
        (costY + currentY) / 2,
        size.width * 0.6,
        currentY.clamp(0, size.height),
      )
      ..lineTo(size.width, currentY.clamp(0, size.height));

    canvas.drawPath(linePath, linePaint);

    // Current price dot
    canvas.drawCircle(
      Offset(size.width, currentY.clamp(0, size.height)),
      2.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
