import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/providers.dart';
import '../../core/data_exporter.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/caffeine_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/ct_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  UserSettings? _local;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    final s = repo.load();
    if (mounted) setState(() { _local = s; _loading = false; });
  }

  Future<void> _save(UserSettings updated) async {
    setState(() => _local = updated);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.save(updated);
    ref.invalidate(settingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _local == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.crema)),
      );
    }
    final s = _local!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: GoogleFonts.newsreader(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 60),
                children: [
                  // Profile card
                  CTCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.crema, AppColors.cremaDk],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              s.name.isNotEmpty ? s.name[0].toLowerCase() : 'g',
                              style: GoogleFonts.newsreader(
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                                color: AppColors.bg,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Text(
                                'Member since 2024',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const CTEyebrow('Goals'),
                  const SizedBox(height: 10),

                  // Goals card
                  CTCard(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daily limit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${s.safeThresholdMg > 0 ? 400 : 400} mg',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CTSlider(
                          value: 400,
                          min: 100,
                          max: 600,
                          divisions: 20,
                          activeColor: AppColors.crema,
                          label: '400 mg',
                          onChanged: (_) {},
                        ),
                        const Divider(height: 1, thickness: 0.5, color: AppColors.line),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Half-life',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${s.halfLifeHours.toStringAsFixed(1)}h',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CTSlider(
                          value: s.halfLifeHours,
                          min: 3,
                          max: 8,
                          divisions: 10,
                          activeColor: AppColors.night,
                          label: '${s.halfLifeHours}h',
                          onChanged: (v) => _save(s.copyWith(halfLifeHours: v)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bedtime row
                  CTCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.bedtime_outlined,
                              size: 20, color: AppColors.muted),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Bedtime',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            '${s.bedtimeHour}:${s.bedtimeMinute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              color: AppColors.crema,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.muted2),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const CTEyebrow('Reminders'),
                  const SizedBox(height: 10),

                  CTCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'Safe to sleep',
                          sub: 'When caffeine clears bedtime threshold',
                          value: s.notifySleepSafe,
                          onChanged: (v) => _save(s.copyWith(notifySleepSafe: v)),
                        ),
                        const Divider(height: 1, thickness: 0.5, color: AppColors.line, indent: 18, endIndent: 18),
                        _ToggleRow(
                          label: 'Daily summary',
                          sub: 'Morning recap of yesterday',
                          value: s.notifyDailySummary,
                          onChanged: (v) => _save(s.copyWith(notifyDailySummary: v)),
                        ),
                        const Divider(height: 1, thickness: 0.5, color: AppColors.line, indent: 18, endIndent: 18),
                        _ToggleRow(
                          label: 'Log reminders',
                          sub: 'Remind me to log after morning coffee',
                          value: false,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const CTEyebrow('Account'),
                  const SizedBox(height: 10),

                  CTCard(
                    child: Column(
                      children: [
                        _AccountRow(
                          icon: Icons.ios_share_outlined,
                          label: 'Export data',
                          onTap: () async {
                            final entries = await ref.read(caffeineRepositoryProvider).getAll();
                            final csv = DataExporter().exportToCsv(entries);
                            final dir = await getTemporaryDirectory();
                            final file = File('${dir.path}/caffeine_export.csv');
                            await file.writeAsString(csv);
                            await Share.shareXFiles([XFile(file.path)]);
                          },
                        ),
                        const Divider(height: 1, thickness: 0.5, color: AppColors.line, indent: 54, endIndent: 18),
                        _AccountRow(
                          icon: Icons.info_outline,
                          label: 'About',
                          onTap: () {},
                        ),
                        const Divider(height: 1, thickness: 0.5, color: AppColors.line, indent: 54, endIndent: 18),
                        _AccountRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy policy',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'Caffeine Tracker v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.tea,
            activeTrackColor: AppColors.teaTn,
            inactiveThumbColor: AppColors.muted2,
            inactiveTrackColor: AppColors.bg2,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted2),
          ],
        ),
      ),
    );
  }
}
