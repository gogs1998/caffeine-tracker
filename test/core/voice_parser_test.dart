import 'package:flutter_test/flutter_test.dart';
import 'package:caffeine_tracker/core/voice_parser.dart';

void main() {
  final parser = VoiceParser();

  group('VoiceParser', () {
    test('large Costa latte', () {
      final r = parser.parse('I just had a large Costa latte');
      expect(r, isNotNull);
      expect(r!.name, contains('Latte'));
      expect(r.name.toLowerCase(), contains('large'));
      expect(r.mg, closeTo(320, 30));
      expect(r.confidence, greaterThanOrEqualTo(0.3));
    });

    test('double espresso', () {
      final r = parser.parse('double espresso');
      expect(r, isNotNull);
      expect(r!.name, 'Espresso Double');
      expect(r.mg, closeTo(126, 15));
    });

    test('red bull', () {
      final r = parser.parse('red bull');
      expect(r, isNotNull);
      expect(r!.name, 'Red Bull 250ml');
      expect(r.mg, closeTo(80, 10));
    });

    test('can of coke', () {
      final r = parser.parse('can of coke');
      expect(r, isNotNull);
      expect(r!.name, contains('Coca-Cola'));
      expect(r.mg, closeTo(32, 10));
    });

    test('200mg of caffeine', () {
      final r = parser.parse('200mg of caffeine');
      expect(r, isNotNull);
      expect(r!.mg, closeTo(200, 1));
      expect(r.name, 'Custom');
    });

    test('cup of tea', () {
      final r = parser.parse('cup of tea');
      expect(r, isNotNull);
      expect(r!.name, contains('Tea'));
      expect(r.mg, closeTo(75, 20));
    });

    test('green tea', () {
      final r = parser.parse('green tea');
      expect(r, isNotNull);
      expect(r!.name, 'Green Tea');
      expect(r.mg, closeTo(35, 10));
    });

    test('flat white', () {
      final r = parser.parse('flat white');
      expect(r, isNotNull);
      expect(r!.name, contains('Flat White'));
      expect(r.mg, closeTo(277, 30));
    });

    test('monster', () {
      final r = parser.parse('monster');
      expect(r, isNotNull);
      expect(r!.name, contains('Monster'));
      expect(r.mg, closeTo(160, 20));
    });

    test('I had 150 milligrams', () {
      final r = parser.parse('I had 150 milligrams');
      expect(r, isNotNull);
      expect(r!.mg, closeTo(150, 1));
      expect(r.name, 'Custom');
    });

    test('empty transcript returns null', () {
      expect(parser.parse(''), isNull);
    });

    test('unrecognised transcript returns null', () {
      expect(parser.parse('xyzzy frobnicator'), isNull);
    });
  });
}
