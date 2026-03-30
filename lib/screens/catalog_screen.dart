import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/product_detail_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/filter_chip_pill.dart';
import 'package:xillafit_flutter/widgets/common/product_card.dart';
import 'package:xillafit_flutter/widgets/common/search_bar_widget.dart';

class CatalogScreen extends StatelessWidget {
  static const routeName = '/catalog';
  final bool showScaffold;

  const CatalogScreen({super.key, this.showScaffold = true});

  static const double _gridCardExtent = 288;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 520 ? 3 : 2;

    final products = [
      ('Classic Brand', 'T-Shirt · Cotton · 5 colors', '₱350', 'New'),
      ('Minimal Mono', 'T-Shirt · Cotton · 3 colors', '₱320', null),
      ('Sublimation Jersey', 'Jersey · Polyester', '₱480', null),
      ('Corporate Polo', 'Polo Shirt · Drifit', '₱420', null),
      ('Hoodie Pro', 'Hoodie · Fleece', '₱650', null),
      ('Verde Sports', 'Jersey · Sublimation', '₱450', null),
    ];

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
                  Text('68 items · Showing 1–12', style: AppTextStyles.caption),
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
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                FilterChipPill(text: 'All', active: true),
                SizedBox(width: 7),
                FilterChipPill(text: 'T-Shirts'),
                SizedBox(width: 7),
                FilterChipPill(text: 'Jerseys'),
                SizedBox(width: 7),
                FilterChipPill(text: 'Polo Shirts'),
                SizedBox(width: 7),
                FilterChipPill(text: 'Hoodies'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: products.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              mainAxisExtent: CatalogScreen._gridCardExtent,
            ),
            itemBuilder: (context, index) {
              final item = products[index];
              return ProductCard(
                name: item.$1,
                subtitle: item.$2,
                price: item.$3,
                badge: item.$4,
                onTap: () => Navigator.pushNamed(context, ProductDetailScreen.routeName),
                onCustomize: () => Navigator.pushNamed(context, ProductDetailScreen.routeName),
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
}
