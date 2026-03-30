import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/widgets/common/dark_button.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String price;
  final String? badge;
  final VoidCallback? onTap;
  final VoidCallback? onCustomize;

  const ProductCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.price,
    this.badge,
    this.onTap,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: const Color(0x0A000000), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceWarm, AppColors.surface],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: -20,
                      bottom: -8,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x44FFFFFF), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 12,
                      top: 10,
                      child: Icon(Icons.image_outlined, size: 16, color: Color(0x998A8A8A)),
                    ),
                    Center(
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 72,
                        color: AppColors.muted.withValues(alpha: 0.45),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badge!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.text,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.productName.copyWith(
                      fontSize: 15,
                      letterSpacing: 0.7,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    maxLines: 1,
                    style: AppTextStyles.price.copyWith(
                      fontSize: 24,
                      color: AppColors.text,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DarkButton(
                    text: 'Customize',
                    compact: true,
                    onPressed: onCustomize ?? onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
