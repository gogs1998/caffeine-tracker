import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/caffeine_entry.dart';
import '../../data/models/drink_preset.dart';
import '../../data/repositories/caffeine_repository.dart';
import 'preset_picker_screen.dart';

class LogDrinkScreen extends StatefulWidget {
  const LogDrinkScreen({super.key});

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a Drink'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Choose a preset ──────────────────────────
            const _SectionLabel(label: '1. Choose a Preset'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPreset,
              icon: const Icon(Icons.search),
              label: const Text('Browse Drinks'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (_selectedPreset != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Text(
                    _selectedPreset!.iconEmoji ?? '☕',
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(_selectedPreset!.name,
                      style: theme.textTheme.titleMedium),
                  subtitle: _selectedPreset!.brand != null
                      ? Text(_selectedPreset!.brand!)
                      : null,
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedPreset!.mgAmount.toInt()} mg',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: _pickPreset,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Section 2: Custom amount override ───────────────────
            const _SectionLabel(label: '2. Custom Amount (optional override)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Caffeine (mg)',
                hintText: 'e.g. 150',
                suffixText: 'mg',
                border: OutlineInputBorder(),
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
            const _SectionLabel(label: '3. Time'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(_formatDateTime(_consumedAt)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                alignment: Alignment.centerLeft,
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 4: Notes ─────────────────────────────────────
            const _SectionLabel(label: '4. Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g. after gym, felt tired…',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 28),

            // ── Log it button ────────────────────────────────────────
            FilledButton.icon(
              onPressed: _saving ? null : _logIt,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Log it'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
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
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
