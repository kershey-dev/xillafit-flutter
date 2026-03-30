import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const QuantityStepper({
    super.key,
    required this.value,
    this.onMinus,
    this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _qBtn('−', onMinus, left: true),
        Container(
          width: 40,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          child: Text('$value', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        _qBtn('+', onPlus, right: true),
      ],
    );
  }

  Widget _qBtn(String text, VoidCallback? onTap, {bool left = false, bool right = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(left ? AppRadius.small : 0),
            bottomLeft: Radius.circular(left ? AppRadius.small : 0),
            topRight: Radius.circular(right ? AppRadius.small : 0),
            bottomRight: Radius.circular(right ? AppRadius.small : 0),
          ),
        ),
        child: Text(text, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
