import 'package:flutter/material.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/custom_button.dart';

class ProductCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String subtitle;
  final String price;
  final String? badge;
  final VoidCallback onCustomize;

  const ProductCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.price,
    this.badge,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 132,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
              gradient: const LinearGradient(
                colors: [Color(0xFFEEE9E0), Color(0xFFE5DFD4)],
              ),
            ),
            child: Stack(
              children: [
                const Center(child: Text('👕', style: TextStyle(fontSize: 44))),
                if (badge != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.productName),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.muted),
                const SizedBox(height: 8),
                Text(price, style: AppTextStyles.price),
                const SizedBox(height: 8),
                CustomButton(text: 'Customize', onPressed: onCustomize),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
