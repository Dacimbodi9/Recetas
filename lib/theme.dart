import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recetas/models/models.dart';

class AppTheme {

  // ── Default Theme Presets ──

  static const _oliva = AppThemePreset(
    id: 'oliva',
    name: 'Oliva',
    primaryColor: Color(0xFF6B8738),
    secondaryColor: Color(0xFFB54921),
    isDefault: true,
  );

  static const _cereza = AppThemePreset(
    id: 'cereza',
    name: 'Cereza',
    primaryColor: Color(0xFFA32B45),
    secondaryColor: Color(0xFF7A2033),
    isDefault: true,
  );

  static const _oceano = AppThemePreset(
    id: 'oceano',
    name: 'Océano',
    primaryColor: Color(0xFF215473),
    secondaryColor: Color(0xFF448FA3),
    isDefault: true,
  );

  static const _lavanda = AppThemePreset(
    id: 'lavanda',
    name: 'Lavanda',
    primaryColor: Color(0xFF75558C),
    secondaryColor: Color(0xFF927A9E),
    isDefault: true,
  );

  static const _miel = AppThemePreset(
    id: 'miel',
    name: 'Miel',
    primaryColor: Color(0xFFD18E34),
    secondaryColor: Color(0xFFA36622),
    isDefault: true,
  );

  static const _carbon = AppThemePreset(
    id: 'carbon',
    name: 'Carbón',
    primaryColor: Color(0xFF455A64),
    secondaryColor: Color(0xFF37474F),
    isDefault: true,
  );

  static const List<AppThemePreset> defaultPresets = [
    _oliva,
    _cereza,
    _oceano,
    _lavanda,
    _miel,
    _carbon,
  ];

  static AppThemePreset get defaultPreset => _oliva;

  // ── Original Oliva hand-tuned overrides ──
  // These preserve the exact colors the designer picked for the default theme.
  // Other presets use auto-derived colors from AppThemePreset getters.

  static const _olivaLightBg = Color(0xFFEBE6DD);
  static const _olivaLightSurface = Color(0xFFF6F3EC);
  static const _olivaLightText = Color(0xFF2E2A27);
  static const _olivaDarkBg = Color(0xFF141513);
  static const _olivaDarkSurface = Color(0xFF222420);
  static const _olivaDarkPrimary = Color(0xFF8BA85D);
  static const _olivaDarkText = Color(0xFFF2EFE9);

  // ── Typography (unchanged) ──

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

  // ── Theme Builders ──

  /// For the Oliva preset, use hand-tuned colors. For all others, auto-derive.
  static Color _bg(AppThemePreset p, bool dark) =>
      dark ? (p.id == 'oliva' ? _olivaDarkBg : p.darkBg)
           : (p.id == 'oliva' ? _olivaLightBg : p.lightBg);

  static Color _surface(AppThemePreset p, bool dark) =>
      dark ? (p.id == 'oliva' ? _olivaDarkSurface : p.darkSurface)
           : (p.id == 'oliva' ? _olivaLightSurface : p.lightSurface);

  static Color _primary(AppThemePreset p, bool dark) =>
      dark ? (p.id == 'oliva' ? _olivaDarkPrimary : p.darkPrimary)
           : p.lightPrimary;

  static Color _text(AppThemePreset p, bool dark) =>
      dark ? (p.id == 'oliva' ? _olivaDarkText : p.darkText)
           : (p.id == 'oliva' ? _olivaLightText : p.lightText);

  static ThemeData light([AppThemePreset? preset]) {
    final p = preset ?? _oliva;
    final bg = _bg(p, false);
    final surface = _surface(p, false);
    final primary = _primary(p, false);
    final secondary = p.lightSecondary;
    final text = _text(p, false);

    return ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: bg,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: primary,
                    brightness: Brightness.light,
                    primary: primary,
                    onPrimary: Colors.white,
                    secondary: secondary,
                    surface: surface,
                    surfaceTint:
                        Colors.transparent, // Disable overlay tint for dialogs
                    surfaceContainerHighest:
                        surface, // Make dialogs and tonals creamy white
                    surfaceContainerHigh: surface,
                    surfaceContainer: surface,
                    surfaceContainerLow: bg,
                    surfaceContainerLowest: bg,
                    secondaryContainer:
                        surface, // Avoid pale olive buttons
                    onSecondaryContainer: text,
                    onSurface: text,
                  ),
                  textTheme: _createTextTheme(
                    ThemeData.light().textTheme,
                    text,
                  ),
                  appBarTheme: AppBarTheme(
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: text.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: text.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                  cardTheme: CardThemeData(
                    color: surface,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: text.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: bg,
                    indicatorColor: primary.withValues(alpha: 0.2),
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
                  checkboxTheme: CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: WidgetStateBorderSide.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return BorderSide(color: primary, width: 2);
                      }
                      return const BorderSide(color: Colors.grey, width: 2);
                    }),
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return primary;
                      }
                      return Colors.transparent;
                    }),
                    checkColor: WidgetStateProperty.all(Colors.white),
                  ),
                );
  }

  static ThemeData dark([AppThemePreset? preset]) {
    final p = preset ?? _oliva;
    final bg = _bg(p, true);
    final surface = _surface(p, true);
    final primary = _primary(p, true);
    final text = _text(p, true);

    return ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: bg,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: primary,
                    brightness: Brightness.dark,
                    primary: primary,
                    onPrimary: text,
                    surface: surface,
                    surfaceTint: Colors.transparent, // Disable overlay tint
                    surfaceContainerHighest:
                        surface, // Force match card color
                    surfaceContainerHigh: surface,
                    surfaceContainer: surface,
                    surfaceContainerLow: bg,
                    surfaceContainerLowest: bg,
                    secondaryContainer:
                        surface, // Ensures FilledButton.tonal is NOT olive green
                    onSecondaryContainer: text,
                    onSurface: text,
                  ),
                  textTheme: _createTextTheme(
                    ThemeData.dark().textTheme,
                    text,
                  ),
                  appBarTheme: AppBarTheme(
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: surface,
                    hintStyle: TextStyle(
                      color: text.withValues(alpha: 0.4),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: text.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: text.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                  cardTheme: CardThemeData(
                    color: surface,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  chipTheme: ChipThemeData(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: primary.withValues(alpha: 0.3),
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
                    backgroundColor: primary,
                    foregroundColor: Color(0xFF1E1E24), // Text on button
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: bg,
                    indicatorColor: primary.withValues(alpha: 0.2),
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
                  checkboxTheme: CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: WidgetStateBorderSide.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return BorderSide(color: primary, width: 2);
                      }
                      return const BorderSide(color: Colors.grey, width: 2);
                    }),
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return primary;
                      }
                      return Colors.transparent;
                    }),
                    checkColor: WidgetStateProperty.all(Colors.white),
                  ),
                );
  }
}
