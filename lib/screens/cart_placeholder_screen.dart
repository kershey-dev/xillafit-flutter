import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/features/checkout/data/checkout_repository.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/cached_product_image.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';
import 'package:xillafit_flutter/widgets/common/quantity_stepper.dart';

class CartPlaceholderArgs {
  const CartPlaceholderArgs({
    this.customDesign,
  });

  final CustomDesignDraft? customDesign;
}

class CartPlaceholderScreen extends ConsumerStatefulWidget {
  static const routeName = '/cart';

  const CartPlaceholderScreen({super.key});

  @override
  ConsumerState<CartPlaceholderScreen> createState() =>
      _CartPlaceholderScreenState();
}

class _CartPlaceholderScreenState extends ConsumerState<CartPlaceholderScreen> {
  Future<void> _refreshCart() async {
    await ref.read(cartProvider.notifier).refreshCart();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final cartState = ref.read(cartProvider);
      if (cartState.items.isEmpty && !cartState.isLoading) {
        return _refreshCart();
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final customDesign =
        routeArgs is CartPlaceholderArgs ? routeArgs.customDesign : null;
    final cartState = ref.watch(cartProvider);
    final lines = cartState.items;
    final subtotal = ref.watch(cartSubtotalProvider);

    ref.listen(cartProvider.select((value) => value.error), (previous, next) {
      if (next != null && next != previous) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next)),
        );
      }
    });

    if (cartState.isLoading && lines.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        appBar: _CartAppBar(),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (lines.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const _CartAppBar(),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshCart,
            color: AppColors.goldDark,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 36,
                  color: AppColors.goldDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text('Your cart is empty', style: AppTextStyles.sectionTitle),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    'Add items from Shop to see them here.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const _CartAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCart,
          color: AppColors.goldDark,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text('CART', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              if (customDesign != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom design ready for checkout',
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF1F7A3D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${customDesign.name} will use the custom-order payment flow when you continue.',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF1F7A3D),
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (cartState.hasPendingSync) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF5D1A7)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 18,
                          color: AppColors.goldDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cart will sync when online.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ...lines.map(
                (line) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _CartPreviewImage(imageUrl: line.item.previewImageUrl),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.item.name,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              line.item.priceLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((line.size ?? '').isNotEmpty ||
                                (line.fabric ?? '').isNotEmpty ||
                                (line.customName ?? '').isNotEmpty ||
                                (line.customNumber ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if ((line.size ?? '').isNotEmpty) 'Size ${line.size}',
                                  if ((line.fabric ?? '').isNotEmpty) line.fabric!,
                                  if ((line.customName ?? '').isNotEmpty)
                                    'Name ${line.customName}',
                                  if ((line.customNumber ?? '').isNotEmpty)
                                    'No. ${line.customNumber}',
                                ].join(' • '),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            QuantityStepper(
                              value: line.quantity,
                              onMinus: () {
                                if (line.quantity <= 1) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .removeItem(line.cartId);
                                  return;
                                }
                                ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(line, line.quantity - 1);
                              },
                              onPlus: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(line, line.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ref.read(cartProvider.notifier).removeItem(line.cartId),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTextStyles.caption),
                        Text(
                          'PHP ${subtotal.toStringAsFixed(0)}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: cartState.isLoading
                          ? 'Updating cart...'
                          : 'Proceed to Checkout',
                      onPressed: cartState.isLoading
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                PaymentSubmissionScreen.routeName,
                                arguments: customDesign == null
                                    ? null
                                    : PaymentSubmissionArgs.customDesign(
                                        design: customDesign,
                                      ),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPreviewImage extends StatelessWidget {
  const _CartPreviewImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return CachedProductImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      fallback: const Icon(Icons.checkroom_rounded),
    );
  }
}

class _CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CartAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.text,
                size: 18,
              ),
            )
          : null,
      title: Text(
        'My Cart',
        style: AppTextStyles.heading.copyWith(
          fontSize: 22,
          color: AppColors.text,
        ),
      ),
    );
  }
}
