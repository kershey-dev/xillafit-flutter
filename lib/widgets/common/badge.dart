import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

enum BadgeType { gold, green, blue, gray }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  const StatusBadge({super.key, required this.text, this.type = BadgeType.gray});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (type) {
      case BadgeType.gold:
        bg = const Color(0x1AC9902A);
        fg = AppColors.goldDark;
        break;
      case BadgeType.green:
        bg = const Color(0xFFEDFAF3);
        fg = AppColors.success;
        break;
      case BadgeType.blue:
        bg = const Color(0xFFEBF2FF);
        fg = AppColors.blueBadge;
        break;
      case BadgeType.gray:
        bg = AppColors.border;
        fg = AppColors.muted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
