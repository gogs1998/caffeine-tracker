import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers.dart';
import '../../data/models/caffeine_entry.dart';
import '../../data/models/drink_preset.dart';
import '../../data/repositories/barcode_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final BarcodeRepository _barcodeRepo = BarcodeRepository();
  bool _processing = false;
  bool _paused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _paused) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _processing = true;
      _paused = true;
    });
    await _controller.stop();

    final preset = await _barcodeRepo.lookupBarcode(barcode);

    if (!mounted) return;

    if (preset != null) {
      await _showFoundSheet(preset);
    } else {
      await _showNotFoundSheet();
    }

    setState(() => _processing = false);
  }

  Future<void> _showFoundSheet(DrinkPreset preset) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              preset.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_cafe_outlined,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  preset.mgAmount > 0
                      ? '${preset.mgAmount.toStringAsFixed(0)} mg caffeine'
                      : 'Caffeine not listed',
                  style: const TextStyle(color: Colors.amber, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resumeScanner();
                    },
                    child: const Text('Scan again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _logEntry(preset);
                    },
                    child: const Text('Log it',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotFoundSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Product not recognised',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find caffeine data for this product.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resumeScanner();
                    },
                    child: const Text('Scan again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/log');
                    },
                    child: const Text('Enter manually',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logEntry(DrinkPreset preset) async {
    final entry = CaffeineEntry(
      id: const Uuid().v4(),
      drinkName: preset.name,
      mgAmount: preset.mgAmount,
      consumedAt: DateTime.now(),
      presetId: preset.id,
    );
    await ref.read(caffeineRepositoryProvider).insert(entry);
    ref.invalidate(entriesProvider);
    ref.invalidate(currentLevelProvider);
    if (mounted) context.go('/');
  }

  void _resumeScanner() {
    setState(() => _paused = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan barcode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark vignette + scan zone
          const _ScanOverlay(),

          // Loading indicator
          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),

          // Bottom hint
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point the camera at a barcode',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 240.0;
    final boxLeft = (size.width - boxSize) / 2;
    final boxTop = (size.height - boxSize) / 2;

    return CustomPaint(
      size: size,
      painter: _OverlayPainter(
        scanRect: Rect.fromLTWH(boxLeft, boxTop, boxSize, boxSize),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect scanRect;
  const _OverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(160);

    // Draw four dark rectangles around the scan zone
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, scanRect.top),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, scanRect.bottom, size.width, size.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, scanRect.top, scanRect.left, scanRect.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(scanRect.right, scanRect.top, size.width, scanRect.bottom),
      paint,
    );

    // Rounded white border for scan zone
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );

    // Corner accents
    final cornerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const cl = 20.0; // corner length
    final r = scanRect;
    canvas.drawLine(Offset(r.left, r.top + cl), Offset(r.left, r.top), cornerPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + cl, r.top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(r.right - cl, r.top), Offset(r.right, r.top), cornerPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + cl), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - cl), Offset(r.left, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + cl, r.bottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(r.right - cl, r.bottom), Offset(r.right, r.bottom), cornerPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - cl), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
