import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';

class ProgressBarX extends StatelessWidget {
  final double value;
  const ProgressBarX({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 1);
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped.toDouble(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.gold]),
          ),
        ),
      ),
    );
  }
}
