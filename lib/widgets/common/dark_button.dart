import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

/// Light premium secondary action (gold outline) — not a black fill button.
class DarkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool compact;
  const DarkButton({super.key, required this.text, this.onPressed, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 13,
            horizontal: compact ? 8 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? AppRadius.input : AppRadius.pill),
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: compact ? 10.5 : 12,
          ),
        ),
      ),
    );
  }
}
