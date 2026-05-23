// ignore_for_file: unused_element
// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: deprecated_member_use
// ignore_for_file: constant_identifier_names
// ignore_for_file: avoid_print
part of '../main.dart';


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
                  SearchPage(key: ValueKey('search_$lang'), showAppBar: false),
                );
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.search),
                    label: 'Buscar'.tr,
                  ),
                );
              } else if (feature == 'saved') {
                pages.add(
                  SavedPage(key: ValueKey('saved_$lang'), showAppBar: false),
                );
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.book),
                    label: 'Guardados'.tr,
                  ),
                );
              } else if (feature == 'mealPlanner') {
                pages.add(const _MealPlannerPage(showAppBar: false));
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: 'Planificador'.tr,
                  ),
                );
              } else if (feature == 'shopping') {
                pages.add(const _ShoppingPage(showAppBar: false));
                destinations.add(
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.cart),
                    label: 'Compra'.tr,
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
