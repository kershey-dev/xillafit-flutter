import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/product_detail_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/filter_chip_pill.dart';
import 'package:xillafit_flutter/widgets/common/product_card.dart';
import 'package:xillafit_flutter/widgets/common/search_bar_widget.dart';
import 'package:xillafit_flutter/widgets/common/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Fixed cell height for [ProductCard] (image uses [Expanded] inside this bound).
  static const double _cardCellHeight = 288;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final newArrivals = List.generate(
      5,
      (i) => ('Essential Tee ${i + 1}', 'Cotton Premium', '₱${350 + (i * 40)}'),
    );
    final popular = List.generate(
      6,
      (i) => ('Minimal Fit ${i + 1}', 'New Season', '₱${390 + (i * 30)}', i == 0 ? 'New' : null),
    );

    return ColoredBox(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + bottomInset),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'XILLAFIT',
                style: AppTextStyles.largeTitle.copyWith(
                  fontSize: 34,
                  letterSpacing: 2.0,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              const Icon(Icons.shopping_bag_outlined, color: AppColors.goldDark),
            ],
          ),
          const SizedBox(height: 10),
          const SearchBarWidget(hint: 'Search products'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 230),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surfaceWarm, Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x18C9902A), blurRadius: 28, spreadRadius: -12, offset: Offset(0, 6)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x33C9902A), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOM SPORTSWEAR\nPRINTING',
                      style: AppTextStyles.largeTitle.copyWith(
                        color: AppColors.text,
                        fontSize: 48,
                        letterSpacing: 1.7,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'From team jerseys to custom uniforms,\nprint-ready quality built for performance.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                FilterChipPill(text: 'All', active: true),
                SizedBox(width: 8),
                FilterChipPill(text: 'T-Shirts'),
                SizedBox(width: 8),
                FilterChipPill(text: 'Jerseys'),
                SizedBox(width: 8),
                FilterChipPill(text: 'Polo Shirts'),
                SizedBox(width: 8),
                FilterChipPill(text: 'Hoodies'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'NEW ARRIVALS',
            actionText: 'View all',
            onActionTap: () {},
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: HomeScreen._cardCellHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newArrivals.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = newArrivals[index];
                return SizedBox(
                  width: 172,
                  height: HomeScreen._cardCellHeight,
                  child: ProductCard(
                    name: item.$1,
                    subtitle: item.$2,
                    price: item.$3,
                    badge: index == 0 ? 'New' : null,
                    onTap: () => Navigator.pushNamed(context, ProductDetailScreen.routeName),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'POPULAR'),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: popular.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: HomeScreen._cardCellHeight,
            ),
            itemBuilder: (context, index) {
              final item = popular[index];
              return ProductCard(
                name: item.$1,
                subtitle: item.$2,
                price: item.$3,
                badge: item.$4,
                onTap: () => Navigator.pushNamed(context, ProductDetailScreen.routeName),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
