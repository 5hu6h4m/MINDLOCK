import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Color Palette ───────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF050508);
  static const Color bgDarkSurface = Color(0xFF0A0A0F);
  static const Color bgDarkCard = Color(0xFF14141E);
  static const Color bgDarkElevated = Color(0xFF1E1E2D);

  static const Color primaryPurple = Color(0xFF8A78F0);
  static const Color primaryPurpleLight = Color(0xFFA798FF);
  static const Color accentBlue = Color(0xFF5B9CF0);
  static const Color accentCyan = Color(0xFF69C9D0);
  static const Color accentGreen = Color(0xFF4FC295);
  static const Color accentRed = Color(0xFFFF5263);
  static const Color accentAmber = Color(0xFFFFC53D);
  static const Color accentOrange = Color(0xFFFF6B35);

  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF777777);

  static const Color borderColor = Color(0xFF2A2A35);
  static const Color borderColorLight = Color(0xFF3A3A4A);

  // ─── Gradient Presets ────────────────────────────────────────────────────
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A78F0), Color(0xFF5B9CF0)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FC295), Color(0xFF69C9D0)],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5263), Color(0xFFFF6B35)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC53D), Color(0xFFFF6B35)],
  );

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.dark,
        primary: primaryPurple,
        secondary: accentCyan,
        surface: bgDarkSurface,
        error: accentRed,
      ),
      scaffoldBackgroundColor: bgDark,
      textTheme: _buildTextTheme(textPrimary),
      cardTheme: CardThemeData(
        color: bgDarkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDarkSurface,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textMuted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryPurple;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryPurple.withOpacity(0.3);
          }
          return borderColor;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgDarkElevated,
        selectedColor: primaryPurple.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
        side: const BorderSide(color: borderColor, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 0.5,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: bgDarkElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: textPrimary),
      ),
    );
  }

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.light,
        primary: primaryPurple,
        secondary: accentCyan,
        surface: const Color(0xFFF5F5FF),
        error: accentRed,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F0FA),
      textTheme: _buildTextTheme(const Color(0xFF1A1A2E)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: baseColor,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: baseColor.withOpacity(0.8),
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: baseColor.withOpacity(0.6),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Glassmorphism Helper ────────────────────────────────────────────────────
class GlassDecoration {
  static BoxDecoration build({
    double blur = 20,
    double opacity = 0.08,
    Color? borderColor,
    double borderRadius = 20,
    Gradient? gradient,
    Color? glowColor,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(opacity),
              Colors.white.withOpacity(opacity / 2),
            ],
          ),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.1),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
      ],
    );
  }

  /// Builds a card-style glass decoration with a colored glow effect.
  static BoxDecoration glow({
    required Color color,
    double borderRadius = 20,
    double opacity = 0.08,
  }) {
    return build(
      borderRadius: borderRadius,
      opacity: opacity,
      glowColor: color,
      borderColor: color.withOpacity(0.25),
    );
  }
}
