import 'package:flutter/material.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.goldBright : Colors.transparent,
        foregroundColor: isPrimary ? AppColors.black : AppColors.text2,
        elevation: isPrimary ? 2 : 0,
        side: isPrimary ? null : const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      child: Text(
        text,
        style: AppTextStyles.button.copyWith(
          color: isPrimary ? AppColors.black : AppColors.text2,
        ),
      ),
    );

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
