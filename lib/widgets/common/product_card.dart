import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/widgets/common/dark_button.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final String subtitle;
  final String? description;
  final String price;
  final String? imageUrl;
  final String? badge;
  final String? modelLabel;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onAddToCart;
  final String primaryActionLabel;

  const ProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.subtitle,
    this.description,
    required this.price,
    this.imageUrl,
    this.badge,
    this.modelLabel,
    this.onTap,
    this.onPrimaryAction,
    this.onAddToCart,
    this.primaryActionLabel = 'Buy Now',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 430.0;
          final imageHeight = (cardHeight * 0.58).clamp(190.0, 250.0);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [
                BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF0EFEA), Color(0xFFE4E2DA)],
                          ),
                        ),
                      ),
                      if (imageUrl != null && imageUrl!.isNotEmpty)
                        Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.06),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.58),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((modelLabel ?? '').isNotEmpty)
                              _badge(
                                text: modelLabel!,
                                background: Colors.black.withValues(alpha: 0.82),
                                foreground: Colors.white,
                              ),
                            if (badge != null) ...[
                              const SizedBox(height: 6),
                              _badge(
                                text: badge!,
                                background: AppColors.goldBright,
                                foreground: AppColors.text,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: DarkButton(
                          text: 'View Product',
                          compact: true,
                          onPressed: onTap,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.goldDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.productName.copyWith(
                            fontSize: 18,
                            letterSpacing: 0.7,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description?.trim().isNotEmpty == true
                              ? description!.trim()
                              : 'Crafted for performance and style. Ready to order.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                price,
                                maxLines: 1,
                                style: AppTextStyles.price.copyWith(
                                  fontSize: 24,
                                  color: AppColors.text,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (onAddToCart != null) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: onAddToCart,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 20,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 118,
                              child: PrimaryButton(
                                text: primaryActionLabel,
                                onPressed: onPrimaryAction ?? onTap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _imageFallback() {
    return Center(
      child: Icon(
        Icons.checkroom_rounded,
        size: 84,
        color: AppColors.muted.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _badge({
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
