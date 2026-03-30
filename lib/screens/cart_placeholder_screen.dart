import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class CartPlaceholderScreen extends StatelessWidget {
  const CartPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text('Your cart is empty', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text('Add items from Shop to see them here.', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
