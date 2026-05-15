import 'package:flutter/material.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _freeFeatures = [
    'Basic caffeine logging',
    'Decay graph',
    '200+ drink presets',
  ];

  static const _proFeatures = [
    'Voice logging',
    'Barcode scanner',
    'Heart rate integration',
    'AI-powered advice',
    'GLP-1 mode',
    'Streak tracking',
    'Export data (CSV / JSON)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Hero ────────────────────────────────────────────────────────
            const Text('☕', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'Caffeine Tracker Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smarter caffeine awareness, every day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 28),

            // ── Price card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFFAB40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text(
                    '£2.99 / year',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Less than 1p a day',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Feature comparison ──────────────────────────────────────────
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FeatureColumn(
                    title: 'Free',
                    icon: Icons.lock_open_outlined,
                    iconColor: Colors.white54,
                    features: _freeFeatures,
                    active: false,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _FeatureColumn(
                    title: 'Pro',
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    features: _proFeatures,
                    active: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── CTA ─────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('☕ Purchase flow coming soon'),
                      backgroundColor: Color(0xFF1E1E2E),
                    ),
                  );
                },
                child: const Text('Start Free Trial'),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restore purchases coming soon'),
                    backgroundColor: Color(0xFF1E1E2E),
                  ),
                );
              },
              child: const Text(
                'Restore Purchases',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cancel anytime. No commitment.',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> features;
  final bool active;

  const _FeatureColumn({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.features,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active
            ? Colors.amber.withAlpha(20)
            : const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.amber.withAlpha(80) : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: active ? Colors.amber : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: active
                          ? Colors.greenAccent
                          : Colors.white38,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
