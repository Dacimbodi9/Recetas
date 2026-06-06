import 'package:recetas/screens/shopping_list_page.dart';
import 'package:recetas/screens/meal_planner/meal_planner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/screens/search_page.dart';
import 'package:recetas/screens/saved_page.dart';
import 'package:recetas/screens/profile_page.dart';
import 'package:recetas/screens/stats_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  String _currentFeature = SettingsManager.startScreenFeature.value;

  @override
  void initState() {
    super.initState();
    _currentFeature = SettingsManager.startScreenFeature.value;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.language,
      builder: (context, lang, child) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: SettingsManager.bottomMenuFeatures,
          builder: (context, features, child) {
            final List<Widget> pages = [];
            final List<NavigationDestination> destinations = [];

            final limitedFeatures = features.take(4).toList();

            for (final feature in limitedFeatures) {
              if (feature == 'search') {
                pages.add(
                  _currentFeature == 'search'
                      ? SearchPage(
                          key: const ValueKey('search'),
                          showAppBar: false,
                        )
                      : const SizedBox.shrink(),
                );
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.search),
                    label: 'Buscar'.tr,
                  ),
                );
              } else if (feature == 'saved') {
                pages.add(
                  SavedPage(key: const ValueKey('saved'), showAppBar: false),
                );
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.book),
                    label: 'Guardados'.tr,
                  ),
                );
              } else if (feature == 'mealPlanner') {
                pages.add(const MealPlannerPage(showAppBar: false));
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: 'Planificador'.tr,
                  ),
                );
              } else if (feature == 'shoppingList') {
                pages.add(ShoppingListPage(
                  key: const ValueKey('shopping'),
                  showAppBar: false,
                  isActive: _currentFeature == 'shoppingList',
                ));
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: 'Compra'.tr,
                  ),
                );
              } else if (feature == 'stats') {
                pages.add(const StatsPage(showAppBar: false));
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: 'Estadísticas'.tr,
                  ),
                );
              }
            }

            // Always add ProfilePage (Inicio) at the end
            pages.add(ProfilePage(key: ValueKey('profile_$lang')));
            destinations.add(
              NavigationDestination(
                icon: const Icon(CupertinoIcons.house),
                label: 'Inicio'.tr,
              ),
            );

            final activeFeatures = [...limitedFeatures, 'profile'];
            int currentIndex = 0;
            if (activeFeatures.contains(_currentFeature)) {
              currentIndex = activeFeatures.indexOf(_currentFeature);
            } else {
              _currentFeature = 'profile';
              currentIndex = activeFeatures.length - 1;
            }

            return Scaffold(
              body: IndexedStack(index: currentIndex, children: pages),
              bottomNavigationBar: destinations.length >= 2
                  ? NavigationBar(
                      selectedIndex: currentIndex,
                      labelBehavior: destinations.length == 5
                          ? NavigationDestinationLabelBehavior.alwaysHide
                          : NavigationDestinationLabelBehavior.alwaysShow,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentFeature = activeFeatures[index];
                        });
                      },
                      destinations: destinations,
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}






