import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/cart/data/cart_repository.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/catalog/presentation/catalog_providers.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/cached_product_image.dart';

final productFabricOptionsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final options = <String>{};
  try {
    final api = ref.watch(backendApiClientProvider);
    final data = await api.get('/inventory');
    final rows = (data as List? ?? const <dynamic>[]);

    for (final row in rows.whereType<Map>()) {
      final materialType = row['material_type']?.toString().trim().toLowerCase();
      final materialName = row['material_name']?.toString().trim();
      if (materialType == 'fabric' && (materialName ?? '').isNotEmpty) {
        options.add(materialName!);
      }
    }
  } catch (_) {
    options.addAll(_fallbackFabricOptions);
  }

  if (options.isEmpty) {
    options.addAll(_fallbackFabricOptions);
  }

  final sorted = options.toList()..sort();
  return sorted;
});

const _fallbackFabricOptions = <String>[
  'Cotton',
  'Dri-Fit',
  'Polyester',
];

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
  String? _selectedSize;
  String? _selectedFabric;
  String _customName = '';
  String _customNumber = '';
  bool _expandedDescription = false;
  bool _isAddingToCart = false;

  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final detailArgs = args is ProductDetailArgs ? args : null;
    final inlineItem = detailArgs?.item;
    final itemId = detailArgs?.itemId ?? inlineItem?.id;
    final fabricsAsync = ref.watch(productFabricOptionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemAsync = itemId == null
        ? const AsyncData<ClothingItemModel?>(null)
        : ref.watch(clothingItemDetailProvider(itemId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: itemAsync.asData?.value == null && inlineItem == null
          ? null
          : _bottomActionBar(
              (inlineItem ?? itemAsync.asData?.value)!,
              fabricsAsync.asData?.value ?? const <String>[],
              categoriesAsync.asData?.value ?? const <CategoryModel>[],
            ),
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
          final rating = item.avgRating;
          final safeTop = MediaQuery.paddingOf(context).top;
          final fabrics = fabricsAsync.asData?.value ?? const <String>[];
          final isLoadingFabrics = fabricsAsync.isLoading && fabrics.isEmpty;
          final categories = categoriesAsync.asData?.value ?? const <CategoryModel>[];
          final isJersey = _isJerseyProduct(item, categories);

          if ((_selectedFabric ?? '').isEmpty && fabrics.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || (_selectedFabric ?? '').isNotEmpty) return;
              setState(() => _selectedFabric = fabrics.first);
            });
          }

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
                              ? CachedProductImage(
                                  imageUrl: item.previewImageUrl,
                                  fit: BoxFit.contain,
                                  fallback: const Icon(
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
                          if ((rating ?? 0) > 0) ...[
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 17),
                            const SizedBox(width: 4),
                            Text(
                              '${rating!.toStringAsFixed(1)} (${item.reviewCount})',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ] else
                            Text(
                              'No reviews',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9CA3AF),
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
                      _selectorHeader(
                        title: 'Select Size',
                        trailing: TextButton(
                          onPressed: () {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Size chart will be available here soon.'),
                              ),
                            );
                          },
                          child: Text(
                            'Size Chart',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A3263),
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _sizes.map((size) {
                          final selected = size == _selectedSize;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSize = size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: size.length >= 3 ? 62 : 52,
                              height: 48,
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF111827) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF111827)
                                      : const Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                boxShadow: selected
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                                child: Text(
                                  size,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      _selectorHeader(title: 'Fabric Type'),
                      if (isLoadingFabrics)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (fabrics.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'No specific fabrics defined in inventory.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: fabrics.map((fabric) {
                            final selected = fabric == _selectedFabric;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFabric = fabric),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: MediaQuery.sizeOf(context).width > 420
                                    ? 176
                                    : (MediaQuery.sizeOf(context).width - 76) / 2,
                                constraints: const BoxConstraints(minHeight: 78),
                                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.gold : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.gold
                                        : const Color(0xFFE5E7EB),
                                    width: 1.6,
                                  ),
                                  boxShadow: selected
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x26F59E0B),
                                            blurRadius: 18,
                                            offset: Offset(0, 8),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fabric.toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PREMIUM CHOICE',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? const Color(0xFF4B5563)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      if (isJersey) ...[
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _textFieldBlock(
                                title: 'Jersey Name',
                                child: TextField(
                                  onChanged: (value) =>
                                      setState(() => _customName = value),
                                  maxLength: 15,
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9 ]'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'JORDAN',
                                    counterText: '${_customName.length}/15',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: AppColors.gold,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _textFieldBlock(
                                title: 'Jersey Number',
                                child: TextField(
                                  onChanged: (value) =>
                                      setState(() => _customNumber = value),
                                  keyboardType: TextInputType.number,
                                  maxLength: 3,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '23',
                                    counterText: '',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(
                                        color: AppColors.gold,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      _optionRow(
                        title: 'Quantity',
                        child: Row(
                          children: [
                            _qtyButton(
                              icon: Icons.remove_rounded,
                              onTap: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
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
                            _qtyButton(
                              icon: Icons.add_rounded,
                              onTap: () => setState(() => _quantity++),
                            ),
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

  Widget _bottomActionBar(
    ClothingItemModel item,
    List<String> fabrics,
    List<CategoryModel> categories,
  ) {
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
              onPressed: _isAddingToCart
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (!_validateSelections(item, fabrics, categories)) return;
                      setState(() => _isAddingToCart = true);
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Adding to cart...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      final success = await ref
                          .read(cartProvider.notifier)
                          .addItem(
                            item,
                            quantity: _quantity,
                            size: _selectedSize,
                            fabric: _selectedFabric,
                            customName: _normalizedCustomName(item, categories),
                            customNumber: _normalizedCustomNumber(item, categories),
                          );
                      if (!context.mounted) return;
                      setState(() => _isAddingToCart = false);
                      messenger.hideCurrentSnackBar();
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: _isAddingToCart
                    ? Row(
                        key: const ValueKey('adding'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Adding...',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Add to Cart',
                        key: const ValueKey('idle'),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (!_validateSelections(item, fabrics, categories)) return;
                Navigator.pushNamed(
                  context,
                  PaymentSubmissionScreen.routeName,
                  arguments: PaymentSubmissionArgs.singleItem(
                    item: item,
                    quantity: _quantity,
                    size: _selectedSize,
                    fabric: _selectedFabric,
                    customName: _normalizedCustomName(item, categories),
                    customNumber: _normalizedCustomNumber(item, categories),
                  ),
                );
              },
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

  Widget _selectorHeader({required String title, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const Spacer(),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _textFieldBlock({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectorHeader(title: title),
        child,
      ],
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

  bool _isJerseyProduct(ClothingItemModel item, List<CategoryModel> categories) {
    final categoryName = _categoryNameFor(item, categories);
    final text = '${item.name} ${item.description ?? ''} $categoryName'.toLowerCase();
    return text.contains('jersey');
  }

  String? _normalizedCustomName(ClothingItemModel item, List<CategoryModel> categories) {
    if (!_isJerseyProduct(item, categories)) return null;
    final value = _customName.trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  String? _normalizedCustomNumber(ClothingItemModel item, List<CategoryModel> categories) {
    if (!_isJerseyProduct(item, categories)) return null;
    final value = _customNumber.trim();
    return value.isEmpty ? null : value;
  }

  bool _validateSelections(
    ClothingItemModel item,
    List<String> fabrics,
    List<CategoryModel> categories,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    if ((_selectedSize ?? '').isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Please choose a size first.')),
      );
      return false;
    }
    if (fabrics.isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('No fabric options are available right now.')),
      );
      return false;
    }
    if ((_selectedFabric ?? '').isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Please choose a fabric first.')),
      );
      return false;
    }
    if (_isJerseyProduct(item, categories) && _normalizedCustomName(item, categories) == null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a jersey name first.')),
      );
      return false;
    }
    if (_isJerseyProduct(item, categories) && _normalizedCustomNumber(item, categories) == null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a jersey number first.')),
      );
      return false;
    }
    return true;
  }

  String _categoryNameFor(ClothingItemModel item, List<CategoryModel> categories) {
    for (final category in categories) {
      if (category.id == item.categoryId) return category.name;
    }
    return '';
  }

  int _soldCount(String id) {
    final seed = id.codeUnits.fold<int>(0, (sum, value) => sum + value);
    return 10 + (seed % 90);
  }

  String _strikePrice(double value) {
    final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return '₱$text';
  }

}
