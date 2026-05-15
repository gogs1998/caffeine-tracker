import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/advice_engine.dart';
import '../../core/providers.dart';

class AdviceScreen extends ConsumerStatefulWidget {
  const AdviceScreen({super.key});

  @override
  ConsumerState<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends ConsumerState<AdviceScreen> {
  final _controller = TextEditingController();
  String? _aiResponse;
  bool _loading = false;
  String? _error;

  static const _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askGemini(CaffeineAdvice advice, String question) async {
    if (_apiKey.isEmpty) {
      setState(() {
        _error =
            'AI chat requires an API key — set the GEMINI_API_KEY environment variable.';
        _aiResponse = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _aiResponse = null;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
You are a helpful caffeine and health assistant embedded in a caffeine tracking app.

Current caffeine status:
- Advice level: ${advice.level.name}
- Headline: ${advice.headline}
- Detail: ${advice.body}

Active tips:
${advice.tips.map((t) => '  • $t').join('\n')}

The user asks: "$question"

Please give a concise, friendly, evidence-based answer in 2-3 sentences. 
Do not provide medical diagnoses. Recommend consulting a doctor for health concerns.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _aiResponse = response.text ?? 'No response received.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'AI error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adviceAsync = ref.watch(adviceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A28),
        title: const Text(
          'Caffeine Advice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: adviceAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, _) => Center(
            child:
                Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (advice) => _buildContent(context, advice),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CaffeineAdvice advice) {
    final borderColor = _levelColor(advice.level);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Advice Card ──────────────────────────────────────────────────
          Card(
            color: const Color(0xFF1E1E2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: borderColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_levelIcon(advice.level),
                                  color: borderColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  advice.headline,
                                  style: TextStyle(
                                    color: borderColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            advice.body,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Tips ─────────────────────────────────────────────────────────
          if (advice.tips.isNotEmpty) ...[
            const Text(
              'Recommended tips',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: advice.tips
                      .map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right_rounded,
                                  color: borderColor, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── AI Ask section ────────────────────────────────────────────────
          const Text(
            'Ask a question',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask anything about your caffeine levels, sleep timing, or habits.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'e.g. Can I have another coffee?',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.amber, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.amber),
                onPressed: _loading
                    ? null
                    : () {
                        final q = _controller.text.trim();
                        if (q.isNotEmpty) _askGemini(advice, q);
                      },
              ),
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty && !_loading) {
                _askGemini(advice, q.trim());
              }
            },
          ),
          const SizedBox(height: 16),

          // ── AI Response ───────────────────────────────────────────────────
          if (_error != null)
            Card(
              color: const Color(0xFF2A1A1A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13))),
                  ],
                ),
              ),
            ),
          if (_aiResponse != null)
            Card(
              color: const Color(0xFF1A2030),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smart_toy_outlined,
                            color: Colors.blueAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Gemini says',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _aiResponse!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Color _levelColor(AdviceLevel level) {
    switch (level) {
      case AdviceLevel.warning:
        return Colors.redAccent;
      case AdviceLevel.caution:
        return Colors.amber;
      case AdviceLevel.ok:
        return Colors.greenAccent;
    }
  }

  IconData _levelIcon(AdviceLevel level) {
    switch (level) {
      case AdviceLevel.warning:
        return Icons.warning_amber_rounded;
      case AdviceLevel.caution:
        return Icons.info_outline_rounded;
      case AdviceLevel.ok:
        return Icons.check_circle_outline_rounded;
    }
  }
}
