import 'package:flutter/material.dart';
import 'package:recetas/services/snackbar_service.dart';
import 'l10n.dart';
import 'theme.dart';
import 'package:flutter/services.dart';

import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:recetas/services/deep_link_handler.dart';
import 'package:recetas/services/meal_plan_manager.dart';
import 'package:recetas/services/shopping_list_manager.dart';
import 'package:recetas/screens/main_navigation.dart';
import 'package:recetas/screens/onboarding_page.dart';
import 'package:recetas/services/data_management_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SettingsManager.loadSettings();
  await RecipeManager.loadDefaultRecipes();
  await RecipeManager.loadRecipes();
  await MealPlanManager.load();
  await ShoppingListManager.load();

  MealPlanManager.cleanOldMeals();
  
  // Run auto backup silently in background if needed
  DataManagementService.runAutoBackupIfNeeded().catchError((e) {
    debugPrint('Auto backup failed: $e');
  });

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
    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.language,
      builder: (context, lang, child) {
        return ValueListenableBuilder<String>(
          valueListenable: SettingsManager.activeThemeId,
          builder: (context, themeId, child) {
            final preset = SettingsManager.activePreset;
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
                    scaffoldMessengerKey: SnackbarService.messengerKey,
                    navigatorKey: navigatorKey,
                    debugShowCheckedModeBanner: false,
                    title: 'Recetas'.tr,
                    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        child: child,
                      );
                    },
                    theme: AppTheme.light(preset),
                    darkTheme: AppTheme.dark(preset),
                    home: ValueListenableBuilder<bool>(
                      valueListenable: SettingsManager.hasSeenOnboarding,
                      builder: (context, hasSeen, _) {
                        if (!hasSeen) return OnboardingPage();

                        return ValueListenableBuilder<String>(
                          valueListenable: SettingsManager.startScreenFeature,
                          builder: (context, feature, child) =>
                              MainNavigationPage(),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}





