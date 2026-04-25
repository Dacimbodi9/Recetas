// ignore_for_file: deprecated_member_use
// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'dart:async';
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
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_links/app_links.dart';

part 'models/models.dart';
part 'services/services.dart';
part 'utils/utils.dart';
part 'widgets/widgets.dart';
part 'screens/screens.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SettingsManager.loadSettings();
  await RecipeManager.loadDefaultRecipes();
  await RecipeManager.loadRecipes();
  await MealPlanManager.load();
  MealPlanManager.cleanOldMeals();
  runApp(RecetasApp());
  DeepLinkHandler.instance.init();
}

class RecetasApp extends StatefulWidget {
  const RecetasApp({super.key});

  @override
  State<RecetasApp> createState() => _RecetasAppState();
}

class _RecetasAppState extends State<RecetasApp> {
  @override
  Widget build(BuildContext context) {
    // Light Mode Palette - Vibe: "Artisan Bakery" (Parchment, Thick Cream, Dark Olive)
    const lightBg = Color(
      0xFFEBE6DD,
    ); // Papel de hornear tostado (Toasted Baking Paper - richer, distinctly warm beige)
    const lightSurface = Color(
      0xFFF6F3EC,
    ); // Crema pastelera (Pastry Cream - undeniably a rich warm off-white)
    const lightPrimary = Color(
      0xFF6B8738,
    ); // Hojas de olivo (Deep, grounded olive leaf green)
    const lightSecondary = Color(
      0xFFB54921,
    ); // Horno de ladrillo (Deeper brick terracota)
    const lightText = Color(
      0xFF2E2A27,
    ); // Café moca (Rich dark mocha brown, extremely earthy)

    // Dark Mode Palette - Vibe: "Rustic Organic Kitchen" (Deep Forest & Sage)
    const darkBg = Color(
      0xFF141513,
    ); // Trufa negra / Sombra de bosque (Black Truffle / Deep Forest)
    const darkSurface = Color(
      0xFF222420,
    ); // Madera de olivo oscura (Dark Olive Wood)
    const darkPrimary = Color(
      0xFF8BA85D,
    ); // Hojas de salvia / Romero (Sage / Rosemary)
    const darkText = Color(
      0xFFF2EFE9,
    ); // Harina / Crema (Flour / Warm Cream instead of pure white)
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
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarColor: Colors.transparent,
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemStatusBarContrastEnforced: false,
              ),
              child: MaterialApp(
                navigatorKey: navigatorKey,
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
                    background: darkBg,
                  ),
                  textTheme: createTextTheme(
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
              ),
            );
          },
        );
      },
    );
  }
}
