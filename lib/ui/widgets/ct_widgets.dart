import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Cream card with shadow and hairline border
class CTCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;

  const CTCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: surfaceCard(color: color, radius: radius),
      child: child,
    );
  }
}

// ─── Pill badge ──────────────────────────────────────────────────────────────

enum CTPillTone { crema, tea, burnt, neutral, night, ink }

class CTPill extends StatelessWidget {
  final String label;
  final CTPillTone tone;
  final String? dotColor; // hex string or null
  final bool small;

  const CTPill({
    super.key,
    required this.label,
    this.tone = CTPillTone.neutral,
    this.dotColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case CTPillTone.crema:
        bg = AppColors.cremaTn;
        fg = AppColors.cremaDk;
        break;
      case CTPillTone.tea:
        bg = AppColors.teaTn;
        fg = AppColors.tea;
        break;
      case CTPillTone.burnt:
        bg = AppColors.burntTn;
        fg = AppColors.burnt;
        break;
      case CTPillTone.night:
        bg = AppColors.night;
        fg = Colors.white;
        break;
      case CTPillTone.ink:
        bg = AppColors.ink;
        fg = AppColors.bg;
        break;
      case CTPillTone.neutral:
        bg = AppColors.bg2;
        fg = AppColors.muted;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTEyebrow ───────────────────────────────────────────────────────────────

class CTEyebrow extends StatelessWidget {
  final String text;
  final Color? color;

  const CTEyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.12 * 11,
        color: color ?? AppColors.muted,
      ),
    );
  }
}

// ─── DrinkIcon ───────────────────────────────────────────────────────────────

class DrinkIcon extends StatelessWidget {
  final String kind; // espresso, coffee, tea, matcha, energy, soda
  final double size;

  const DrinkIcon({super.key, required this.kind, this.size = 22});

  IconData get _icon {
    switch (kind) {
      case 'espresso':
        return Icons.coffee;
      case 'coffee':
        return Icons.local_cafe;
      case 'tea':
        return Icons.eco;
      case 'matcha':
        return Icons.eco;
      case 'energy':
        return Icons.bolt;
      case 'soda':
        return Icons.local_drink;
      default:
        return Icons.coffee;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: size, color: AppColors.ink2);
  }
}

// ─── CTStatusBar ─────────────────────────────────────────────────────────────

class CTStatusBar extends StatelessWidget {
  final String time;
  final bool dark;

  const CTStatusBar({super.key, this.time = '8:42', this.dark = false});

  @override
  Widget build(BuildContext context) {
    final c = dark ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: TextStyle(
              color: c,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 80),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 16, color: c),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: c),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── CTTabBar ────────────────────────────────────────────────────────────────

class CTTabBar extends StatelessWidget {
  final int activeIndex; // 0=Today,1=History,2=Log,3=Sleep,4=Library
  final ValueChanged<int>? onTap;
  final bool dark;

  const CTTabBar({
    super.key,
    required this.activeIndex,
    this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.night : AppColors.bg;
    final activeColor = dark ? Colors.white : AppColors.ink;
    final inactiveColor = dark ? Colors.white54 : AppColors.muted2;

    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Today'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'History'),
      (null, null, 'Log'), // special center button
      (Icons.bedtime_outlined, Icons.bedtime_rounded, 'Sleep'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Library'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: const [0.0, 0.65, 1.0],
          colors: [bg, bg, bg.withAlpha(0)],
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isCenter = i == 2;
          final isActive = activeIndex == i;

          if (isCenter) {
            return Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => onTap?.call(i),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withAlpha(65),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: AppColors.bg, size: 26),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap?.call(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.$2! : item.$1!,
                      size: 22,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? activeColor : inactiveColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── CTSlider ────────────────────────────────────────────────────────────────

class CTSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;
  final String? label;

  const CTSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.activeColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: activeColor ?? AppColors.crema,
        thumbColor: activeColor ?? AppColors.crema,
        overlayColor: (activeColor ?? AppColors.crema).withAlpha(30),
        inactiveTrackColor: AppColors.bg2,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Mono number helper ───────────────────────────────────────────────────────

TextStyle get monoStyle => GoogleFonts.jetBrainsMono(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
      letterSpacing: -0.02,
    );

TextStyle displayStyle({
  double size = 96,
  bool italic = true,
  Color color = AppColors.ink,
}) =>
    GoogleFonts.newsreader(
      fontSize: size,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontWeight: FontWeight.w300,
      height: 0.95,
      letterSpacing: -0.02 * size,
      color: color,
    );
