import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  const SearchBarWidget({super.key, this.hint = 'Search', this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }
}
