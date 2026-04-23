import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/core/storage/local_database.dart';
import 'package:xillafit_flutter/features/catalog/data/catalog_repository.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

final catalogSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(
    api: BackendApiClient(supabase: ref.watch(catalogSupabaseClientProvider)),
    localDatabase: LocalDatabase.instance,
  );
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchCategories();
});

final clothingItemsProvider = FutureProvider<List<ClothingItemModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.fetchActiveItems();
});

final clothingItemDetailProvider = FutureProvider.family<ClothingItemModel?, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).fetchItemById(id);
});
