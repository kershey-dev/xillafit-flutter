import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/catalog/data/catalog_repository.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchCategories();
});

class SelectedCategoryIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedCategoryIdProvider =
    NotifierProvider<SelectedCategoryIdNotifier, String?>(SelectedCategoryIdNotifier.new);

final clothingItemsProvider = FutureProvider<List<ClothingItemModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

  if (selectedCategoryId == null) {
    return repo.fetchActiveItems();
  }
  return repo.fetchItemsByCategory(selectedCategoryId);
});

final clothingItemDetailProvider = FutureProvider.family<ClothingItemModel?, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).fetchItemById(id);
});

