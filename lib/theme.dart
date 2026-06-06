import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
// Light Mode Palette - Vibe: "Artisan Bakery" (Parchment, Thick Cream, Dark Olive)
    static const lightBg = Color(
      0xFFEBE6DD,
    ); // Papel de hornear tostado (Toasted Baking Paper - richer, distinctly warm beige)
    static const lightSurface = Color(
      0xFFF6F3EC,
    ); // Crema pastelera
    static const lightPrimary = Color(
      0xFF6B8738,
    ); // Hojas de olivo
    static const lightSecondary = Color(
      0xFFB54921,
    ); // Horno de ladrillo
    static const lightText = Color(
      0xFF2E2A27,
    ); // Cafe moca

    // Dark Mode Palette
    static const darkBg = Color(
      0xFF141513,
    ); // Trufa negra
    static const darkSurface = Color(
      0xFF222420,
    ); // Madera de olivo oscura (Dark Olive Wood)
    static const darkPrimary = Color(
      0xFF8BA85D,
    ); // Hojas de salvia / Romero (Sage / Rosemary)
    static const darkText = Color(
      0xFFF2EFE9,
    ); // Harina / Crema (Flour / Warm Cream instead of pure white)
    // const darkSecondary = Color(0xFFE2916E); // Terracota suave

    // Typography
    static TextTheme _createTextTheme(TextTheme base, Color textColor) {
      return GoogleFonts.nunitoTextTheme(base).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          textStyle: base.displayLarge,
          color: textColor,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          textStyle: base.displayMedium,
          color: textColor,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          textStyle: base.displaySmall,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          textStyle: base.headlineLarge,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          textStyle: base.headlineMedium,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          textStyle: base.headlineSmall,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          textStyle: base.titleLarge,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.nunito(
          textStyle: base.titleMedium,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.nunito(
          textStyle: base.titleSmall,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.nunito(
          textStyle: base.bodyLarge,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.nunito(
          textStyle: base.bodyMedium,
          color: textColor,
        ),
        bodySmall: GoogleFonts.nunito(
          textStyle: base.bodySmall,
          color: textColor,
        ),
        labelLarge: GoogleFonts.nunito(
          textStyle: base.labelLarge,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    
  static ThemeData get light {
    return ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: lightBg,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: lightPrimary,
                    brightness: Brightness.light,
                    primary: lightPrimary,
                    onPrimary: Colors.white,
                    secondary: lightSecondary,
                    surface: lightSurface,
                    surfaceTint:
                        Colors.transparent, // Disable overlay tint for dialogs
                    surfaceContainerHighest:
                        lightSurface, // Make dialogs and tonals creamy white
                    surfaceContainerHigh: lightSurface,
                    surfaceContainer: lightSurface,
                    surfaceContainerLow: lightBg,
                    surfaceContainerLowest: lightBg,
                    secondaryContainer:
                        lightSurface, // Avoid pale olive buttons
                    onSecondaryContainer: lightText,
                    onSurface: lightText,
                  ),
                  textTheme: _createTextTheme(
                    ThemeData.light().textTheme,
                    lightText,
                  ),
                  appBarTheme: AppBarTheme(
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: lightText.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: lightText.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: lightPrimary, width: 1.5),
                    ),
                  ),
                  cardTheme: CardThemeData(
                    color: lightSurface,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: lightText.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: lightPrimary,
                    foregroundColor: Colors.white,
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: lightBg,
                    indicatorColor: lightPrimary.withValues(alpha: 0.2),
                    iconTheme: WidgetStateProperty.all(
                      IconThemeData(color: Colors.grey[700]),
                    ),
                    labelTextStyle: WidgetStateProperty.all(
                      GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
  }

  static ThemeData get dark {
    return ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: darkBg,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: darkPrimary,
                    brightness: Brightness.dark,
                    primary: darkPrimary,
                    onPrimary: darkText,
                    surface: darkSurface,
                    surfaceTint: Colors.transparent, // Disable overlay tint
                    surfaceContainerHighest:
                        darkSurface, // Force match card color
                    surfaceContainerHigh: darkSurface,
                    surfaceContainer: darkSurface,
                    surfaceContainerLow: darkBg,
                    surfaceContainerLowest: darkBg,
                    secondaryContainer:
                        darkSurface, // Ensures FilledButton.tonal is NOT olive green
                    onSecondaryContainer: darkText,
                    onSurface: darkText,
                  ),
                  textTheme: _createTextTheme(
                    ThemeData.dark().textTheme,
                    darkText,
                  ),
                  appBarTheme: AppBarTheme(
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: darkSurface,
                    hintStyle: TextStyle(
                      color: darkText.withValues(alpha: 0.4),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: darkText.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: darkText.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: darkPrimary, width: 1.5),
                    ),
                  ),
                  cardTheme: CardThemeData(
                    color: darkSurface,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  chipTheme: ChipThemeData(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: darkPrimary.withValues(alpha: 0.3),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: TextStyle(color: Colors.white),
                    secondaryLabelStyle: TextStyle(color: Colors.white),
                  ),
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: darkPrimary,
                    foregroundColor: Color(0xFF1E1E24), // Text on button
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: darkBg,
                    indicatorColor: darkPrimary.withValues(alpha: 0.2),
                    iconTheme: WidgetStateProperty.all(
                      IconThemeData(color: Colors.white70),
                    ),
                    labelTextStyle: WidgetStateProperty.all(
                      GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                );
  }
}
