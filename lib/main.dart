// ignore_for_file: deprecated_member_use
// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
// import 'shopping_list.dart';

part 'models/models.dart';
part 'services/services.dart';
part 'utils/utils.dart';
part 'widgets/widgets.dart';
part 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager.loadSettings();
  await RecipeManager.loadDefaultRecipes();
  await RecipeManager.loadRecipes();
  runApp(RecetasApp());
}

class RecetasApp extends StatefulWidget {
  const RecetasApp({super.key});

  @override
  State<RecetasApp> createState() => _RecetasAppState();
}

class _RecetasAppState extends State<RecetasApp> {
  @override
  @override
  Widget build(BuildContext context) {
    // Light Mode Palette
    const lightBg = Color(0xFFF9F7F2); // Crema suave / Hueso
    const lightPrimary = Color(0xFF6B8E23); // Verde Salvia / Albahaca
    const lightSecondary = Color(0xFFC05832); // Terracota / Naranja Quemado
    const lightText = Color(0xFF333333); // Gris oscuro cálido
    const lightSurface = Colors.white;

    // Dark Mode Palette
    const darkBg = Color(0xFF1E1E24); // Gris Carbón / Azul Pizarra muy oscuro
    const darkSurface = Color(0xFF2B2B36); // Ligeramente más claro que el fondo
    const darkPrimary = Color(0xFF9CCC65); // Verde Fresco / Vibrante
    // const darkSecondary = Color(0xFFE2916E); // Terracota suave

    // Typography
    TextTheme createTextTheme(TextTheme base, Color textColor) {
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

    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.language,
      builder: (context, lang, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: SettingsManager.isDarkMode,
          builder: (context, isDark, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Recetas'.tr.tr,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: lightBg,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: lightPrimary,
                  brightness: Brightness.light,
                  primary: lightPrimary,
                  secondary: lightSecondary,
                  surface: lightSurface,
                  onSurface: lightText,
                  background: lightBg,
                ),
                textTheme: createTextTheme(
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
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: lightPrimary, width: 1.5),
                  ),
                ),
                cardTheme: CardThemeData(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black12,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
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
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: darkBg,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: darkPrimary,
                  brightness: Brightness.dark,
                  primary: darkPrimary,
                  surface: darkSurface,
                  onSurface: Colors.white, // Text on dark background
                  background: darkBg,
                ),
                textTheme: createTextTheme(
                  ThemeData.dark().textTheme,
                  Colors.white,
                ),
                appBarTheme: AppBarTheme(
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.transparent,
                  centerTitle: true,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
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
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
              ),
              home: ValueListenableBuilder<bool>(
                valueListenable: SettingsManager.hasSeenOnboarding,
                builder: (context, hasSeen, _) {
                  if (!hasSeen) return OnboardingPage();

                  return ValueListenableBuilder<int>(
                    valueListenable: SettingsManager.startScreenIndex,
                    builder: (context, index, child) => MainNavigationPage(),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
