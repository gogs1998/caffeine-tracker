import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/main.dart';

void main() {
  testWidgets('App smoke test — wraps in ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CaffeineTrackerApp()));
    // Allow async providers to start loading
    await tester.pump();
    // App should render without throwing
    expect(find.byType(CaffeineTrackerApp), findsOneWidget);
  });
}
