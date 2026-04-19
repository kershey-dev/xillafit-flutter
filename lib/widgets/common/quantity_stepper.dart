import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool enabled;

  const QuantityStepper({
    super.key,
    required this.value,
    this.onMinus,
    this.onPlus,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _qBtn('-', enabled ? onMinus : null, left: true),
        Container(
          width: 40,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '$value',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        _qBtn('+', enabled ? onPlus : null, right: true),
      ],
    );
  }

  Widget _qBtn(
    String text,
    VoidCallback? onTap, {
    bool left = false,
    bool right = false,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(left ? AppRadius.small : 0),
            bottomLeft: Radius.circular(left ? AppRadius.small : 0),
            topRight: Radius.circular(right ? AppRadius.small : 0),
            bottomRight: Radius.circular(right ? AppRadius.small : 0),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: isEnabled ? AppColors.text : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
