import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/features/cart/data/cart_repository.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.hasPendingSync = false,
    this.error,
  });

  final List<CartLineItem> items;
  final bool isLoading;
  final bool hasPendingSync;
  final String? error;

  CartState copyWith({
    List<CartLineItem>? items,
    bool? isLoading,
    bool? hasPendingSync,
    String? error,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  bool _bootstrapped = false;

  @override
  CartState build() {
    ref.listen(authSessionProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.user.id;
      final nextSession = next.asData?.value;
      final nextUserId = nextSession?.user.id;

      if (nextUserId == null) {
        state = const CartState();
        return;
      }

      if (previousUserId != nextUserId) {
        Future.microtask(refreshCart);
      }
    });

    final session = ref.read(cartSupabaseClientProvider).auth.currentSession;
    if (!_bootstrapped && session != null) {
      _bootstrapped = true;
      Future.microtask(refreshCart);
    }

    return const CartState();
  }

  Future<void> refreshCart() async {
    await _runLoading(() async {
      final repository = ref.read(cartRepositoryProvider);
      final items = await repository.fetchCart();
      final hasPendingSync = await repository.hasPendingSync();
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasPendingSync: hasPendingSync,
        clearError: true,
      );
    });
  }

  Future<bool> addItem(
    ClothingItemModel item, {
    int quantity = 1,
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) async {
    CartLineItem? existing;
    for (final line in state.items) {
      if (line.item.id == item.id &&
          (line.size ?? '') == (size ?? '') &&
          (line.fabric ?? '') == (fabric ?? '') &&
          (line.customName ?? '') == (customName ?? '') &&
          (line.customNumber ?? '') == (customNumber ?? '')) {
        existing = line;
        break;
      }
    }
    final nextQuantity = (existing?.quantity ?? 0) + quantity;

    return _runLoading(() async {
      final repository = ref.read(cartRepositoryProvider);
      final items = await repository.addItem(
            productId: item.id,
            quantity: nextQuantity,
            productName: item.name,
            productImage: item.previewImageUrl,
            productPrice: item.basePrice,
            productCategory: item.description,
            size: size,
            fabric: fabric,
            customName: customName,
            customNumber: customNumber,
          );
      final hasPendingSync = await repository.hasPendingSync();
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasPendingSync: hasPendingSync,
        clearError: true,
      );
    });
  }

  Future<bool> updateQuantity(CartLineItem line, int quantity) async {
    if (quantity <= 0) {
      return removeItem(line.cartId);
    }

    final previous = state;
    final updatedItems = [
      for (final item in state.items)
        if (item.cartId == line.cartId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
    state = state.copyWith(
      items: updatedItems,
      isLoading: true,
      clearError: true,
    );

    try {
      final repository = ref.read(cartRepositoryProvider);
      final items = await repository.addItem(
        productId: line.item.id,
        quantity: quantity,
        productName: line.item.name,
        productImage: line.item.previewImageUrl,
        productPrice: line.item.basePrice,
        productCategory: line.item.description,
        size: line.size,
        fabric: line.fabric,
        customName: line.customName,
        customNumber: line.customNumber,
      );
      final hasPendingSync = await repository.hasPendingSync();
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasPendingSync: hasPendingSync,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = previous.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> removeItem(String cartId) async {
    final previous = state;
    final updatedItems = [
      for (final item in state.items)
        if (item.cartId != cartId) item,
    ];
    state = state.copyWith(
      items: updatedItems,
      isLoading: true,
      clearError: true,
    );

    try {
      final repository = ref.read(cartRepositoryProvider);
      final items = await repository.removeItem(cartId);
      final hasPendingSync = await repository.hasPendingSync();
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasPendingSync: hasPendingSync,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = previous.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> clear() async {
    return _runLoading(() async {
      final repository = ref.read(cartRepositoryProvider);
      await repository.clear();
      final hasPendingSync = await repository.hasPendingSync();
      state = CartState(hasPendingSync: hasPendingSync);
    });
  }

  Future<bool> _runLoading(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasPendingSync: state.hasPendingSync,
        error: error.toString(),
      );
      return false;
    }
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).items.fold<double>(
        0,
        (sum, line) => sum + line.lineTotal,
      );
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).items.fold<int>(
        0,
        (sum, line) => sum + line.quantity,
      );
});
