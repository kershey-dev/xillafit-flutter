import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xillafit_flutter/app_colors.dart';

class AppTextStyles {
  static TextStyle largeTitle = GoogleFonts.bebasNeue(
    fontSize: 26,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.2,
    color: AppColors.text,
  );

  static TextStyle sectionTitle = GoogleFonts.bebasNeue(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
    color: AppColors.text,
  );

  static TextStyle productTitle = GoogleFonts.bebasNeue(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.6,
    color: AppColors.text,
  );

  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.35,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: AppColors.muted,
    height: 1.35,
  );

  // Compatibility aliases for existing files.
  static TextStyle title = largeTitle;
  static TextStyle heading = sectionTitle;
  static TextStyle productName = productTitle;
  static TextStyle price = GoogleFonts.bebasNeue(
    fontSize: 24,
    letterSpacing: 0.5,
    color: AppColors.text,
  );
  static TextStyle muted = caption;
  static TextStyle label = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.muted,
  );
  static TextStyle button = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.black,
  );
}
