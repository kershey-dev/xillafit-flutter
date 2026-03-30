import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/catalog/data/category_model.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/catalog/presentation/catalog_providers.dart';
import 'package:xillafit_flutter/screens/product_detail_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/filter_chip_pill.dart';
import 'package:xillafit_flutter/widgets/common/product_card.dart';
import 'package:xillafit_flutter/widgets/common/search_bar_widget.dart';

class CatalogScreen extends ConsumerWidget {
  static const routeName = '/catalog';
  final bool showScaffold;

  const CatalogScreen({super.key, this.showScaffold = true});

  static const double _gridCardExtent = 288;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 520 ? 3 : 2;

    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = ref.watch(clothingItemsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COLLECTION', style: AppTextStyles.title.copyWith(fontSize: 22, letterSpacing: 1.2)),
                  Text(
                    itemsAsync.maybeWhen(
                      data: (items) => '${items.length} items',
                      orElse: () => 'Loading items...',
                    ),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('⊞ Grid', style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SearchBarWidget(hint: 'Search collection...'),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: categoriesAsync.when(
              loading: () => const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
              error: (error, stack) => Align(
                alignment: Alignment.centerLeft,
                child: Text('Failed to load categories', style: AppTextStyles.caption.copyWith(color: AppColors.goldDark)),
              ),
              data: (categories) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChipPill(
                      text: 'All',
                      active: selectedCategoryId == null,
                      onTap: () => ref.read(selectedCategoryIdProvider.notifier).select(null),
                    );
                  }
                  final category = categories[index - 1];
                  return FilterChipPill(
                    text: category.name,
                    active: selectedCategoryId == category.id,
                    onTap: () => ref.read(selectedCategoryIdProvider.notifier).select(category.id),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Could not load products.\n$error',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.goldDark),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No products available for this category yet.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                );
              }
              return GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  mainAxisExtent: CatalogScreen._gridCardExtent,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ProductCard(
                    name: item.name,
                    subtitle: _buildSubtitle(item, categoriesAsync.asData?.value),
                    price: item.priceLabel,
                    imageUrl: item.previewImageUrl,
                    badge: index == 0 ? 'New' : null,
                    onTap: () => Navigator.pushNamed(
                      context,
                      ProductDetailScreen.routeName,
                      arguments: ProductDetailArgs(itemId: item.id),
                    ),
                    onCustomize: () => Navigator.pushNamed(
                      context,
                      ProductDetailScreen.routeName,
                      arguments: ProductDetailArgs(itemId: item.id),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    if (!showScaffold) return content;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: content,
    );
  }

  String _buildSubtitle(ClothingItemModel item, List<CategoryModel>? categories) {
    String? categoryName;
    if (categories != null) {
      for (final category in categories) {
        if (category.id == item.categoryId) {
          categoryName = category.name;
          break;
        }
      }
    }
    final statusRaw = (item.availabilityStatus ?? 'available').trim();
    final status = statusRaw.isEmpty
        ? 'Available'
        : statusRaw[0].toUpperCase() + statusRaw.substring(1);
    if (categoryName != null && categoryName.isNotEmpty) {
      return '$categoryName · $status';
    }
    return status;
  }
}
