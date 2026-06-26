import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../models/sector.dart';

class DonutChart extends StatelessWidget {
  final List<SectorAllocation> sectors;
  final double size;

  const DonutChart({super.key, required this.sectors, this.size = 180});

  @override
  Widget build(BuildContext context) {
    if (sectors.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(sectors: sectors),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${sectors.length}',
                style: AppTheme.monoLarge.copyWith(fontSize: 28),
              ),
              Text(
                'Sectors',
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<SectorAllocation> sectors;

  _DonutPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final total = sectors.fold<double>(0, (s, e) => s + e.investPct);
    if (total <= 0) return;

    double startAngle = -math.pi / 2;

    for (final sector in sectors) {
      final sweepAngle = (sector.investPct / total) * 2 * math.pi;
      final paint = Paint()
        ..color = sector.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final gap = sweepAngle > 0.04 ? 0.02 : 0.0;
      canvas.drawArc(rect, startAngle, sweepAngle - gap, false, paint);
      startAngle += sweepAngle;
    }

    // Draw inner circle for clean donut look
    final innerPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - strokeWidth - 2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
