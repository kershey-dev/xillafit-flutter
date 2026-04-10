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

enum _HomeSort { newest, priceLow, priceHigh, name }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  _HomeSort _sort = _HomeSort.newest;

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
    final itemsAsync = ref.watch(clothingItemsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load products.\n$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.goldDark),
              ),
            ),
          ),
          data: (items) {
            final categories = categoriesAsync.asData?.value ?? const <CategoryModel>[];
            final visibleItems = _filterAndSortItems(items, categories);
            final heroItem = visibleItems.isNotEmpty ? visibleItems.first : null;
            final flashItems = visibleItems.take(4).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 24 + safeBottom),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _topHeader(),
                      const SizedBox(height: 18),
                      _searchRow(),
                      const SizedBox(height: 16),
                      if (heroItem != null) _promoBanner(heroItem),
                      if (heroItem != null) const SizedBox(height: 20),
                      _sectionTitle('Popular Category'),
                      const SizedBox(height: 12),
                      _categoryScroller(categories),
                      const SizedBox(height: 20),
                      _flashHeader(),
                      const SizedBox(height: 12),
                      _flashGrid(flashItems, categories),
                      const SizedBox(height: 22),
                      _customizeCard(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topHeader() {
    final cartCount = ref.watch(cartItemCountProvider);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/xilla-logo.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Xilla',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldDark,
                  ),
                ),
                TextSpan(
                  text: 'fit',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        _circleButton(icon: Icons.search_rounded, onTap: () {}),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _circleButton(icon: Icons.shopping_bag_outlined, onTap: () => _openCartTab()),
            if (cartCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$cartCount',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _searchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search products',
                hintStyle: AppTextStyles.body.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<_HomeSort>(
          initialValue: _sort,
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: _HomeSort.newest, child: Text('Newest')),
            PopupMenuItem(value: _HomeSort.priceLow, child: Text('Price low-high')),
            PopupMenuItem(value: _HomeSort.priceHigh, child: Text('Price high-low')),
            PopupMenuItem(value: _HomeSort.name, child: Text('Name A-Z')),
          ],
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _promoBanner(ClothingItemModel item) {
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        height: 178,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/xillfit-auth-bg.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0.9, 0),
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.96),
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.28, 0.52, 0.9],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              bottom: 16,
              child: SizedBox(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Don't miss out",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.text,
                        fontSize: 22,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Browse our latest drop and order directly from the app.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.text.withValues(alpha: 0.76),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.32,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Shop now',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.body.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }

  Widget _categoryScroller(List<CategoryModel> categories) {
    final quick = _pickQuickAccessCategories(categories);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quick.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _categoryBubble(
              label: 'All',
              active: _selectedCategoryId == null,
              icon: Icons.grid_view_rounded,
              onTap: () => setState(() => _selectedCategoryId = null),
            );
          }
          final category = quick[index - 1];
          return _categoryBubble(
            label: category.name,
            active: _selectedCategoryId == category.id,
            icon: _categoryIcon(category.name),
            onTap: () => setState(() => _selectedCategoryId = category.id),
          );
        },
      ),
    );
  }

  Widget _categoryBubble({
    required String label,
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFF2D6) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.gold : const Color(0xFFEAEAEA),
                ),
              ),
              child: Icon(
                icon,
                color: active ? AppColors.goldDark : const Color(0xFF60636B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flashHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Flash Sale',
            style: AppTextStyles.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        Text(
          'Ends at',
          style: AppTextStyles.body.copyWith(
            color: const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE7E2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '11:12:02',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFE94F37),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _flashGrid(List<ClothingItemModel> items, List<CategoryModel> categories) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Text(
          'No products available yet.',
          style: AppTextStyles.body.copyWith(color: const Color(0xFF6B7280)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final rating = _ratingFor(item.id);
        return GestureDetector(
          onTap: () => _openDetail(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: (item.previewImageUrl ?? '').isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  item.previewImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.checkroom_rounded,
                                    size: 42,
                                    color: Color(0xFFB6BCC5),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.checkroom_rounded,
                                size: 42,
                                color: Color(0xFFB6BCC5),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.priceLabel,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _categoryNameFor(item, categories),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _customizeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26F59E0B),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need full customization?',
            style: AppTextStyles.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open the web studio for full 3D customization, design review, and advanced team ordering.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.text.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openCustomizationWeb,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Start customizing',
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

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: AppColors.text, size: 22),
      ),
    );
  }

  List<ClothingItemModel> _filterAndSortItems(
    List<ClothingItemModel> items,
    List<CategoryModel> categories,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = items.where((item) {
      final categoryName = _categoryNameFor(item, categories).toLowerCase();
      final matchesCategory =
          _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          categoryName.contains(query) ||
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
        case _HomeSort.newest:
          return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      }
    });

    return filtered;
  }

  List<CategoryModel> _pickQuickAccessCategories(List<CategoryModel> categories) {
    if (categories.isEmpty) return const [];
    return categories.take(6).toList();
  }

  String _categoryNameFor(ClothingItemModel item, List<CategoryModel> categories) {
    for (final category in categories) {
      if (category.id == item.categoryId) return category.name;
    }
    return 'Collection';
  }

  String _modelLabel(ClothingItemModel item) {
    final modelUrl = (item.modelFileUrl ?? '').toLowerCase();
    if (modelUrl.contains('hoodie')) return 'Hoodie';
    if (modelUrl.contains('polo')) return 'Polo';
    if (modelUrl.contains('tank')) return 'Tank';
    return 'Shirt';
  }

  IconData _categoryIcon(String name) {
    final text = name.toLowerCase();
    if (text.contains('hood')) return Icons.dry_cleaning_outlined;
    if (text.contains('polo')) return Icons.person_outline_rounded;
    if (text.contains('jersey')) return Icons.sports_football_rounded;
    if (text.contains('shirt')) return Icons.checkroom_rounded;
    return Icons.style_rounded;
  }

  double _ratingFor(String id) {
    final value = id.codeUnits.fold<int>(0, (sum, item) => sum + item);
    return 4.1 + ((value % 8) / 10);
  }

  void _openDetail(ClothingItemModel item) {
    Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
      arguments: ProductDetailArgs(itemId: item.id, item: item),
    );
  }

  void _openCartTab() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use the Cart tab below to review your items.')),
    );
  }

  Future<void> _openCustomizationWeb() async {
    final uri = Uri.parse(AppLinks.customizeUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open customization website.')),
      );
    }
  }
}
