import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/catalog/presentation/catalog_providers.dart';
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

class ProductDetailScreen extends ConsumerWidget {
  static const routeName = '/product-detail';

  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load product details.\n$error',
              style: AppTextStyles.caption.copyWith(color: AppColors.goldDark),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (fetchedItem) {
          final item = inlineItem ?? fetchedItem;
          if (item == null) {
            return Center(
              child: Text(
                'Product not found.',
                style: AppTextStyles.caption.copyWith(color: AppColors.goldDark),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text('1', style: AppTextStyles.caption.copyWith(color: AppColors.text, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Text('Design Review', style: AppTextStyles.caption.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w700)),
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                      Text('2 Details', style: AppTextStyles.caption),
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                      Text('3 Payment', style: AppTextStyles.caption),
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                      Text('4 Done', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: (item.previewImageUrl != null && item.previewImageUrl!.isNotEmpty)
                            ? Image.network(
                                item.previewImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                                    const Icon(Icons.checkroom, size: 28),
                              )
                            : const Icon(Icons.checkroom, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              '${item.availabilityStatus ?? 'available'} · ${item.priceLabel}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                StatusBadge(text: 'Category item', type: BadgeType.gold),
                                if ((item.description ?? '').isNotEmpty) const StatusBadge(text: 'Has description', type: BadgeType.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text('✏ Edit', style: AppTextStyles.body.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Garment Options', style: AppTextStyles.heading),
                  SizedBox(height: 12),
                  InputField(label: 'Fabric / Material', hint: 'Cotton 100%'),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StaticPill('Front', true),
                      _StaticPill('Back', false),
                      _StaticPill('Left Sleeve', false),
                      _StaticPill('Right Sleeve', false),
                    ],
                  ),
                  SizedBox(height: 12),
                  InputField(label: 'Design / Production Notes (optional)', hint: 'e.g., exact Pantone colors...', maxLines: 3),
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
                      Text('Size & Quantity', style: AppTextStyles.heading),
                      const Spacer(),
                      const StatusBadge(text: '0 pcs · min 6', type: BadgeType.gold),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    ('XS', 0, '—'),
                    ('S', 0, '—'),
                    ('M', 3, '₱1,050'),
                    ('L', 3, '₱1,050'),
                  ].map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text(row.$1, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 8),
                          QuantityStepper(value: row.$2),
                          const Spacer(),
                          Text(row.$3, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: row.$3 == '—' ? AppColors.muted : AppColors.text)),
                        ],
                      ),
                    ),
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
                  BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  _sum('Base item', item.priceLabel),
                  _sum('Design fee', '₱500'),
                  _sum('Delivery', 'TBD'),
                  Divider(color: AppColors.border.withValues(alpha: 0.9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Est. Total', style: AppTextStyles.heading.copyWith(color: AppColors.muted)),
                      Text(item.priceLabel, style: AppTextStyles.price.copyWith(color: AppColors.goldDark, fontSize: 26)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'Continue to Order Details →',
                    onPressed: () => Navigator.pushNamed(context, PaymentSubmissionScreen.routeName),
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
}

class _StaticPill extends StatelessWidget {
  final String text;
  final bool active;
  const _StaticPill(this.text, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.gold : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.gold : AppColors.border, width: 1.5),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(fontSize: 12, color: active ? AppColors.text : AppColors.muted, fontWeight: FontWeight.w600)),
    );
  }
}
