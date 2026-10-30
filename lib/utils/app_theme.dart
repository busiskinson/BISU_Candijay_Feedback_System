import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF2D0047); // Primary Deep Purple
  static const Color primaryLight = Color(0xFF4B176B); // Primary Purple
  static const Color secondary = Color(0xFF5A2380); // Secondary Purple
  static const Color accent = Color(0xFFFFA800); // Gold
  static const Color accentDark = Color(0xFFE09600);

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFFAFBFE);
  static const Color border = Color(0xFFE6EAF2);
  static const Color borderStrong = Color(0xFFD7DDEA);
  static const Color ink = Color(0xFF101828);
  static const Color teal = Color(0xFF0E9384);
  static const Color info = Color(0xFF2563EB);

  static const Color textPrimary = Color(0xFF171426);
  static const Color textSecondary = Color(0xFF6F6A78);

  static const Color success = Color(0xFF2E8B45);
  static const Color warning = Color(0xFFEF6C00);
  static const Color danger = Color(0xFFD93636);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // Kept for backward compatibility with existing files
  static const Color primaryDark = primary;
}

/// Standard corner radii used across the app.
class AppRadius {
  static const double card = 8;
  static const double button = 8;
  static const double icon = 8;
}

class AppTextStyles {
  static TextStyle get heading => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get welcomeTitle => GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get subheading => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get sectionTitle => GoogleFonts.inter(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get button =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Aliases kept for backward compatibility with app_widgets.dart
  static TextStyle get sectionHeading => heading;
  static TextStyle get bodySecondary => subheading;
  static TextStyle get cardTitle => sectionTitle;
}

class AppDecorations {
  static BoxDecoration card({double radius = AppRadius.card}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.03),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static InputDecoration input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      textStyle: AppTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }

  static ButtonStyle accentButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.primary,
      elevation: 0,
      textStyle: AppTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }

  static ButtonStyle secondaryButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1.4),
      textStyle: AppTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }

  static BoxDecoration adminPanel({double radius = AppRadius.card}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration softField() {
    return BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.button),
      border: Border.all(color: AppColors.border),
    );
  }

  static WidgetStateProperty<Color?> tableHeadingColor() {
    return WidgetStateProperty.all(AppColors.surfaceAlt);
  }
}
