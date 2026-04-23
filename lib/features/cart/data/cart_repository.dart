import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/core/storage/local_database.dart';
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
    final rawPrice = map['price'] ?? map['product_price'];
    final category = map['category']?.toString();
    return CartLineItem(
      cartId: map['cart_id']?.toString() ??
          map['server_cart_id']?.toString() ??
          ((map['local_id'] != null) ? 'local:${map['local_id']}' : ''),
      item: ClothingItemModel(
        id: map['id']?.toString() ?? map['product_id']?.toString() ?? '',
        categoryId: '',
        name: map['name']?.toString() ?? map['product_name']?.toString() ?? '',
        previewImageUrl: map['image']?.toString() ?? map['product_image']?.toString(),
        basePrice:
            rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice'),
        description: category == null || category.isEmpty
            ? map['product_category']?.toString()
            : category,
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
  CartRepository({
    required BackendApiClient api,
    required SupabaseClient supabase,
    required LocalDatabase localDatabase,
  })  : _api = api,
        _supabase = supabase,
        _localDatabase = localDatabase;

  final BackendApiClient _api;
  final SupabaseClient _supabase;
  final LocalDatabase _localDatabase;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<List<CartLineItem>> fetchCart() async {
    final userId = _requireUserId();
    final dirty = await _localDatabase.isCartDirty(userId);
    if (dirty) {
      try {
        return await _reconcileLocalCart(userId);
      } catch (_) {
        return _loadLocalCart(userId);
      }
    }

    try {
      final data = await _api.get('/cart');
      final rows = (data as List? ?? const <dynamic>[])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
      await _replaceLocalCart(userId, rows, dirty: false);
      return rows.map(CartLineItem.fromApiMap).toList(growable: false);
    } catch (_) {
      return _loadLocalCart(userId);
    }
  }

  Future<List<CartLineItem>> addItem({
    required String productId,
    required int quantity,
    String? productName,
    String? productImage,
    double? productPrice,
    String? productCategory,
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) async {
    final userId = _requireUserId();
    final existing = await _findMatchingLocalItem(
      userId,
      productId: productId,
      size: size,
      fabric: fabric,
      customName: customName,
      customNumber: customNumber,
    );

    final row = {
      'server_cart_id': existing?['server_cart_id']?.toString(),
      'product_id': productId,
      'product_name': productName ?? existing?['product_name']?.toString() ?? 'Product',
      'product_image': productImage ?? existing?['product_image']?.toString(),
      'product_price': productPrice ?? existing?['product_price'],
      'product_category': productCategory ?? existing?['product_category']?.toString(),
      'quantity': quantity,
      'size': size,
      'fabric': fabric,
      'custom_name': customName,
      'custom_number': customNumber,
    };
    await _localDatabase.upsertCartItem(
      userId,
      row,
      existingLocalId: existing == null ? null : 'local:${existing['local_id']}',
    );

    try {
      return await _reconcileLocalCart(userId);
    } catch (_) {
      return _loadLocalCart(userId);
    }
  }

  Future<List<CartLineItem>> syncCart(List<CartLineItem> items) async {
    final userId = _requireUserId();
    await _replaceLocalCart(
      userId,
      items.map(_toLocalCartMapFromLine).toList(growable: false),
      dirty: true,
    );

    try {
      return await _reconcileLocalCart(userId);
    } catch (_) {
      return _loadLocalCart(userId);
    }
  }

  Future<List<CartLineItem>> removeItem(String cartId) async {
    final userId = _requireUserId();
    await _localDatabase.deleteCartItem(userId, cartId);
    if (!cartId.startsWith('local:')) {
      try {
        await _api.delete('/cart/$cartId');
        final freshData = await _api.get('/cart');
        final rows = (freshData as List? ?? const <dynamic>[])
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        await _replaceLocalCart(userId, rows, dirty: false);
        return rows.map(CartLineItem.fromApiMap).toList(growable: false);
      } catch (_) {
        // Fall back to the broader reconciliation path below.
      }
    }
    try {
      return await _reconcileLocalCart(userId);
    } catch (_) {
      return _loadLocalCart(userId);
    }
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    await _localDatabase.clearCart(userId, dirty: true);
    try {
      await _reconcileLocalCart(userId);
    } catch (_) {
      // Keep local cart cleared and marked dirty for a later retry.
    }
  }

  Future<bool> hasPendingSync() async {
    final userId = _requireUserId();
    return _localDatabase.isCartDirty(userId);
  }

  Future<List<CartLineItem>> _loadLocalCart(String userId) async {
    final rows = await _localDatabase.loadCartItems(userId);
    return rows.map(CartLineItem.fromApiMap).toList(growable: false);
  }

  Future<List<CartLineItem>> _reconcileLocalCart(String userId) async {
    final localItems = await _loadLocalCart(userId);
    final serverData = await _api.get('/cart');
    final serverRows = (serverData as List? ?? const <dynamic>[])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final desiredByKey = <String, CartLineItem>{};
    for (final line in localItems) {
      desiredByKey[_cartLineKey(line)] = line;
    }

    if (desiredByKey.isEmpty) {
      if (serverRows.isNotEmpty) {
        await _api.delete('/cart');
      }
    } else {
      for (final row in serverRows) {
        final key = _cartRowKey(row);
        if (!desiredByKey.containsKey(key)) {
          final cartId = row['cart_id']?.toString();
          if (cartId != null && cartId.isNotEmpty) {
            await _api.delete('/cart/$cartId');
          }
        }
      }

      for (final line in desiredByKey.values) {
        await _api.post(
          '/cart/add',
          body: {
            'productId': line.item.id,
            'quantity': line.quantity,
            'unitPrice': line.item.basePrice,
            if ((line.size ?? '').trim().isNotEmpty) 'size': line.size,
            if ((line.fabric ?? '').trim().isNotEmpty) 'fabric': line.fabric,
            if ((line.customName ?? '').trim().isNotEmpty)
              'customName': line.customName,
            if ((line.customNumber ?? '').trim().isNotEmpty)
              'customNumber': line.customNumber,
          },
        );
      }
    }

    final freshData = await _api.get('/cart');
    final rows = (freshData as List? ?? const <dynamic>[])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    await _replaceLocalCart(userId, rows, dirty: false);
    return rows.map(CartLineItem.fromApiMap).toList(growable: false);
  }

  Future<void> _replaceLocalCart(
    String userId,
    List<Map<String, dynamic>> rows, {
    required bool dirty,
  }) async {
    await _localDatabase.replaceCartItems(
      userId,
      rows.map(_toLocalCartMap).toList(growable: false),
      dirty: dirty,
    );
  }

  Map<String, dynamic> _toLocalCartMap(Map<String, dynamic> row) {
    final rawPrice = row['price'] ?? row['product_price'];
    final category = row['category']?.toString() ?? row['product_category']?.toString();
    return {
      'server_cart_id': row['cart_id']?.toString() ?? row['server_cart_id']?.toString(),
      'product_id': row['id']?.toString() ?? row['product_id']?.toString() ?? '',
      'product_name': row['name']?.toString() ?? row['product_name']?.toString() ?? '',
      'product_image': row['image']?.toString() ?? row['product_image']?.toString(),
      'product_price': rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice'),
      'product_category': category,
      'quantity': row['quantity'] is num
          ? (row['quantity'] as num).toInt()
          : int.tryParse('${row['quantity']}') ?? 1,
      'size': row['size']?.toString(),
      'fabric': row['fabric']?.toString(),
      'custom_name': row['customName']?.toString() ?? row['custom_name']?.toString(),
      'custom_number':
          row['customNumber']?.toString() ?? row['custom_number']?.toString(),
    };
  }

  Map<String, dynamic> _toLocalCartMapFromLine(CartLineItem line) {
    return {
      'server_cart_id': line.cartId.startsWith('local:') ? null : line.cartId,
      'product_id': line.item.id,
      'product_name': line.item.name,
      'product_image': line.item.previewImageUrl,
      'product_price': line.item.basePrice,
      'product_category': line.item.description,
      'quantity': line.quantity,
      'size': line.size,
      'fabric': line.fabric,
      'custom_name': line.customName,
      'custom_number': line.customNumber,
    };
  }

  Future<Map<String, dynamic>?> _findMatchingLocalItem(
    String userId, {
    required String productId,
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) async {
    final rows = await _localDatabase.loadCartItems(userId);
    for (final row in rows) {
      if (row['product_id']?.toString() == productId &&
          (row['size']?.toString() ?? '') == (size ?? '') &&
          (row['fabric']?.toString() ?? '') == (fabric ?? '') &&
          (row['custom_name']?.toString() ?? '') == (customName ?? '') &&
          (row['custom_number']?.toString() ?? '') == (customNumber ?? '')) {
        return row;
      }
    }
    return null;
  }

  String _cartLineKey(CartLineItem line) {
    return _cartKey(
      productId: line.item.id,
      size: line.size,
      fabric: line.fabric,
      customName: line.customName,
      customNumber: line.customNumber,
    );
  }

  String _cartRowKey(Map<String, dynamic> row) {
    return _cartKey(
      productId: row['id']?.toString() ?? row['product_id']?.toString(),
      size: row['size']?.toString(),
      fabric: row['fabric']?.toString(),
      customName: row['customName']?.toString() ?? row['custom_name']?.toString(),
      customNumber:
          row['customNumber']?.toString() ?? row['custom_number']?.toString(),
    );
  }

  String _cartKey({
    required String? productId,
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) {
    String normalize(String? value) => (value ?? '').trim();
    return [
      normalize(productId),
      normalize(size),
      normalize(fabric),
      normalize(customName),
      normalize(customNumber),
    ].join('||');
  }

  String _requireUserId() {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const BackendApiException('You need to sign in again.');
    }
    return userId;
  }
}

final cartSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  return BackendApiClient(supabase: ref.watch(cartSupabaseClientProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(
    api: ref.watch(backendApiClientProvider),
    supabase: ref.watch(cartSupabaseClientProvider),
    localDatabase: LocalDatabase.instance,
  );
});
