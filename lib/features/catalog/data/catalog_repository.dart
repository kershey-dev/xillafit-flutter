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
      return _withRatings(availableData);
    }

    final fallbackData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .order('created_at', ascending: false);

    return _withRatings(fallbackData as List);
  }

  Future<List<ClothingItemModel>> fetchItemsByCategory(String categoryId) async {
    final availableData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('availability_status', 'available')
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);

    if ((availableData as List).isNotEmpty) {
      return _withRatings(availableData);
    }

    final fallbackData = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);

    return _withRatings(fallbackData as List);
  }

  Future<ClothingItemModel?> fetchItemById(String id) async {
    final data = await _client
        .from('clothing_items')
        .select(_catalogFields)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    final items = await _withRatings([data]);
    return items.isEmpty ? null : items.first;
  }

  Future<List<ClothingItemModel>> _withRatings(List rows) async {
    final itemMaps = rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final ratingMap = await _fetchRatingsByProductIds(
      itemMaps.map((row) => row['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet(),
    );

    return itemMaps.map((row) {
      final id = row['id']?.toString() ?? '';
      final rating = ratingMap[id];
      return ClothingItemModel.fromMap({
        ...row,
        'avg_rating': rating?.avgRating ?? row['avg_rating'],
        'review_count': rating?.reviewCount ?? row['review_count'],
      });
    }).toList(growable: false);
  }

  Future<Map<String, _ProductRatingAggregate>> _fetchRatingsByProductIds(Set<String> ids) async {
    if (ids.isEmpty) return const {};

    try {
      final data = await _client
          .from('feedback')
          .select('rating, orders(order_items(clothing_item_id))');

      final aggregates = <String, _ProductRatingAggregate>{};
      for (final row in (data as List)) {
        final feedback = Map<String, dynamic>.from(row as Map);
        final ratingValue = feedback['rating'];
        final rating = ratingValue is num
            ? ratingValue.toDouble()
            : double.tryParse('${feedback['rating']}');
        if (rating == null) continue;

        final orders = feedback['orders'];
        final orderMap = orders is Map ? Map<String, dynamic>.from(orders) : null;
        final orderItems = orderMap?['order_items'];
        if (orderItems is! List) continue;

        for (final item in orderItems) {
          final orderItem = item is Map ? Map<String, dynamic>.from(item) : const <String, dynamic>{};
          final productId = orderItem['clothing_item_id']?.toString();
          if (productId == null || !ids.contains(productId)) continue;
          final current = aggregates[productId] ?? const _ProductRatingAggregate();
          aggregates[productId] = current.add(rating);
        }
      }
      return aggregates;
    } catch (_) {
      return const {};
    }
  }
}

class _ProductRatingAggregate {
  const _ProductRatingAggregate({
    this.total = 0,
    this.reviewCount = 0,
  });

  final double total;
  final int reviewCount;

  double get avgRating => reviewCount == 0 ? 0 : double.parse((total / reviewCount).toStringAsFixed(1));

  _ProductRatingAggregate add(double rating) {
    return _ProductRatingAggregate(
      total: total + rating,
      reviewCount: reviewCount + 1,
    );
  }
}
