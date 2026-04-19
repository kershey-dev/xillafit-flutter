import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

class CartLineItem {
  const CartLineItem({
    required this.cartId,
    required this.item,
    required this.quantity,
    this.size,
    this.fabric,
    this.customName,
    this.customNumber,
  });

  final String cartId;
  final ClothingItemModel item;
  final int quantity;
  final String? size;
  final String? fabric;
  final String? customName;
  final String? customNumber;

  double get lineTotal => (item.basePrice ?? 0) * quantity;

  CartLineItem copyWith({
    String? cartId,
    ClothingItemModel? item,
    int? quantity,
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) {
    return CartLineItem(
      cartId: cartId ?? this.cartId,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      fabric: fabric ?? this.fabric,
      customName: customName ?? this.customName,
      customNumber: customNumber ?? this.customNumber,
    );
  }

  factory CartLineItem.fromApiMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    final category = map['category']?.toString();
    return CartLineItem(
      cartId: map['cart_id']?.toString() ?? '',
      item: ClothingItemModel(
        id: map['id']?.toString() ?? '',
        categoryId: '',
        name: map['name']?.toString() ?? '',
        previewImageUrl: map['image']?.toString(),
        basePrice:
            rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice'),
        description: category == null || category.isEmpty ? null : category,
      ),
      quantity: map['quantity'] is num
          ? (map['quantity'] as num).toInt()
          : int.tryParse('${map['quantity']}') ?? 1,
      size: map['size']?.toString(),
      fabric: map['fabric']?.toString(),
      customName: map['customName']?.toString() ?? map['custom_name']?.toString(),
      customNumber:
          map['customNumber']?.toString() ?? map['custom_number']?.toString(),
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
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) async {
    final data = await _api.post(
      '/cart/add',
      body: {
        'productId': productId,
        'quantity': quantity,
        if ((size ?? '').trim().isNotEmpty) 'size': size,
        if ((fabric ?? '').trim().isNotEmpty) 'fabric': fabric,
        if ((customName ?? '').trim().isNotEmpty) 'customName': customName,
        if ((customNumber ?? '').trim().isNotEmpty) 'customNumber': customNumber,
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
              if ((line.size ?? '').trim().isNotEmpty) 'size': line.size,
              if ((line.fabric ?? '').trim().isNotEmpty) 'fabric': line.fabric,
              if ((line.customName ?? '').trim().isNotEmpty)
                'customName': line.customName,
              if ((line.customNumber ?? '').trim().isNotEmpty)
                'customNumber': line.customNumber,
            },
        ],
      },
    );
    return _parseList(data);
  }

  Future<List<CartLineItem>> removeItem(String cartId) async {
    final data = await _api.delete('/cart/$cartId');
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
