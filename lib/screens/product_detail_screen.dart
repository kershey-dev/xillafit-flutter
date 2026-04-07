import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/catalog/presentation/catalog_providers.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/badge.dart';
import 'package:xillafit_flutter/widgets/common/input_field.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';
import 'package:xillafit_flutter/widgets/common/quantity_stepper.dart';

class ProductDetailArgs {
  final String? itemId;
  final ClothingItemModel? item;

  const ProductDetailArgs({this.itemId, this.item});
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  static const routeName = '/product-detail';

  const ProductDetailScreen({super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final detailArgs = args is ProductDetailArgs ? args : null;

    final inlineItem = detailArgs?.item;
    final itemId = detailArgs?.itemId ?? inlineItem?.id;

    final itemAsync = itemId == null
        ? const AsyncData<ClothingItemModel?>(null)
        : ref.watch(clothingItemDetailProvider(itemId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: itemAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load product details.\n$error',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.goldDark),
                  textAlign: TextAlign.center,
                ),
                if (itemId != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(clothingItemDetailProvider(itemId)),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
        data: (fetchedItem) {
          final item = inlineItem ?? fetchedItem;
          if (item == null) {
            return Center(
              child: Text(
                'Product not found.',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.goldDark),
              ),
            );
          }

          final estimatedTotal = (item.basePrice ?? 0) * _quantity;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _stepPill('1 Product', true),
                      _stepPill('2 Details', false),
                      _stepPill('3 Payment', false),
                      _stepPill('4 Done', false),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: (item.previewImageUrl != null &&
                                item.previewImageUrl!.isNotEmpty)
                            ? Image.network(
                                item.previewImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (BuildContext context, Object error,
                                            StackTrace? stackTrace) =>
                                        const Icon(Icons.checkroom, size: 28),
                              )
                            : const Icon(Icons.checkroom, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_availabilityLabel(item)} | ${item.priceLabel}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                const StatusBadge(
                                  text: 'Simple mobile ordering',
                                  type: BadgeType.gold,
                                ),
                                if ((item.description ?? '').isNotEmpty)
                                  const StatusBadge(
                                    text: 'Real product item',
                                    type: BadgeType.blue,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Notes', style: AppTextStyles.heading),
                      const SizedBox(height: 12),
                      InputField(
                        label: 'Notes (optional)',
                        hint:
                            'e.g., preferred size mix, delivery reminders...',
                        maxLines: 3,
                        controller: _notesController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need full customization?',
                        style: AppTextStyles.heading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For 3D design editing and advanced customization, continue on the web configurator.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlineButtonX(
                        text: 'Open Web Customizer',
                        onPressed: _openCustomizationWeb,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Quantity', style: AppTextStyles.heading),
                          const Spacer(),
                          StatusBadge(
                            text: '$_quantity item(s)',
                            type: BadgeType.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          QuantityStepper(
                            value: _quantity,
                            onMinus: _quantity > 1
                                ? () => setState(() => _quantity -= 1)
                                : null,
                            onPlus: () => setState(() => _quantity += 1),
                          ),
                          const Spacer(),
                          Text(
                            _formatAmount(estimatedTotal),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _sum('Base item', item.priceLabel),
                      _sum('Quantity', 'x$_quantity'),
                      _sum('Delivery', 'TBD'),
                      Divider(color: AppColors.border.withValues(alpha: 0.9)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Est. Total',
                            style: AppTextStyles.heading.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            _formatAmount(estimatedTotal),
                            style: AppTextStyles.price.copyWith(
                              color: AppColors.goldDark,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(item, quantity: _quantity);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${item.name} added to cart.'),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.gold,
                                  width: 1.5,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                'Add to Cart',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Buy Now',
                              onPressed: () => Navigator.pushNamed(
                                context,
                                PaymentSubmissionScreen.routeName,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stepPill(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x1AF59E0B) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.gold : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.goldDark : AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sum(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: value == 'TBD' ? AppColors.goldDark : AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _availabilityLabel(ClothingItemModel item) {
    final raw = (item.availabilityStatus ?? 'available').trim();
    if (raw.isEmpty) return 'Available';
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  String _formatAmount(double amount) {
    if (amount <= 0) return 'Price on request';
    return 'PHP ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  Future<void> _openCustomizationWeb() async {
    final uri = Uri.parse(AppLinks.customizeUrl);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open customization website.'),
        ),
      );
    }
  }
}
