import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class FilterChipPill extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback? onTap;

  const FilterChipPill({
    super.key,
    required this.text,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF7EC) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.gold : AppColors.border,
            width: active ? 1.8 : 1.5,
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.goldDark : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
