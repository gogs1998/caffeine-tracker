# Caffeine Tracker ☕

A premium Flutter caffeine tracking app with real-time decay modelling, HealthKit integration, barcode scanner, AI advice, GLP-1 mode, and streak gamification.

## Features

- **Real-time decay graph** — C(t) = C₀ × 0.5^(t/5), 5hr half-life
- **224 UK-focused drink presets** with category picker
- **Voice logging** — "large oat flat white" → 130mg
- **Barcode scanner** — Open Food Facts API lookup
- **Heart rate integration** — HealthKit / Health Connect
- **AI advice engine** — rule-based + Gemini chat fallback
- **GLP-1 mode** — Mounjaro 1.5×, Ozempic 1.4× multipliers
- **Streak gamification** — daily logging streaks
- **Pro paywall** — £2.99/yr via in-app purchase
- **CSV/JSON export**

## Tech Stack

Flutter · SQLite · Firebase · HealthKit · ARKit · fl_chart · Riverpod · go_router

## Live Demo

[caffeine-tracker.pages.dev](https://caffeine-tracker.pages.dev)

## Development

```bash
flutter pub get
flutter run
flutter test        # 86 tests
flutter analyze
```

## License

MIT
