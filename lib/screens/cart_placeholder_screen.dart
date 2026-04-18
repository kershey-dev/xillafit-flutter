import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';
import 'package:xillafit_flutter/widgets/common/quantity_stepper.dart';

class CartPlaceholderScreen extends ConsumerWidget {
  static const routeName = '/cart';

  const CartPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 36,
                    color: AppColors.goldDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Your cart is empty', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Add items from Shop to see them here.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const _CartAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CART', style: AppTextStyles.heading),
              const SizedBox(height: 12),
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
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: (line.item.previewImageUrl ?? '').isNotEmpty
                            ? Image.network(
                                line.item.previewImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.checkroom_rounded),
                              )
                            : const Icon(Icons.checkroom_rounded),
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
