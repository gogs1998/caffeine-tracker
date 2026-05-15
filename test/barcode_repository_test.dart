import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:caffeine_tracker/data/repositories/barcode_repository.dart';

import 'barcode_repository_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('BarcodeRepository — local map lookup', () {
    late BarcodeRepository repo;

    setUp(() {
      // Use real http.Client; local lookups never hit the network
      repo = BarcodeRepository();
    });

    test('returns Red Bull 250ml for EAN 5449000214911', () async {
      final preset = await repo.lookupBarcode('5449000214911');
      expect(preset, isNotNull);
      expect(preset!.name, contains('Red Bull'));
      expect(preset.mgAmount, equals(80));
      expect(preset.category, equals('energy'));
    });

    test('returns Monster Original 500ml for EAN 5060466513077', () async {
      final preset = await repo.lookupBarcode('5060466513077');
      expect(preset, isNotNull);
      expect(preset!.name, contains('Monster'));
      expect(preset.mgAmount, equals(160));
    });

    test('returns Coca-Cola 330ml for EAN 5000112637938', () async {
      final preset = await repo.lookupBarcode('5000112637938');
      expect(preset, isNotNull);
      expect(preset!.name, contains('Coca-Cola'));
      expect(preset.mgAmount, equals(32));
    });

    test('returns Diet Coke for EAN 5000112637952', () async {
      final preset = await repo.lookupBarcode('5000112637952');
      expect(preset, isNotNull);
      expect(preset!.mgAmount, equals(42));
    });

    test('returns Celsius 200mg for EAN 4056489764588', () async {
      final preset = await repo.lookupBarcode('4056489764588');
      expect(preset, isNotNull);
      expect(preset!.mgAmount, equals(200));
    });

    test('returns Bang Energy 300mg for UPC 852882004222', () async {
      final preset = await repo.lookupBarcode('852882004222');
      expect(preset, isNotNull);
      expect(preset!.mgAmount, equals(300));
    });

    test('preset id is prefixed with barcode_', () async {
      final preset = await repo.lookupBarcode('5449000214911');
      expect(preset!.id, equals('barcode_5449000214911'));
    });
  });

  group('BarcodeRepository — Open Food Facts API fallback', () {
    late MockClient mockClient;
    late BarcodeRepository repo;

    setUp(() {
      mockClient = MockClient();
      repo = BarcodeRepository(client: mockClient);
    });

    test('returns null for unknown barcode when API returns status=0', () async {
      const barcode = '0000000000000';
      when(mockClient.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'status': 0, 'status_verbose': 'product not found'}),
            200,
          ));

      final result = await repo.lookupBarcode(barcode);
      expect(result, isNull);
    });

    test('returns DrinkPreset with caffeine from OFF nutriments', () async {
      const barcode = '1234567890123';
      when(mockClient.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Test Energy Drink',
                'serving_quantity': '250',
                'nutriments': {
                  'caffeine': 0.032, // 0.032 g/100g × 250ml = 80mg
                },
              },
            }),
            200,
          ));

      final result = await repo.lookupBarcode(barcode);
      expect(result, isNotNull);
      expect(result!.name, equals('Test Energy Drink'));
      expect(result.mgAmount, closeTo(80.0, 0.01));
    });

    test('returns preset with 0mg when caffeine not in nutriments', () async {
      const barcode = '9999999999999';
      when(mockClient.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Plain Water',
                'nutriments': {},
              },
            }),
            200,
          ));

      final result = await repo.lookupBarcode(barcode);
      expect(result, isNotNull);
      expect(result!.mgAmount, equals(0));
    });

    test('returns null when API returns 404', () async {
      const barcode = '1111111111111';
      when(mockClient.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      )).thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await repo.lookupBarcode(barcode);
      expect(result, isNull);
    });

    test('returns null when network throws', () async {
      const barcode = '2222222222222';
      when(mockClient.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      )).thenThrow(Exception('Network error'));

      final result = await repo.lookupBarcode(barcode);
      expect(result, isNull);
    });
  });
}
