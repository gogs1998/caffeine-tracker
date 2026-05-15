import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CaffeineTrackerApp());
    expect(find.text('Caffeine Tracker'), findsOneWidget);
  });
}
