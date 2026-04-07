import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/catalog/presentation/catalog_providers.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/screens/product_detail_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/filter_chip_pill.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';
import 'package:xillafit_flutter/widgets/common/product_card.dart';
import 'package:xillafit_flutter/widgets/common/search_bar_widget.dart';

enum _HomeSort { featured, priceLow, priceHigh, name }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _productSectionKey = GlobalKey();
  String? _selectedCategoryId;
  _HomeSort _sort = _HomeSort.featured;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(clothingItemsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 360;
        final isNarrow = width < 420;
        final horizontalPadding = isCompact ? 14.0 : 16.0;
        final bottomPadding = 28.0 + MediaQuery.viewPaddingOf(context).bottom;

        return ColoredBox(
          color: AppColors.surface,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topHeader(isCompact: isCompact),
                const SizedBox(height: 18),
                _hero(
                  isCompact: isCompact,
                  stackButtons: isCompact,
                ),
                const SizedBox(height: 16),
                SearchBarWidget(
                  hint: 'Search products...',
                  controller: _searchController,
                ),
                const SizedBox(height: 18),
                _categoryFilters(categoriesAsync),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: _productSectionKey,
                  child: _productSections(
                    context: context,
                    categoriesAsync: categoriesAsync,
                    itemsAsync: itemsAsync,
                    availableWidth: width - (horizontalPadding * 2),
                    isCompact: isCompact,
                    isNarrow: isNarrow,
                  ),
                ),
                const SizedBox(height: 18),
                _realProductPhotos(itemsAsync),
                const SizedBox(height: 22),
                _customizationCta(compact: isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topHeader({required bool isCompact}) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XILLAFIT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.largeTitle.copyWith(
                  fontSize: isCompact ? 28 : 32,
                  height: 1,
                  letterSpacing: 1.8,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Teamwear ordering made simple',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.goldDark,
                size: 20,
              ),
            ),
            if (cartCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.goldBright,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cartCount',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _hero({
    required bool isCompact,
    required bool stackButtons,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceWarm, Colors.white],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'REAL PRODUCT ORDERING',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'CUSTOM SPORTSWEAR\nPRINTING',
            style: AppTextStyles.largeTitle.copyWith(
              color: AppColors.text,
              fontSize: isCompact ? 38 : 42,
              letterSpacing: 1.1,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Browse products, compare real photos, and place team orders directly from mobile.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (stackButtons) ...[
            PrimaryButton(
              text: 'Browse Products',
              onPressed: _scrollToProducts,
            ),
            const SizedBox(height: 10),
            OutlineButtonX(
              text: 'Start Customizing',
              onPressed: _openCustomizationWeb,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Browse Products',
                    onPressed: _scrollToProducts,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlineButtonX(
                    text: 'Start Customizing',
                    onPressed: _openCustomizationWeb,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _categoryFilters(AsyncValue<List<CategoryModel>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) => Text(
        'Could not load categories.',
        style: AppTextStyles.caption.copyWith(color: AppColors.goldDark),
      ),
      data: (categories) {
        final quickAccess = _pickQuickAccessCategories(categories);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHOP BY CATEGORY',
              style: AppTextStyles.sectionTitle.copyWith(height: 1),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChipPill(
                    text: 'All',
                    active: _selectedCategoryId == null,
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                  ...quickAccess.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChipPill(
                        text: category.name,
                        active: _selectedCategoryId == category.id,
                        onTap: () => setState(() => _selectedCategoryId = category.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _productSections({
    required BuildContext context,
    required AsyncValue<List<CategoryModel>> categoriesAsync,
    required AsyncValue<List<ClothingItemModel>> itemsAsync,
    required double availableWidth,
    required bool isCompact,
    required bool isNarrow,
  }) {
    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stack) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              'Could not load products.\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.goldDark),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(clothingItemsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) {
        final categories = categoriesAsync.asData?.value;
        final visibleItems = _filterAndSortItems(
          items: items,
          categories: categories,
        );

        if (visibleItems.isEmpty) {
          return _emptyProducts();
        }

        final featuredItems = visibleItems.take(4).toList();
        final newArrivals = visibleItems.skip(1).take(3).toList();
        final newArrivalWidth = math.min<double>(
          math.max<double>(availableWidth * (isNarrow ? 0.82 : 0.68), 220),
          280,
        );
        final newArrivalHeight = isCompact ? 380.0 : 410.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.max<double>(availableWidth - 148, 180),
                    maxWidth: availableWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POPULAR RIGHT NOW',
                        style: AppTextStyles.heading.copyWith(
                          letterSpacing: 1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real products from the live company catalog.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                _sortMenu(),
              ],
            ),
            const SizedBox(height: 14),
            ...featuredItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  height: isCompact ? 410 : 430,
                  child: ProductCard(
                    name: item.name,
                    category: _categoryNameFor(item, categories),
                    subtitle: _buildSubtitle(
                      item,
                      _categoryNameFor(item, categories),
                    ),
                    description: item.description,
                    price: item.priceLabel,
                    imageUrl: item.previewImageUrl,
                    modelLabel: _modelLabel(item),
                    badge: item == featuredItems.first ? 'Popular' : null,
                    onTap: () => _openDetail(context, item),
                    primaryActionLabel: 'Buy Now',
                    onPrimaryAction: () => _openDetail(context, item),
                    onAddToCart: () => _addToCart(item),
                  ),
                ),
              ),
            ),
            if (newArrivals.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'NEW ARRIVALS',
                style: AppTextStyles.sectionTitle.copyWith(height: 1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: newArrivalHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: newArrivals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = newArrivals[index];
                    final category = _categoryNameFor(item, categories);
                    return SizedBox(
                      width: newArrivalWidth,
                      child: ProductCard(
                        name: item.name,
                        category: category,
                        subtitle: _buildSubtitle(item, category),
                        description: item.description,
                        price: item.priceLabel,
                        imageUrl: item.previewImageUrl,
                        modelLabel: _modelLabel(item),
                        badge: 'New',
                        onTap: () => _openDetail(context, item),
                        primaryActionLabel: 'Buy Now',
                        onPrimaryAction: () => _openDetail(context, item),
                        onAddToCart: () => _addToCart(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _sortMenu() {
    return PopupMenuButton<_HomeSort>(
      initialValue: _sort,
      onSelected: (value) => setState(() => _sort = value),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _HomeSort.featured,
          child: Text('Featured'),
        ),
        PopupMenuItem(
          value: _HomeSort.priceLow,
          child: Text('Price: Low-High'),
        ),
        PopupMenuItem(
          value: _HomeSort.priceHigh,
          child: Text('Price: High-Low'),
        ),
        PopupMenuItem(
          value: _HomeSort.name,
          child: Text('Name: A-Z'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sortLabel(_sort),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: AppColors.goldDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _realProductPhotos(AsyncValue<List<ClothingItemModel>> itemsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REAL CUSTOMER PRINTS',
          style: AppTextStyles.sectionTitle.copyWith(height: 1),
        ),
        const SizedBox(height: 12),
        itemsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (items) {
            final withImages = items
                .where((item) => (item.previewImageUrl ?? '').isNotEmpty)
                .take(3)
                .toList();
            if (withImages.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: withImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = withImages[index];
                  return GestureDetector(
                    onTap: () => _openDetail(context, item),
                    child: Container(
                      width: 210,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        image: DecorationImage(
                          image: NetworkImage(item.previewImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.06),
                              Colors.black.withValues(alpha: 0.58),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _customizationCta({required bool compact}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.goldBright,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26F59E0B),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESIGN YOUR OWN JERSEY',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.text,
              letterSpacing: 1,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Need the full 3D configurator? Continue on web for advanced customization and design review.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            text: 'Start Customizing',
            onPressed: _openCustomizationWeb,
          ),
        ],
      ),
    );
  }

  Widget _emptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checkroom_rounded,
            size: 44,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: AppTextStyles.heading.copyWith(height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or category filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  List<ClothingItemModel> _filterAndSortItems({
    required List<ClothingItemModel> items,
    required List<CategoryModel>? categories,
  }) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = items.where((item) {
      final categoryName = _categoryNameFor(item, categories);
      final matchesCategory =
          _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          categoryName.toLowerCase().contains(query) ||
          (item.description ?? '').toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _HomeSort.priceLow:
          return (a.basePrice ?? 0).compareTo(b.basePrice ?? 0);
        case _HomeSort.priceHigh:
          return (b.basePrice ?? 0).compareTo(a.basePrice ?? 0);
        case _HomeSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _HomeSort.featured:
          return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      }
    });

    return filtered;
  }

  String _categoryNameFor(
    ClothingItemModel item,
    List<CategoryModel>? categories,
  ) {
    if (categories == null) return 'Shop';
    for (final category in categories) {
      if (category.id == item.categoryId) return category.name;
    }
    return 'Shop';
  }

  String _buildSubtitle(ClothingItemModel item, String categoryName) {
    final statusRaw = (item.availabilityStatus ?? 'available').trim();
    final status = statusRaw.isEmpty
        ? 'Available'
        : statusRaw[0].toUpperCase() + statusRaw.substring(1);
    return '$categoryName | $status';
  }

  String _modelLabel(ClothingItemModel item) {
    final modelUrl = (item.modelFileUrl ?? '').toLowerCase();
    if (modelUrl.contains('hoodie')) return 'Hoodie';
    if (modelUrl.contains('polo')) return 'Polo Shirt';
    if (modelUrl.contains('tank')) return 'Tank Top';
    return 'T-Shirt';
  }

  String _sortLabel(_HomeSort sort) {
    switch (sort) {
      case _HomeSort.featured:
        return 'Featured';
      case _HomeSort.priceLow:
        return 'Low-High';
      case _HomeSort.priceHigh:
        return 'High-Low';
      case _HomeSort.name:
        return 'A-Z';
    }
  }

  List<CategoryModel> _pickQuickAccessCategories(List<CategoryModel> categories) {
    const wanted = ['T-Shirts', 'Jerseys', 'Hoodies', 'Polo Shirts'];
    final picked = <CategoryModel>[];

    for (final label in wanted) {
      for (final category in categories) {
        final name = category.name.toLowerCase();
        final target = label.toLowerCase();
        if (name == target ||
            name.contains(target.replaceAll(' ', '')) ||
            name.contains(target.replaceAll('-', ' ')) ||
            target.contains(name)) {
          if (!picked.any((item) => item.id == category.id)) {
            picked.add(category);
          }
          break;
        }
      }
    }

    if (picked.isEmpty) return categories.take(4).toList();
    return picked;
  }

  void _scrollToProducts() {
    final context = _productSectionKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
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

  void _openDetail(BuildContext context, ClothingItemModel item) {
    Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
      arguments: ProductDetailArgs(itemId: item.id),
    );
  }

  void _addToCart(ClothingItemModel item) {
    ref.read(cartProvider.notifier).addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart.')),
    );
  }
}
