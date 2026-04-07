import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

class CartNotifier extends Notifier<List<CartLineItem>> {
  @override
  List<CartLineItem> build() => const [];

  void addItem(ClothingItemModel item, {int quantity = 1}) {
    final index = state.indexWhere((line) => line.item.id == item.id);
    if (index == -1) {
      state = [...state, CartLineItem(item: item, quantity: quantity)];
      return;
    }

    final updated = [...state];
    final line = updated[index];
    updated[index] = line.copyWith(quantity: line.quantity + quantity);
    state = updated;
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = [
      for (final line in state)
        if (line.item.id == itemId)
          line.copyWith(quantity: quantity)
        else
          line,
    ];
  }

  void removeItem(String itemId) {
    state = state.where((line) => line.item.id != itemId).toList();
  }

  void clear() {
    state = const [];
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartLineItem>>(CartNotifier.new);

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold<double>(
        0,
        (sum, line) => sum + line.lineTotal,
      );
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold<int>(
        0,
        (sum, line) => sum + line.quantity,
      );
});
