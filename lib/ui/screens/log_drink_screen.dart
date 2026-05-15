import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/caffeine_entry.dart';
import '../../data/models/drink_preset.dart';
import '../../data/repositories/caffeine_repository.dart';
import '../theme/app_theme.dart';
import 'preset_picker_screen.dart';

class LogDrinkScreen extends StatefulWidget {
  final String? initialName;
  final double? initialMg;

  const LogDrinkScreen({super.key, this.initialName, this.initialMg});

  @override
  State<LogDrinkScreen> createState() => _LogDrinkScreenState();
}

class _LogDrinkScreenState extends State<LogDrinkScreen> {
  final CaffeineRepository _repo = CaffeineRepository();
  final _formKey = GlobalKey<FormState>();
  final _customAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DrinkPreset? _selectedPreset;
  DateTime _consumedAt = DateTime.now();
  bool _saving = false;
  String? _voiceName; // pre-filled from voice parser

  @override
  void initState() {
    super.initState();
    if (widget.initialMg != null) {
      _customAmountController.text = widget.initialMg!.toInt().toString();
    }
    _voiceName = widget.initialName;
  }

  Future<void> _pickPreset() async {
    final preset = await Navigator.push<DrinkPreset>(
      context,
      MaterialPageRoute(builder: (_) => const PresetPickerScreen()),
    );
    if (preset != null) {
      setState(() {
        _selectedPreset = preset;
        _customAmountController.text = preset.mgAmount.toInt().toString();
      });
    }
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _consumedAt,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consumedAt),
    );
    if (time == null) return;

    setState(() {
      _consumedAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _logIt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPreset == null && _customAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a drink or enter an amount')),
      );
      return;
    }

    final mgText = _customAmountController.text.trim();
    final mg = mgText.isNotEmpty
        ? double.tryParse(mgText) ?? _selectedPreset?.mgAmount ?? 0
        : _selectedPreset?.mgAmount ?? 0;

    final drinkName = _selectedPreset?.name ??
        _voiceName ??
        (_customAmountController.text.isNotEmpty ? 'Custom Drink' : 'Unknown');

    final entry = CaffeineEntry(
      id: const Uuid().v4(),
      drinkName: drinkName,
      mgAmount: mg,
      consumedAt: _consumedAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      presetId: _selectedPreset?.id,
    );

    setState(() => _saving = true);
    try {
      await _repo.insert(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${entry.drinkName} (${mg.toInt()} mg)'),
          ),
        );
        Navigator.pop(context, entry);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Log a Drink'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Choose a preset ──────────────────────────
            const _SectionLabel(label: 'CHOOSE A DRINK'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPreset,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Browse Drinks'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.glassBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_selectedPreset != null) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.amber.withAlpha(80)),
                ),
                child: ListTile(
                  leading: Text(
                    _selectedPreset!.iconEmoji ?? '☕',
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(_selectedPreset!.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: _selectedPreset!.brand != null
                      ? Text(_selectedPreset!.brand!,
                          style: const TextStyle(
                              color: AppColors.textTertiary))
                      : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedPreset!.mgAmount.toInt()} mg',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  onTap: _pickPreset,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Section 2: Custom amount override ───────────────────
            const _SectionLabel(label: 'CUSTOM AMOUNT (OPTIONAL)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Caffeine (mg)',
                hintText: 'e.g. 150',
                suffixText: 'mg',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final v = double.tryParse(value.trim());
                if (v == null || v < 0) return 'Enter a valid amount';
                if (v > 2000) return 'Amount seems too high';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Section 3: Time picker ───────────────────────────────
            const _SectionLabel(label: 'TIME'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(_formatDateTime(_consumedAt)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.glassBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.centerLeft,
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 4: Notes ─────────────────────────────────────
            const _SectionLabel(label: 'NOTES (OPTIONAL)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g. after gym, felt tired…',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 28),

            // ── Log it button ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _saving ? null : _logIt,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black54),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Log it'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (dtDay == today) return 'Today at $timeStr';
    final yesterday = today.subtract(const Duration(days: 1));
    if (dtDay == yesterday) return 'Yesterday at $timeStr';
    return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
