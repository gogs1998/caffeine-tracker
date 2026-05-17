import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/drink_db_preset.dart';
import '../../data/repositories/drink_search_repository.dart';

final drinkSearchRepositoryProvider = Provider<DrinkSearchRepository>(
  (ref) => DrinkSearchRepository(),
);

final drinkSearchQueryProvider = StateProvider<String>((ref) => '');

final drinkSearchResultsProvider =
    FutureProvider<List<DrinkDbPreset>>((ref) async {
  final repo = ref.watch(drinkSearchRepositoryProvider);
  final query = ref.watch(drinkSearchQueryProvider);
  return repo.search(query);
});
