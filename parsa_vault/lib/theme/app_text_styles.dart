import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Playfair Display — headlines & titles ──────────────────────────────────
  static TextStyle displayHeadline = GoogleFonts.playfairDisplay(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.nearBlack,
    height: 1.2,
  );

  static TextStyle screenTitle = GoogleFonts.playfairDisplay(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.nearBlack,
    height: 1.25,
  );

  static TextStyle sectionHeading = GoogleFonts.playfairDisplay(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.3,
  );

  static TextStyle cardTitle = GoogleFonts.playfairDisplay(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.3,
  );

  // ── Inter — everything functional ─────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.nearBlack,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.nearBlack,
    height: 1.5,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.nearBlack,
    height: 1.4,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGrey,
    height: 1.4,
    letterSpacing: 0.3,
  );

  static TextStyle captionBold = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mediumGrey,
    height: 1.4,
  );

  static TextStyle priceLarge = GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.nearBlack,
    height: 1.2,
  );

  static TextStyle priceMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.nearBlack,
    height: 1.2,
  );

  static TextStyle priceSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.nearBlack,
    height: 1.2,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.0,
  );

  static TextStyle tabLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGrey,
    height: 1.0,
  );

  static TextStyle tagline = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGrey,
    letterSpacing: 1.2,
    height: 1.6,
  );

  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.nearBlack,
    height: 1.4,
  );

  static TextStyle inputPlaceholder = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF9E9E9E),
    height: 1.4,
  );

  static TextStyle errorText = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.dangerRed,
    height: 1.4,
  );

  static TextStyle greetingText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.nearBlack,
    height: 1.4,
  );

  static TextStyle xpText = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGrey,
    height: 1.0,
  );

  static TextStyle levelText = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.nearBlack,
    height: 1.0,
  );

  static TextStyle badgeText = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.0,
  );

  static TextStyle percentageUp = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.successGreen,
    height: 1.0,
  );

  static TextStyle percentageDown = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.dangerRed,
    height: 1.0,
  );
}
