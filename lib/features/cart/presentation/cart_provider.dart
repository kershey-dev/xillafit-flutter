import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/cart/data/cart_repository.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CartLineItem> items;
  final bool isLoading;
  final String? error;

  CartState copyWith({
    List<CartLineItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
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
      final items = await ref.read(cartRepositoryProvider).fetchCart();
      state = state.copyWith(
        items: items,
        isLoading: false,
        clearError: true,
      );
    });
  }

  Future<bool> addItem(ClothingItemModel item, {int quantity = 1}) async {
    CartLineItem? existing;
    for (final line in state.items) {
      if (line.item.id == item.id) {
        existing = line;
        break;
      }
    }
    final nextQuantity = (existing?.quantity ?? 0) + quantity;

    return _runLoading(() async {
      final items = await ref.read(cartRepositoryProvider).addItem(
            productId: item.id,
            quantity: nextQuantity,
          );
      state = state.copyWith(
        items: items,
        isLoading: false,
        clearError: true,
      );
    });
  }

  Future<bool> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      return removeItem(itemId);
    }

    return _runLoading(() async {
      final items = await ref.read(cartRepositoryProvider).addItem(
            productId: itemId,
            quantity: quantity,
          );
      state = state.copyWith(
        items: items,
        isLoading: false,
        clearError: true,
      );
    });
  }

  Future<bool> removeItem(String itemId) async {
    return _runLoading(() async {
      final items = await ref.read(cartRepositoryProvider).removeItem(itemId);
      state = state.copyWith(
        items: items,
        isLoading: false,
        clearError: true,
      );
    });
  }

  Future<bool> clear() async {
    return _runLoading(() async {
      await ref.read(cartRepositoryProvider).clear();
      state = const CartState();
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
