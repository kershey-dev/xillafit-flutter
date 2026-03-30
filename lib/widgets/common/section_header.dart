import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const Spacer(),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText!,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
