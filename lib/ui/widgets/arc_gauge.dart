import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gradient arc gauge rendered with CustomPainter.
///
/// Spans 240° starting at the 7-o'clock position, sweeping clockwise to
/// 5 o'clock. Gradient runs green → amber → red. A glow effect and a bright
/// tip dot give the Oura-ring aesthetic.
class ArcGauge extends StatefulWidget {
  final double value; // 0.0 – 1.0
  final double size;
  final double strokeWidth;

  const ArcGauge({
    super.key,
    required this.value,
    this.size = 180,
    this.strokeWidth = 16,
  });

  @override
  State<ArcGauge> createState() => _ArcGaugeState();
}

class _ArcGaugeState extends State<ArcGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _from = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ArcGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final animated = _from + (_anim.value * (widget.value - _from));
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ArcGaugePainter(
            value: animated.clamp(0.0, 1.0),
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final double strokeWidth;

  // Arc: start at 210° from 12-o'clock (7 o'clock), sweep 240° CW.
  // In Flutter canvas coords (0° = 3 o'clock, CW = positive):
  //   7 o'clock = 210° from 12 = 120° from 3  → 120° → 2π/3 rad
  //   sweep = 240° → 4π/3 rad
  static const double _startRad = 120 * math.pi / 180;
  static const double _sweepRad = 240 * math.pi / 180;

  // Gradient anchors in the same coordinate system
  static const double _gradStart = _startRad;
  static const double _gradEnd = _startRad + _sweepRad;

  static const _colorSafe = Color(0xFF4ADE80);
  static const _colorCaution = Color(0xFFFBBF24);
  static const _colorDanger = Color(0xFFF87171);

  const _ArcGaugePainter({required this.value, required this.strokeWidth});

  Color get _tipColor {
    if (value < 0.33) return _colorSafe;
    if (value < 0.66) return _colorCaution;
    return _colorDanger;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── 1. Background track ─────────────────────────────────────────
    canvas.drawArc(
      rect,
      _startRad,
      _sweepRad,
      false,
      Paint()
        ..color = Colors.white.withAlpha(18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (value <= 0) return;

    final activeSwep = _sweepRad * value;

    // ── 2. Soft outer glow ──────────────────────────────────────────
    canvas.drawArc(
      rect,
      _startRad,
      activeSwep,
      false,
      Paint()
        ..color = _tipColor.withAlpha(35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // ── 3. Gradient value arc ────────────────────────────────────────
    canvas.drawArc(
      rect,
      _startRad,
      activeSwep,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: _gradStart,
          endAngle: _gradEnd,
          colors: [_colorSafe, _colorCaution, _colorDanger],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── 4. Tip dot ──────────────────────────────────────────────────
    final tipAngle = _startRad + activeSwep;
    final tipOffset = Offset(
      cx + radius * math.cos(tipAngle),
      cy + radius * math.sin(tipAngle),
    );
    final dotR = strokeWidth / 2;

    // Outer glow
    canvas.drawCircle(
      tipOffset,
      dotR + 5,
      Paint()
        ..color = _tipColor.withAlpha(70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // White core
    canvas.drawCircle(
      tipOffset,
      dotR - 1,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.value != value;
}
