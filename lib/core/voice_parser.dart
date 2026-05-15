/// ParsedDrink holds the result of parsing a voice transcript.
class ParsedDrink {
  final String name;
  final double mg;
  final double confidence;

  const ParsedDrink({
    required this.name,
    required this.mg,
    required this.confidence,
  });

  @override
  String toString() =>
      'ParsedDrink(name: $name, mg: $mg, confidence: $confidence)';
}

/// VoiceParser converts a natural-language transcript into a [ParsedDrink].
class VoiceParser {
  // ── Keyword map: pattern → (canonicalName, baseMg) ────────────────────────
  // Each entry: regexPattern, canonicalName, baseMg
  static final List<_DrinkRule> _rules = [
    // ── Energy drinks ────────────────────────────────────────────────────────
    _DrinkRule(r'\bred\s*bull\b', 'Red Bull 250ml', 80),
    _DrinkRule(r'\bmonster\b', 'Monster Original 500ml', 160),
    _DrinkRule(r'\brockstar\b', 'Rockstar 500ml', 160),
    _DrinkRule(r'\brelentless\b', 'Relentless 500ml', 160),
    _DrinkRule(r'\bvenom\b', 'Venom Energy 473ml', 160),
    // ── Espresso-based ───────────────────────────────────────────────────────
    _DrinkRule(r'\bmacchiato\b', 'Costa Macchiato', 185),
    _DrinkRule(r'\bflat\s*white\b', 'Costa Flat White', 277),
    _DrinkRule(r'\bcappuccino\b', 'Costa Cappuccino', 185),
    _DrinkRule(r'\blatt[eé]\b', 'Costa Latte', 185),
    _DrinkRule(r'\bespresso\b', 'Espresso', 63),
    _DrinkRule(r'\bamericano\b', 'Americano', 120),
    _DrinkRule(r'\bcortado\b', 'Cortado', 120),
    // ── Brewed coffee ────────────────────────────────────────────────────────
    _DrinkRule(r'\bfilter\s*coffee\b', 'Filter Coffee', 140),
    _DrinkRule(r'\binstant\s*coffee\b', 'Instant Coffee', 100),
    _DrinkRule(r'\bcoffee\b', 'Filter Coffee', 140),
    // ── Teas ─────────────────────────────────────────────────────────────────
    _DrinkRule(r'\bgreen\s*tea\b', 'Green Tea', 35),
    _DrinkRule(r'\bmatcha\b', 'Matcha Latte', 70),
    _DrinkRule(
        r'\b(yorkshire|builder|black|cup of)\s*tea\b', 'Yorkshire Tea', 75),
    _DrinkRule(r'\btea\b', 'Yorkshire Tea', 75),
    // ── Soft drinks ──────────────────────────────────────────────────────────
    _DrinkRule(r'\b(diet\s*)?coke\b', 'Coca-Cola 330ml', 32),
    _DrinkRule(r'\bcoca.?cola\b', 'Coca-Cola 330ml', 32),
    _DrinkRule(r'\bpepsi\b', 'Pepsi 330ml', 32),
    _DrinkRule(r'\bdr\.?\s*pepper\b', 'Dr Pepper 330ml', 41),
    // ── Costa brand catch-all ─────────────────────────────────────────────────
    _DrinkRule(r'\bcosta\b', 'Costa Latte', 185),
  ];

  // ── Size / count adjustments ──────────────────────────────────────────────
  static (String, double) _applySize(
      String baseName, double baseMg, String lower) {
    if (lower.contains('double')) {
      if (baseName.startsWith('Espresso')) return ('Espresso Double', 126);
      return ('$baseName Double', baseMg * 1.5);
    }
    if (lower.contains('single')) {
      return ('$baseName Single', baseMg);
    }
    if (lower.contains('large') || lower.contains('venti')) {
      if (baseName.contains('Latte') ||
          baseName.contains('Cappuccino') ||
          baseName.contains('Flat White') ||
          baseName.contains('Americano')) {
        return ('$baseName Large', baseMg * 1.7);
      }
      return ('$baseName Large', baseMg * 1.4);
    }
    if (lower.contains('grande')) {
      return ('$baseName Grande', baseMg * 1.4);
    }
    if (lower.contains('tall') || lower.contains('small')) {
      return ('$baseName Small', baseMg * 0.75);
    }
    if (lower.contains('medium')) {
      return ('$baseName Medium', baseMg);
    }
    return (baseName, baseMg);
  }

  /// Parse a natural-language [transcript] and return a [ParsedDrink], or
  /// null if confidence < 0.3.
  ParsedDrink? parse(String transcript) {
    if (transcript.trim().isEmpty) return null;
    final lower = transcript.toLowerCase();

    // ── 1. Direct mg mention ──────────────────────────────────────────────────
    final mgRegex =
        RegExp(r'(\d+(?:\.\d+)?)\s*(?:mg|milligrams?)', caseSensitive: false);
    final mgMatch = mgRegex.firstMatch(lower);
    if (mgMatch != null) {
      final mg = double.tryParse(mgMatch.group(1)!);
      if (mg != null && mg > 0 && mg <= 2000) {
        return ParsedDrink(name: 'Custom', mg: mg, confidence: 0.95);
      }
    }

    // ── 2. Keyword match ──────────────────────────────────────────────────────
    for (final rule in _rules) {
      if (rule.regex.hasMatch(lower)) {
        final (name, mg) = _applySize(rule.name, rule.mg, lower);
        return ParsedDrink(
            name: name, mg: mg.roundToDouble(), confidence: 0.85);
      }
    }

    return null; // confidence effectively 0
  }
}

class _DrinkRule {
  final RegExp regex;
  final String name;
  final double mg;

  _DrinkRule(String pattern, this.name, this.mg)
      : regex = RegExp(pattern, caseSensitive: false);
}
