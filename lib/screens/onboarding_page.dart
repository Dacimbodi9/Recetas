import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/screens/main_navigation.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    SettingsManager.completeOnboarding();
    // Use pushReplacement to avoid going back to onboarding
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar (Wizard Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  final isActive = index <= _currentPage;
                  return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: isActive ? 32 : 16, // Active step is wider
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                      .animate(target: isActive ? 1 : 0)
                      .scale(
                        end: const Offset(1.2, 1.2),
                        duration: 150.ms,
                        curve: Curves.easeOut,
                      )
                      .then()
                      .scale(
                        end: const Offset(1.0, 1.0),
                        duration: 150.ms,
                        curve: Curves.easeIn,
                      );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(), // Enforce buttons
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStep1Welcome(theme, _currentPage == 0),
                  _buildStep3Settings(theme, isDark, _currentPage == 1),
                  _buildStep4BodyProfile(theme, isDark, _currentPage == 2),
                  _buildStep5BottomMenu(theme, isDark, _currentPage == 3),
                ],
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor:
                        theme.colorScheme.onPrimary, // High contrast text
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Comenzar a cocinar'.tr
                        : 'Siguiente'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Welcome
  Widget _buildStep1Welcome(ThemeData theme, bool isActive) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  isDark
                      ? 'assets/images/onboarding_logo_dark.png'
                      : 'assets/images/onboarding_logo_light.jpg',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fade(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          SizedBox(height: 32),
          Text(
                'Bienvenido a Recetas'.tr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
              .animate(target: isActive ? 1 : 0)
              .fade(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  // Step 3: Initial Setup
  Widget _buildStep3Settings(ThemeData theme, bool isDark, bool isActive) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              [
                    Text(
                      'Personaliza tu experiencia'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Dark Mode Toggle
                    ValueListenableBuilder<bool>(
                      valueListenable: SettingsManager.isDarkMode,
                      builder: (context, isDarkEnabled, _) {
                        return _buildSettingToggle(
                          theme,
                          isDark,
                          title: 'Modo Oscuro'.tr,
                          subtitle: 'Activa el tema oscuro.'.tr,
                          icon: isDarkEnabled
                              ? CupertinoIcons.moon_fill
                              : CupertinoIcons.sun_max_fill,
                          value: isDarkEnabled,
                          onChanged: (v) => SettingsManager.setDarkMode(v),
                        );
                      },
                    ),
                    SizedBox(height: 16),

                    // Default Recipes
                    ValueListenableBuilder<bool>(
                      valueListenable: SettingsManager.showDefaultRecipes,
                      builder: (context, showDefaults, _) {
                        return _buildSettingToggle(
                          theme,
                          isDark,
                          title: 'Recetas Predeterminadas'.tr,
                          subtitle: 'Carga nuestras +1000 recetas iniciales.'
                              .tr
                              .tr
                              .tr,
                          icon: Icons.book,
                          value: showDefaults,
                          onChanged: (v) => SettingsManager.setShowDefaults(v),
                        );
                      },
                    ),
                    SizedBox(height: 16),

                    // Language Setting
                    ValueListenableBuilder<String>(
                      valueListenable: SettingsManager.language,
                      builder: (context, lang, _) {
                        final isEnglish = lang == 'en';
                        return _buildSettingToggle(
                          theme,
                          isDark,
                          title: 'Idioma / Language'.tr,
                          subtitle: isEnglish
                              ? 'App is in English'
                              : 'La aplicación está en Español',
                          icon: CupertinoIcons.globe,
                          value: isEnglish,
                          onChanged: (v) =>
                              SettingsManager.setLanguage(v ? 'en' : 'es'),
                        );
                      },
                    ),
                    SizedBox(height: 16),

                    // Dietary Filters
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? theme.cardColor : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filtros Dietéticos'.tr,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Excluye recetas incompatibles. Elige las que coincidan con tu dieta.'
                                          .tr,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ValueListenableBuilder<Set<DietaryRestriction>>(
                            valueListenable: SettingsManager.dietaryDefaults,
                            builder: (context, defaults, _) {
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: DietaryRestriction.values.map((
                                  restriction,
                                ) {
                                  final isSelected = defaults.contains(
                                    restriction,
                                  );
                                  return FilterChip(
                                    label: Text(restriction.displayName),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        SettingsManager.toggleDietaryDefault(
                                          restriction,
                                        ),
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    selectedColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ]
                  .asMap()
                  .entries
                  .map(
                    (e) => e.value
                        .animate(target: isActive ? 1 : 0)
                        .fade(duration: 400.ms, delay: (e.key * 100).ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildSettingToggle(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // Step 4: Body Profile
  Widget _buildStep4BodyProfile(ThemeData theme, bool isDark, bool isActive) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Perfil Físico'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Estos datos se usan para calcular recomendaciones nutricionales personalizadas'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _buildNumberInput(theme, isDark, 'Peso (kg)'.tr, SettingsManager.userWeight.value?.toString(), (v) {
              final val = double.tryParse(v);
              if (val != null) SettingsManager.setUserWeight(val);
            }),
            SizedBox(height: 16),
            _buildNumberInput(theme, isDark, 'Altura (cm)'.tr, SettingsManager.userHeight.value?.toString(), (v) {
              final val = double.tryParse(v);
              if (val != null) SettingsManager.setUserHeight(val);
            }),
            SizedBox(height: 16),
            _buildNumberInput(theme, isDark, 'Edad'.tr, SettingsManager.userAge.value?.toString(), (v) {
              final val = int.tryParse(v);
              if (val != null) SettingsManager.setUserAge(val);
            }),
            SizedBox(height: 16),
            _buildDropdownInput(theme, isDark, 'Sexo'.tr, SettingsManager.userSex.value, (v) {
              SettingsManager.setUserSex(v);
            }, [
              DropdownMenuItem(value: 'male', child: Text('Masculino'.tr)),
              DropdownMenuItem(value: 'female', child: Text('Femenino'.tr)),
            ]),
            SizedBox(height: 16),
            _buildDropdownInput(
              theme, 
              isDark, 
              'Nivel de Actividad'.tr, 
              SettingsManager.userActivityLevel.value?.toString() ?? '1.55', 
              (v) {
                final val = double.tryParse(v ?? '');
                if (val != null) SettingsManager.setUserActivityLevel(val);
              }, 
              [
                DropdownMenuItem(value: '1.2', child: Text('Sedentario (Poco/ningún ejercicio)'.tr)),
                DropdownMenuItem(value: '1.375', child: Text('Ligero (1-3 días/sem)'.tr)),
                DropdownMenuItem(value: '1.55', child: Text('Moderado (3-5 días/sem)'.tr)),
                DropdownMenuItem(value: '1.725', child: Text('Muy activo (6-7 días/sem)'.tr)),
                DropdownMenuItem(value: '1.9', child: Text('Extremo (Trabajo físico/Atleta)'.tr)),
              ],
            ),
            SizedBox(height: 32),
            Text(
              'Estos datos son opcionales y se guardan solo en tu dispositivo'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ].asMap().entries.map((e) => e.value
              .animate(target: isActive ? 1 : 0)
              .fade(duration: 400.ms, delay: (e.key * 100).ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic)
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildNumberInput(ThemeData theme, bool isDark, String label, String? initialValue, Function(String) onChanged) {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        filled: true,
        fillColor: isDark ? theme.cardColor : theme.cardColor,
      ),
    );
  }

  Widget _buildDropdownInput(ThemeData theme, bool isDark, String label, String? value, Function(String?) onChanged, List<DropdownMenuItem<String>> items) {
    return Theme(
      data: theme.copyWith(
        focusColor: Colors.transparent, // Removes the grey background of selected items
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        items: items,
        borderRadius: BorderRadius.circular(16),
        dropdownColor: isDark ? theme.colorScheme.surfaceContainerHighest : theme.cardColor,
        icon: Icon(CupertinoIcons.chevron_down, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          filled: true,
          fillColor: isDark ? theme.cardColor : theme.cardColor,
        ),
      ),
    );
  }

  // Step 5: Bottom Menu Features
  Widget _buildStep5BottomMenu(ThemeData theme, bool isDark, bool isActive) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              [
                    Text(
                      'Menú principal'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Elige qué funciones quieres tener a mano en la barra inferior (máx 4). Las que no selecciones aparecerán en la pantalla de inicio.'
                          .tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    ValueListenableBuilder<List<String>>(
                      valueListenable: SettingsManager.bottomMenuFeatures,
                      builder: (context, features, _) {
                        return Column(
                          children: SettingsManager.availableFeatures.map((
                            feat,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildFeatureToggle(
                                context,
                                theme,
                                isDark,
                                id: feat['id'],
                                title: feat['title'],
                                subtitle: feat['subtitle'],
                                icon: feat['icon'],
                                features: features,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ]
                  .asMap()
                  .entries
                  .map(
                    (e) => e.value
                        .animate(target: isActive ? 1 : 0)
                        .fade(duration: 400.ms, delay: (e.key * 100).ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildFeatureToggle(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> features,
  }) {
    final isSelected = features.contains(id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(
                alpha: isSelected ? 0.2 : 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Switch(
            value: isSelected,
            onChanged: (val) {
              final newFeatures = List<String>.from(features);
              if (val) {
                if (newFeatures.length >= 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Solo puedes seleccionar hasta 4 accesos directos'.tr,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                newFeatures.add(id);
              } else {
                newFeatures.remove(id);
              }
              SettingsManager.setBottomMenuFeatures(newFeatures);
            },
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}


