import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';

export 'package:xillafit_flutter/app_colors.dart';
export 'package:xillafit_flutter/app_text_styles.dart';

class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
}

BoxDecoration cardDecoration = BoxDecoration(
  color: AppColors.cardBackground,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: AppColors.border),
);
