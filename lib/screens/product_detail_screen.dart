import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/catalog/presentation/catalog_providers.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/screens/mobile_webview_screen.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';

class ProductDetailArgs {
  final String? itemId;
  final ClothingItemModel? item;

  const ProductDetailArgs({this.itemId, this.item});
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  static const routeName = '/product-detail';

  const ProductDetailScreen({super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedSize = 1;
  bool _expandedDescription = false;

  static const _sizes = ['S', 'M', 'L', 'XL'];

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
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: itemAsync.asData?.value == null && inlineItem == null
          ? null
          : _bottomActionBar((inlineItem ?? itemAsync.asData?.value)!),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load product details.\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.goldDark),
            ),
          ),
        ),
        data: (fetchedItem) {
          final item = inlineItem ?? fetchedItem;
          if (item == null) {
            return Center(
              child: Text(
                'Product not found.',
                style: AppTextStyles.body.copyWith(color: AppColors.goldDark),
              ),
            );
          }

          final sold = _soldCount(item.id);
          final rating = _ratingFor(item.id);
          final safeTop = MediaQuery.paddingOf(context).top;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 360,
                      width: double.infinity,
                      color: Colors.white,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                          child: (item.previewImageUrl ?? '').isNotEmpty
                              ? Image.network(
                                  item.previewImageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.checkroom_rounded,
                                    size: 96,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                )
                              : const Icon(
                                  Icons.checkroom_rounded,
                                  size: 96,
                                  color: Color(0xFFCBD5E1),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: safeTop + 12,
                      left: 18,
                      child: _detailCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      top: safeTop + 12,
                      right: 18,
                      child: _detailCircleButton(
                        icon: Icons.favorite_border_rounded,
                        onTap: () {},
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '1/1',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _modelLabel(item),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.goldDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0EA5E9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 17),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.priceLabel,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if ((item.basePrice ?? 0) > 0)
                            Text(
                              _strikePrice(item.basePrice! * 1.12),
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFF9CA3AF),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '-12%',
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFFE11D48),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$sold+ sold',
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _optionRow(
                        title: 'Size',
                        child: Wrap(
                          spacing: 8,
                          children: List.generate(_sizes.length, (index) {
                            final selected = index == _selectedSize;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? AppColors.gold : Colors.white,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.gold
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _sizes[index],
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: selected ? AppColors.text : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _optionRow(
                        title: 'Quantity',
                        child: Row(
                          children: [
                            _qtyButton(icon: Icons.remove_rounded, onTap: _quantity > 1 ? () => setState(() => _quantity--) : null),
                            Container(
                              width: 48,
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            _qtyButton(icon: Icons.add_rounded, onTap: () => setState(() => _quantity++)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Description',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description?.trim().isNotEmpty == true
                            ? item.description!.trim()
                            : 'Crafted for performance and style with premium Xillafit finishing and ready-for-order presentation.',
                        maxLines: _expandedDescription ? null : 3,
                        overflow: _expandedDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF6B7280),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _expandedDescription = !_expandedDescription),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expandedDescription ? 'Read less' : 'Read more',
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              _expandedDescription
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _openCustomizationWeb,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEAEAEA)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4DE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.brush_outlined, color: AppColors.goldDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Open Web Customizer',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Continue in the full studio for advanced jersey customization.',
                                      style: AppTextStyles.body.copyWith(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, color: Color(0xFF9CA3AF)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _optionRow({required String title, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _bottomActionBar(ClothingItemModel item) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 14 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await ref
                    .read(cartProvider.notifier)
                    .addItem(item, quantity: _quantity);
                if (!context.mounted) return;
                if (!success) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('${item.name} added to cart.')),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text(
                'Add Cart',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(
                context,
                PaymentSubmissionScreen.routeName,
                arguments: PaymentSubmissionArgs.singleItem(
                  item: item,
                  quantity: _quantity,
                  size: _sizes[_selectedSize],
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.text,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Buy Now',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.text, size: 18),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? const Color(0xFFCBD5E1) : AppColors.text),
      ),
    );
  }

  String _modelLabel(ClothingItemModel item) {
    final modelUrl = (item.modelFileUrl ?? '').toLowerCase();
    if (modelUrl.contains('hoodie')) return 'Hoodie';
    if (modelUrl.contains('polo')) return 'Polo';
    if (modelUrl.contains('tank')) return 'Tank Top';
    return 'T-Shirt';
  }

  int _soldCount(String id) {
    final seed = id.codeUnits.fold<int>(0, (sum, value) => sum + value);
    return 10 + (seed % 90);
  }

  double _ratingFor(String id) {
    final seed = id.codeUnits.fold<int>(0, (sum, value) => sum + value);
    return 4.1 + ((seed % 8) / 10);
  }

  String _strikePrice(double value) {
    final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return '₱$text';
  }

  Future<void> _openCustomizationWeb() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final detailArgs = args is ProductDetailArgs ? args : null;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MobileWebViewScreen(
          title: '3D Customizer',
          initialUrl: AppLinks.customizeUrl,
          mode: MobileWebViewMode.customizer,
          productId: detailArgs?.itemId,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      final design = CustomDesignDraft.fromCustomizerResult(result);
      if (design.designId.isNotEmpty) {
        await Navigator.pushNamed(
          context,
          PaymentSubmissionScreen.routeName,
          arguments: PaymentSubmissionArgs.customDesign(design: design),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design synced back to the app.')),
        );
      }
    }
  }
}
