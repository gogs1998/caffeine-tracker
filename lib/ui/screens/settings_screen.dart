import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/providers.dart';
import '../../core/data_exporter.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';

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
        backgroundColor: Color(0xFF12121A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    final s = _local!;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── SECTION A: Profile ──────────────────────────────────────────────
          const _SectionHeader('Profile'),
          _SettingsCard(children: [
            // Half-life slider
            ListTile(
              title: const Text('Caffeine half-life',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                '${s.halfLifeHours.toStringAsFixed(1)} hours  •  How quickly your body processes caffeine',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.amber,
                  thumbColor: Colors.amber,
                  inactiveTrackColor: Colors.white12,
                  overlayColor: Colors.amber.withAlpha(40),
                ),
                child: Slider(
                  value: s.halfLifeHours,
                  min: 3.0,
                  max: 9.0,
                  divisions: 12,
                  label: '${s.halfLifeHours.toStringAsFixed(1)}h',
                  onChanged: (v) => _save(s.copyWith(halfLifeHours: v)),
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Bedtime
            ListTile(
              title: const Text('Bedtime',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                '${s.bedtimeHour.toString().padLeft(2, '0')}:${s.bedtimeMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      TimeOfDay(hour: s.bedtimeHour, minute: s.bedtimeMinute),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: Colors.amber, surface: Color(0xFF1E1E2E)),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  await _save(s.copyWith(
                      bedtimeHour: picked.hour,
                      bedtimeMinute: picked.minute));
                }
              },
            ),
            const Divider(color: Colors.white12, height: 1),

            // Safe threshold
            ListTile(
              title: const Text('Safe threshold',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                '${s.safeThresholdMg.toStringAsFixed(0)} mg  •  Caffeine level considered safe for sleep',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.greenAccent,
                  thumbColor: Colors.greenAccent,
                  inactiveTrackColor: Colors.white12,
                  overlayColor: Colors.greenAccent.withAlpha(40),
                ),
                child: Slider(
                  value: s.safeThresholdMg,
                  min: 25.0,
                  max: 100.0,
                  divisions: 15,
                  label: '${s.safeThresholdMg.toStringAsFixed(0)} mg',
                  onChanged: (v) => _save(s.copyWith(safeThresholdMg: v)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── SECTION B: GLP-1 ───────────────────────────────────────────────
          const _SectionHeader('GLP-1 Medication'),
          _SettingsCard(children: [
            SwitchListTile(
              title: const Text("I'm on a GLP-1 medication",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'GLP-1 medications slow gastric emptying and may increase caffeine sensitivity',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: s.glp1Mode,
              activeColor: Colors.amber,
              onChanged: (v) {
                final med = v ? (s.glp1Medication ?? 'Mounjaro') : null;
                final multiplier = v
                    ? (glp1Multipliers[med ?? 'Mounjaro'] ?? 1.5)
                    : 1.0;
                _save(s.copyWith(
                  glp1Mode: v,
                  glp1Medication: med,
                  sensitivityMultiplier: multiplier,
                ));
              },
            ),
            if (s.glp1Mode) ...[
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: s.glp1Medication ?? 'Mounjaro',
                  dropdownColor: const Color(0xFF1E1E2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Medication',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: glp1Multipliers.keys
                      .map((med) => DropdownMenuItem(
                            value: med,
                            child: Text(med),
                          ))
                      .toList(),
                  onChanged: (med) {
                    if (med != null) {
                      _save(s.copyWith(
                        glp1Medication: med,
                        sensitivityMultiplier: glp1Multipliers[med] ?? 1.0,
                      ));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${(glp1Multipliers[s.glp1Medication ?? 'Mounjaro'] ?? 1.5)}× slower metabolism applied',
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 20),

          // ── SECTION C: Notifications ───────────────────────────────────────
          const _SectionHeader('Notifications'),
          _SettingsCard(children: [
            SwitchListTile(
              title: const Text('Safe-to-sleep reminder',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Notify when caffeine is safe for sleep',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: s.notifySleepSafe,
              activeColor: Colors.amber,
              onChanged: (v) => _save(s.copyWith(notifySleepSafe: v)),
            ),
            const Divider(color: Colors.white12, height: 1),
            SwitchListTile(
              title: const Text('Daily caffeine summary',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("End-of-day summary of today's intake",
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: s.notifyDailySummary,
              activeColor: Colors.amber,
              onChanged: (v) => _save(s.copyWith(notifyDailySummary: v)),
            ),
          ]),
          const SizedBox(height: 20),

          // ── SECTION D: Pro ─────────────────────────────────────────────────
          const _SectionHeader('Pro'),
          _SettingsCard(children: [
            ListTile(
              leading: const Text('⭐', style: TextStyle(fontSize: 22)),
              title: const Text('Caffeine Tracker Pro',
                  style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.w600)),
              subtitle: const Text('£2.99/year — Voice, Barcode, AI & more',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
              onTap: () => context.push('/paywall'),
            ),
          ]),
          const SizedBox(height: 20),

          // ── SECTION E: Export ──────────────────────────────────────────────
          const _SectionHeader('Data'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: Colors.white70),
              title: const Text('Export Data',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Share your caffeine log as CSV',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
              onTap: () => _exportData(context),
            ),
          ]),
          const SizedBox(height: 20),

          // ── SECTION F: About ───────────────────────────────────────────────
          const _SectionHeader('About'),
          _SettingsCard(children: [
            const ListTile(
              title: Text('Version',
                  style: TextStyle(color: Colors.white)),
              trailing: Text('1.0.0', style: TextStyle(color: Colors.white54)),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              title: const Text('Privacy Policy',
                  style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.open_in_new,
                  color: Colors.white30, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Privacy policy URL coming soon'),
                  backgroundColor: Color(0xFF1E1E2E),
                ));
              },
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final entries = await ref.read(caffeineRepositoryProvider).getAll();
    final csv = DataExporter().exportToCsv(entries);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/caffeine_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Caffeine Tracker export',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(children: children),
    );
  }
}
