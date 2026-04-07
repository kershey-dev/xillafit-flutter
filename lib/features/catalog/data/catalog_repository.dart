import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

class CatalogRepository {
  CatalogRepository({required SupabaseClient client}) : _client = client;
  final SupabaseClient _client;
  static const _catalogFields =
      'id,category_id,clothing_name,description,preview_image_url,model_file_url,availability_status,created_at,price';

  Future<List<CategoryModel>> fetchCategories() async {
    final data = await _client
        .from('clothing_categories')
        .select('id,category_name,description,created_at')
        .order('category_name');

    return (data as List)
        .map((row) => CategoryModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<ClothingItemModel>> fetchActiveItems() async {
    final availableData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('availability_status', 'available')
        .order('created_at', ascending: false);

    if ((availableData as List).isNotEmpty) {
      return availableData
          .map((row) => ClothingItemModel.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    }

    final fallbackData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .order('created_at', ascending: false);

    return (fallbackData as List)
        .map((row) => ClothingItemModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<ClothingItemModel>> fetchItemsByCategory(String categoryId) async {
    final availableData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('availability_status', 'available')
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);

    if ((availableData as List).isNotEmpty) {
      return availableData
          .map((row) => ClothingItemModel.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    }

    final fallbackData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);

    return (fallbackData as List)
        .map((row) => ClothingItemModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<ClothingItemModel?> fetchItemById(String id) async {
    final data = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return ClothingItemModel.fromMap(Map<String, dynamic>.from(data as Map));
  }
}
