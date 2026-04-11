import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

class CartLineItem {
  const CartLineItem({
    required this.item,
    required this.quantity,
  });

  final ClothingItemModel item;
  final int quantity;

  double get lineTotal => (item.basePrice ?? 0) * quantity;

  CartLineItem copyWith({
    ClothingItemModel? item,
    int? quantity,
  }) {
    return CartLineItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartLineItem.fromApiMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    final category = map['category']?.toString();
    return CartLineItem(
      item: ClothingItemModel(
        id: map['id']?.toString() ?? '',
        categoryId: '',
        name: map['name']?.toString() ?? '',
        previewImageUrl: map['image']?.toString(),
        basePrice: rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice'),
        description: category == null || category.isEmpty ? null : category,
      ),
      quantity: map['quantity'] is num
          ? (map['quantity'] as num).toInt()
          : int.tryParse('${map['quantity']}') ?? 1,
    );
  }
}

class CartRepository {
  CartRepository({required BackendApiClient api}) : _api = api;

  final BackendApiClient _api;

  Future<List<CartLineItem>> fetchCart() async {
    final data = await _api.get('/cart');
    final rows = (data as List? ?? const <dynamic>[]);
    return rows
        .map((row) => CartLineItem.fromApiMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<CartLineItem>> addItem({
    required String productId,
    required int quantity,
  }) async {
    final data = await _api.post(
      '/cart/add',
      body: {
        'productId': productId,
        'quantity': quantity,
      },
    );
    return _parseList(data);
  }

  Future<List<CartLineItem>> syncCart(List<CartLineItem> items) async {
    final data = await _api.post(
      '/cart/sync',
      body: {
        'items': [
          for (final line in items)
            {
              'id': line.item.id,
              'quantity': line.quantity,
            },
        ],
      },
    );
    return _parseList(data);
  }

  Future<List<CartLineItem>> removeItem(String productId) async {
    final data = await _api.delete('/cart/$productId');
    return _parseList(data);
  }

  Future<void> clear() async {
    await _api.delete('/cart');
  }

  List<CartLineItem> _parseList(dynamic data) {
    final rows = (data as List? ?? const <dynamic>[]);
    return rows
        .map((row) => CartLineItem.fromApiMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}

final cartSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  return BackendApiClient(supabase: ref.watch(cartSupabaseClientProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(api: ref.watch(backendApiClientProvider));
});
