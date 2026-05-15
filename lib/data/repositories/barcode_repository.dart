import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drink_preset.dart';

/// Maps well-known EAN/UPC barcodes → [DrinkPreset].
const _localMap = <String, _BarcodeEntry>{
  // Energy drinks
  '5449000214911': _BarcodeEntry('Red Bull 250ml', 80, 'energy'),
  '5060466513077': _BarcodeEntry('Monster Original 500ml', 160, 'energy'),
  '4056489764588': _BarcodeEntry('Celsius 355ml', 200, 'energy'),
  '852882004222': _BarcodeEntry('Bang Energy 500ml', 300, 'energy'),
  '5060517882049': _BarcodeEntry('Rockstar Energy 500ml', 160, 'energy'),
  '5000168010063': _BarcodeEntry('Lucozade Energy 380ml', 46, 'energy'),
  '5000168010087': _BarcodeEntry('Lucozade Sport 500ml', 0, 'energy'),
  '5010477334765': _BarcodeEntry('Relentless Origin 500ml', 160, 'energy'),
  '5010477320751': _BarcodeEntry('Relentless Passion 500ml', 160, 'energy'),
  '5060466513176': _BarcodeEntry('Monster Ultra White 500ml', 150, 'energy'),
  '5060466513183': _BarcodeEntry('Monster Ultra Blue 500ml', 150, 'energy'),
  '5000112637914': _BarcodeEntry('Red Bull Sugarfree 250ml', 80, 'energy'),
  // Cola
  '5000112637938': _BarcodeEntry('Coca-Cola 330ml', 32, 'cola'),
  '5000112637952': _BarcodeEntry('Diet Coke 330ml', 42, 'cola'),
  '5000112637945': _BarcodeEntry('Coca-Cola Zero 330ml', 32, 'cola'),
  '4002846044879': _BarcodeEntry('Pepsi Max 330ml', 43, 'cola'),
  '5000112637921': _BarcodeEntry('Pepsi Regular 330ml', 38, 'cola'),
  '5000112117479': _BarcodeEntry('Dr Pepper 330ml', 41, 'cola'),
  // Coffee RTD
  '4006058104094': _BarcodeEntry('Nescafe Classic 180ml', 75, 'coffee'),
  '5000118958462': _BarcodeEntry('Starbucks Frappuccino Mocha 250ml', 90, 'coffee'),
  '5000118958479': _BarcodeEntry('Starbucks Doubleshot Espresso 200ml', 125, 'coffee'),
  '4006058104117': _BarcodeEntry('Starbucks Cold Brew 250ml', 130, 'coffee'),
  '5000118958486': _BarcodeEntry('Costa Coffee Latte 250ml', 100, 'coffee'),
  // Tea
  '5000113098022': _BarcodeEntry('Lipton Iced Tea Peach 500ml', 18, 'tea'),
  '5000128527897': _BarcodeEntry('Honest Tea Black Tea 330ml', 25, 'tea'),
  // Sports / other
  '0012000161155': _BarcodeEntry('Gatorade Bolt 24 600ml', 75, 'other'),
  '0012000012145': _BarcodeEntry('Mountain Dew 355ml', 54, 'cola'),
  '0049000028928': _BarcodeEntry('Sprite 355ml', 0, 'cola'),
  '0012000010097': _BarcodeEntry('Mello Yello 355ml', 51, 'cola'),
  '0012000050244': _BarcodeEntry('Vault Energy Drink 355ml', 47, 'cola'),
};

class _BarcodeEntry {
  final String name;
  final double mg;
  final String category;
  const _BarcodeEntry(this.name, this.mg, this.category);
}

class BarcodeRepository {
  final http.Client _client;

  BarcodeRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Returns a [DrinkPreset] for the given [barcode], or null if not found.
  Future<DrinkPreset?> lookupBarcode(String barcode) async {
    // 1. Local lookup
    final local = _localMap[barcode];
    if (local != null) {
      return DrinkPreset(
        id: 'barcode_$barcode',
        name: local.name,
        mgAmount: local.mg,
        category: local.category,
      );
    }

    // 2. Open Food Facts API fallback
    try {
      final uri = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'];
      if (status == null || status == 0) return null; // product not found

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final productName =
          (product['product_name'] as String?)?.trim() ?? 'Unknown product';

      double mgAmount = 0;
      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments != null) {
        // OFF stores caffeine per 100 g/ml — multiply by serving size if available
        final caffeinePerHundred =
            _toDouble(nutriments['caffeine']) ?? _toDouble(nutriments['caffeine_100g']);
        if (caffeinePerHundred != null) {
          final serving = _toDouble(product['serving_quantity']) ?? 100.0;
          // OFF value is in g/100g; convert to mg
          mgAmount = caffeinePerHundred * (serving / 100.0) * 1000;
        }
      }

      return DrinkPreset(
        id: 'barcode_$barcode',
        name: productName,
        mgAmount: mgAmount,
        category: _inferCategory(productName),
      );
    } catch (_) {
      return null;
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('coffee') || lower.contains('espresso') || lower.contains('latte')) {
      return 'coffee';
    }
    if (lower.contains('tea')) return 'tea';
    if (lower.contains('energy') ||
        lower.contains('monster') ||
        lower.contains('red bull') ||
        lower.contains('bang') ||
        lower.contains('celsius') ||
        lower.contains('rockstar')) {
      return 'energy';
    }
    if (lower.contains('cola') ||
        lower.contains('pepsi') ||
        lower.contains('coke') ||
        lower.contains('dr pepper')) {
      return 'cola';
    }
    return 'other';
  }
}
