import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../core/voice_parser.dart';
import '../../data/models/caffeine_entry.dart';
import '../../core/providers.dart';
import '../screens/log_drink_screen.dart';

class VoiceInputButton extends ConsumerStatefulWidget {
  const VoiceInputButton({super.key});

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final VoiceParser _parser = VoiceParser();
  bool _isListening = false;
  bool _available = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.stop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onMicPressed() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.reset();
      });
      return;
    }

    // First-time init / permission
    if (!_available) {
      _available = await _speech.initialize(
        onError: (e) {
          setState(() {
            _isListening = false;
            _pulseController.stop();
            _pulseController.reset();
          });
        },
      );
    }

    if (!_available) {
      if (!mounted) return;
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isListening = true;
      _pulseController.repeat(reverse: true);
    });

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleTranscript(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: false),
    );
  }

  void _handleTranscript(String transcript) {
    setState(() {
      _isListening = false;
      _pulseController.stop();
      _pulseController.reset();
    });

    final parsed = _parser.parse(transcript);

    if (parsed == null) {
      _showSnack("Couldn't understand — try again or log manually");
      return;
    }

    if (parsed.confidence >= 0.5) {
      // Auto-log
      _logEntry(parsed.name, parsed.mg);
      _showSnack('Heard: ${parsed.name} (${parsed.mg.toStringAsFixed(0)}mg) — Logged!');
    } else {
      // Open LogDrinkScreen pre-filled
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LogDrinkScreen(
            initialName: parsed.name,
            initialMg: parsed.mg,
          ),
        ),
      );
    }
  }

  Future<void> _logEntry(String name, double mg) async {
    final entry = CaffeineEntry(
      id: const Uuid().v4(),
      drinkName: name,
      mgAmount: mg,
      consumedAt: DateTime.now(),
    );
    await ref.read(caffeineRepositoryProvider).insert(entry);
    ref.invalidate(entriesProvider);
    ref.invalidate(currentLevelProvider);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A2A3E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Microphone Permission',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Microphone access was denied. Please enable it in Settings to use voice input.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _isListening ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: FloatingActionButton(
        heroTag: 'voiceFab',
        backgroundColor: _isListening ? Colors.red : const Color(0xFF3A3A5C),
        foregroundColor: Colors.white,
        onPressed: _onMicPressed,
        tooltip: _isListening ? 'Stop listening' : 'Log with voice',
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          size: 26,
        ),
      ),
    );
  }
}
