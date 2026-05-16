import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/caffeine_calculator.dart';
import '../../data/models/caffeine_entry.dart';
import '../theme/app_theme.dart';

/// Caffeine decay curve using CustomPainter.
/// Shows solid line for past, dashed for future, NOW dot, bedtime line, limit line.
class CaffeineCurve extends StatelessWidget {
  final List<CaffeineEntry> entries;
  final DateTime now;
  final double bedtimeHour; // e.g. 23.0
  final double limitMg;
  final double halfLifeHours;
  final bool nightScheme;
  final double height;

  const CaffeineCurve({
    super.key,
    required this.entries,
    required this.now,
    this.bedtimeHour = 23.0,
    this.limitMg = 400,
    this.halfLifeHours = 5.0,
    this.nightScheme = false,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CurvePainter(
          entries: entries,
          now: now,
          bedtimeHour: bedtimeHour,
          limitMg: limitMg,
          halfLifeHours: halfLifeHours,
          nightScheme: nightScheme,
        ),
        child: _XAxisLabels(nightScheme: nightScheme),
      ),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  final bool nightScheme;
  const _XAxisLabels({this.nightScheme = false});

  @override
  Widget build(BuildContext context) {
    final color = nightScheme
        ? Colors.white54
        : AppColors.muted2;
    const labels = ['6A', '10A', '2P', '6P', '10P'];
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2, left: 8, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map((l) => Text(
                    l,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: color,
                      letterSpacing: 0.02,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<CaffeineEntry> entries;
  final DateTime now;
  final double bedtimeHour;
  final double limitMg;
  final double halfLifeHours;
  final bool nightScheme;

  _CurvePainter({
    required this.entries,
    required this.now,
    required this.bedtimeHour,
    required this.limitMg,
    required this.halfLifeHours,
    required this.nightScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Time range: 6:00 AM to 11:00 PM of today
    final today = DateTime(now.year, now.month, now.day);
    const startH = 6.0;
    const endH = 23.0;
    const rangeH = endH - startH;

    final calc = CaffeineCalculator(halfLifeHours: halfLifeHours);

    // Generate points (200 steps)
    const steps = 200;
    final points = <Offset>[];
    double maxLevel = limitMg * 1.2;
    final levels = <double>[];

    for (int i = 0; i <= steps; i++) {
      final h = startH + (rangeH * i / steps);
      final t = today.add(Duration(minutes: (h * 60).round()));
      final level = calc.levelAt(entries, t);
      levels.add(level);
      if (level > maxLevel) maxLevel = level;
    }
    if (maxLevel < limitMg * 1.1) maxLevel = limitMg * 1.1;

    final chartBottom = size.height - 20; // leave room for axis labels
    const chartTop = 8.0;
    final chartHeight = chartBottom - chartTop;

    double toX(double h) => (h - startH) / rangeH * size.width;
    double toY(double mg) =>
        chartBottom - (mg / maxLevel) * chartHeight;

    for (int i = 0; i <= steps; i++) {
      final h = startH + (rangeH * i / steps);
      final x = toX(h);
      final y = toY(levels[i]);
      points.add(Offset(x, y));
    }

    final nowH = now.hour + now.minute / 60.0;
    final nowX = toX(nowH.clamp(startH, endH));
    // Find now index
    final nowIdx = ((nowH - startH) / rangeH * steps).round().clamp(0, steps);

    final lineColor = nightScheme ? const Color(0xFFF2EBDF) : AppColors.crema;
    final lineColorFuture = nightScheme
        ? const Color(0x80F2EBDF)
        : AppColors.crema.withAlpha(100);

    // ── Draw limit line ──
    final limitY = toY(limitMg);
    if (limitMg < maxLevel) {
      final limitPaint = Paint()
        ..color = AppColors.burnt.withAlpha(120)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      _drawDashedHLine(canvas, limitPaint, 0, size.width, limitY, 6, 4);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: '${limitMg.toInt()} mg limit',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            color: AppColors.burnt.withAlpha(180),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 4, limitY - 11));
    }

    // ── Draw bedtime line ──
    if (bedtimeHour >= startH && bedtimeHour <= endH) {
      final bedX = toX(bedtimeHour);
      final bedPaint = Paint()
        ..color = AppColors.night.withAlpha(100)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      _drawDashedVLine(canvas, bedPaint, bedX, chartTop, chartBottom, 5, 4);
    }

    // ── Draw past curve (solid) ──
    if (nowIdx > 0) {
      final pastPath = Path();
      pastPath.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i <= nowIdx && i <= steps; i++) {
        pastPath.lineTo(points[i].dx, points[i].dy);
      }
      final pastPaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(pastPath, pastPaint);
    }

    // ── Draw future curve (dashed) ──
    if (nowIdx < steps) {
      final futurePaint = Paint()
        ..color = lineColorFuture
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawDashedPath(
          canvas, futurePaint, points.sublist(nowIdx), 8, 5);
    }

    // ── Draw NOW dot ──
    if (nowH >= startH && nowH <= endH) {
      final nowY = toY(levels[nowIdx]);
      final dotPaint = Paint()
        ..color = nightScheme ? Colors.white : AppColors.ink
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nowX, nowY), 6, dotPaint);
      final innerPaint = Paint()
        ..color = nightScheme ? AppColors.night : AppColors.bg
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nowX, nowY), 3, innerPaint);
    }
  }

  void _drawDashedHLine(Canvas c, Paint p, double x1, double x2, double y,
      double dash, double gap) {
    double x = x1;
    while (x < x2) {
      c.drawLine(Offset(x, y), Offset((x + dash).clamp(x1, x2), y), p);
      x += dash + gap;
    }
  }

  void _drawDashedVLine(Canvas c, Paint p, double x, double y1, double y2,
      double dash, double gap) {
    double y = y1;
    while (y < y2) {
      c.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(y1, y2)), p);
      y += dash + gap;
    }
  }

  void _drawDashedPath(Canvas c, Paint p, List<Offset> pts, double dash,
      double gap) {
    if (pts.length < 2) return;
    double remaining = dash;
    bool drawing = true;
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);

    for (int i = 1; i < pts.length; i++) {
      final dx = pts[i].dx - pts[i - 1].dx;
      final dy = pts[i].dy - pts[i - 1].dy;
      final segLen = (Offset(dx, dy)).distance;
      double traveled = 0;
      while (traveled < segLen) {
        final t = (traveled + remaining).clamp(0, segLen);
        final ratio = t / segLen;
        final pt = Offset(
          pts[i - 1].dx + dx * ratio,
          pts[i - 1].dy + dy * ratio,
        );
        if (drawing) {
          path.lineTo(pt.dx, pt.dy);
        } else {
          path.moveTo(pt.dx, pt.dy);
        }
        traveled += remaining;
        if (traveled >= segLen) break;
        drawing = !drawing;
        remaining = drawing ? dash : gap;
      }
      remaining = remaining - (segLen - (traveled - remaining));
      if (remaining <= 0) {
        drawing = !drawing;
        remaining = drawing ? dash : gap;
      }
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.entries != entries || old.now != now;
}
