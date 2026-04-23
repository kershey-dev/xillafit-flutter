import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/core/storage/local_database.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

class CatalogRepository {
  CatalogRepository({
    required BackendApiClient api,
    required LocalDatabase localDatabase,
  })  : _api = api,
        _localDatabase = localDatabase;
  final BackendApiClient _api;
  final LocalDatabase _localDatabase;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final data = await _api.get('/products/categories');
      final rows = (data as List? ?? const <dynamic>[])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
      await _localDatabase.replaceCatalogCategories(rows);
      return rows.map(CategoryModel.fromMap).toList(growable: false);
    } catch (error) {
      final cachedRows = await _localDatabase.loadCatalogCategories();
      if (cachedRows.isEmpty) rethrow;
      return cachedRows.map(CategoryModel.fromMap).toList(growable: false);
    }
  }

  Future<List<ClothingItemModel>> fetchActiveItems() async {
    try {
      final rows = await _fetchAndCacheAllItems();
      final available = rows.where((row) {
        final status =
            row['availability_status']?.toString().trim().toLowerCase() ?? '';
        return status.isEmpty || status == 'available';
      }).toList(growable: false);
      return available.isNotEmpty
          ? available.map(ClothingItemModel.fromMap).toList(growable: false)
          : rows.map(ClothingItemModel.fromMap).toList(growable: false);
    } catch (error) {
      final cachedRows = await _localDatabase.loadCatalogItems();
      if (cachedRows.isEmpty) rethrow;
      final available = cachedRows.where((row) {
        final status =
            row['availability_status']?.toString().trim().toLowerCase() ?? '';
        return status.isEmpty || status == 'available';
      }).toList(growable: false);
      final source = available.isNotEmpty ? available : cachedRows;
      return source.map(ClothingItemModel.fromMap).toList(growable: false);
    }
  }

  Future<List<ClothingItemModel>> fetchItemsByCategory(String categoryId) async {
    final allItems = await fetchActiveItems();
    final filtered = allItems.where((item) => item.categoryId == categoryId).toList();
    if (filtered.isNotEmpty) return filtered;

    try {
      final cachedRows = await _localDatabase.loadCatalogItems();
      return cachedRows
          .where((row) => row['category_id']?.toString() == categoryId)
          .map(ClothingItemModel.fromMap)
          .toList(growable: false);
    } catch (error) {
      return const [];
    }
  }

  Future<ClothingItemModel?> fetchItemById(String id) async {
    try {
      final rows = await _fetchAndCacheAllItems();
      for (final row in rows) {
        if (row['id']?.toString() == id) {
          return ClothingItemModel.fromMap(row);
        }
      }
    } catch (_) {
      // Fall back to local cache below.
    }

    final cached = await _localDatabase.loadCatalogItemById(id);
    if (cached == null) return null;
    return ClothingItemModel.fromMap(cached);
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheAllItems() async {
    final data = await _api.get('/products');
    final itemMaps = (data as List? ?? const <dynamic>[])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    await _localDatabase.replaceCatalogItems(itemMaps);
    return itemMaps;
  }
}
