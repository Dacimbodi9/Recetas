part of '../main.dart';

class _BottomMenuSettingsPage extends StatelessWidget {
  const _BottomMenuSettingsPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Menú principal'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Elige qué funciones quieres tener a mano en la barra inferior (máx 4). Las que no selecciones aparecerán en la pantalla de inicio.'
                  .tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ValueListenableBuilder<List<String>>(
              valueListenable: SettingsManager.bottomMenuFeatures,
              builder: (context, features, _) {
                return Column(
                  children: SettingsManager.availableFeatures.map((feat) {
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
          ],
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
                  offset: const Offset(0, 4),
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
          const SizedBox(width: 16),
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
          const SizedBox(width: 8),
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.language,
      builder: (context, lang, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Ajustes'.tr)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children:
                [
                      _SettingsSection(
                        title: 'GENERAL'.tr,
                        children: [
                          _SettingsTile(
                            title: 'Escanear código QR'.tr,
                            subtitle:
                                'Importar una receta escaneando un código QR'
                                    .tr,
                            icon: CupertinoIcons.qrcode_viewfinder,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const _QrScannerPage(),
                                ),
                              );
                            },
                          ),

                          _SettingsTile(
                            title: 'Filtros dietéticos permanentes'.tr,
                            subtitle:
                                'Excluir siempre recetas incompatibles'.tr,
                            icon: Icons.no_food,
                            trailing: Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _DietarySettingsPage(),
                                  ),
                                );
                              }
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: SettingsManager.showDefaultRecipes,
                            builder: (context, showDefaults, child) {
                              return _SettingsTile(
                                title: 'Mostrar Recetas Predeterminadas'.tr,
                                isSwitch: true,
                                switchValue: showDefaults,
                                onSwitchChanged: (value) =>
                                    SettingsManager.setShowDefaults(value),
                                icon: CupertinoIcons.book_fill,
                                lastItem: true,
                              );
                            },
                          ),
                        ],
                      ),

                      _SettingsSection(
                        title: 'APARIENCIA Y NAVEGACIÓN'.tr,
                        children: [
                          _SettingsTile(
                            title: 'Menú principal'.tr,
                            subtitle: 'Personalizar botones inferiores'.tr,
                            icon: CupertinoIcons.rectangle_grid_2x2,
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const _BottomMenuSettingsPage(),
                                  ),
                                );
                              }
                            },
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable: SettingsManager.startScreenFeature,
                            builder: (context, feature, child) {
                              String subtitle = '';
                              if (feature == 'search') {
                                subtitle = 'Buscar'.tr;
                              } else if (feature == 'saved') {
                                subtitle = 'Guardados'.tr;
                              } else if (feature == 'mealPlanner') {
                                subtitle = 'Planificador de comidas'.tr;
                              } else if (feature == 'profile') {
                                subtitle = 'Inicio'.tr;
                              }

                              return _SettingsTile(
                                title: 'Pantalla predeterminada'.tr,
                                icon: CupertinoIcons.home,
                                subtitle: subtitle,
                                trailing: const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onTap: () =>
                                    _showStartScreenDialog(context, feature),
                              );
                            },
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable: SettingsManager.language,
                            builder: (context, lang, child) {
                              return _SettingsTile(
                                title: 'Idioma / Language'.tr,
                                icon: CupertinoIcons.globe,
                                subtitle: lang == 'en' ? 'English' : 'Español',
                                trailing: Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onTap: () =>
                                    _showLanguageScreenDialog(context, lang),
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: SettingsManager.isDarkMode,
                            builder: (context, isDark, child) {
                              return _SettingsTile(
                                title: 'Modo Oscuro'.tr,
                                isSwitch: true,
                                switchValue: isDark,
                                onSwitchChanged: (value) =>
                                    SettingsManager.setDarkMode(value),
                                icon: CupertinoIcons.moon_fill,
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: SettingsManager.preventSleep,
                            builder: (context, prevent, child) {
                              return _SettingsTile(
                                title: 'Mantener pantalla encendida'.tr,
                                isSwitch: true,
                                switchValue: prevent,
                                onSwitchChanged: (value) =>
                                    SettingsManager.setPreventSleep(value),
                                icon: CupertinoIcons.eye,
                                lastItem: false,
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: SettingsManager.showTodayMealsInHome,
                            builder: (context, showInHome, child) {
                              return _SettingsTile(
                                title: 'Comidas de hoy en Inicio'.tr,
                                subtitle: 'Mostrar resumen en vez de en planificador'.tr,
                                isSwitch: true,
                                switchValue: showInHome,
                                onSwitchChanged: (value) =>
                                    SettingsManager.setShowTodayMealsInHome(value),
                                icon: CupertinoIcons.square_list,
                                lastItem: true,
                              );
                            },
                          ),
                        ],
                      ),

                      _SettingsSection(
                        title: 'MIS DATOS'.tr,
                        children: [
                          _SettingsTile(
                            title: 'Perfil Físico'.tr,
                            subtitle: 'Configura tus datos de salud para recomendaciones'.tr,
                            icon: Icons.accessibility_new_rounded,
                            trailing: Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BodyProfileSettingsPage(),
                                  ),
                                );
                              }
                            },
                          ),
                          _SettingsTile(
                            title: 'Configurar API Key'.tr,
                            subtitle:
                                'Usar IA para extraer recetas de imágenes'.tr,
                            icon: CupertinoIcons.sparkles,
                            trailing: Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _AiSettingsPage(),
                                  ),
                                );
                              }
                            },
                          ),
                          _SettingsTile(
                            title: 'Exportar recetas'.tr,
                            icon: CupertinoIcons.share,
                            onTap: () => SettingsManager.exportRecipes(context),
                          ),
                          _SettingsTile(
                            title: 'Importar recetas'.tr,
                            icon: CupertinoIcons.arrow_down_doc,
                            onTap: () => SettingsManager.importRecipes(context),
                          ),
                          _SettingsTile(
                            title: 'Borrar todos los datos'.tr,
                            icon: CupertinoIcons.delete,
                            iconColor: Colors.red,
                            textColor: Colors.red,
                            onTap: () => SettingsManager.clearData(context),
                          ),
                          _SettingsTile(
                            title: 'Legal'.tr,
                            subtitle: 'Política de Privacidad y Términos'.tr,
                            icon: CupertinoIcons.doc_text,
                            trailing: Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _LegalPage(),
                                  ),
                                );
                              }
                            },
                            lastItem: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 32),
                    ]
                    .animate(interval: 50.ms)
                    .fade(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ),
        );
      },
    );
  }

  void _showStartScreenDialog(BuildContext context, String currentFeature) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Color(0xFF1C1C1E) // iOS Dark Gray
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),

              Text(
                'Elegir pantalla predeterminada'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: SettingsManager.bottomMenuFeatures,
                  builder: (context, features, _) {
                    final activeFeatures = [...features, 'profile'];
                    return Column(
                      children: activeFeatures.map((feature) {
                        String title = '';
                        IconData icon = Icons.circle;

                        if (feature == 'search') {
                          title = 'Buscar'.tr;
                          icon = CupertinoIcons.search;
                        } else if (feature == 'saved') {
                          title = 'Guardados'.tr;
                          icon = CupertinoIcons.book;
                        } else if (feature == 'mealPlanner') {
                          title = 'Planificador de comidas'.tr;
                          icon = Icons.calendar_month_outlined;
                        } else if (feature == 'profile') {
                          title = 'Inicio'.tr;
                          icon = CupertinoIcons.house;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SelectionOption(
                            title: title,
                            icon: icon,
                            isSelected: currentFeature == feature,
                            onTap: () {
                              SettingsManager.setStartScreenFeature(feature);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              SizedBox(height: 48), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageScreenDialog(BuildContext context, String currentLanguage) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1C1C1E) // iOS Dark Gray
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Idioma / Language'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SelectionOption(
                      title: 'Español'.tr,
                      icon: CupertinoIcons.globe,
                      isSelected: currentLanguage == 'es',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _changeLanguage(context, 'es');
                      },
                    ),
                    const SizedBox(height: 12),
                    _SelectionOption(
                      title: 'English'.tr,
                      icon: CupertinoIcons.globe,
                      isSelected: currentLanguage == 'en',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _changeLanguage(context, 'en');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  void _changeLanguage(BuildContext context, String lang) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              DefaultTextStyle(
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                child: Text(
                  lang == 'en' ? 'Applying language...' : 'Aplicando idioma...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(decoration: TextDecoration.none),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Store navigator before awaiting, so we can pop the dialog even if context unmounts
    final navigator = Navigator.of(context, rootNavigator: true);

    // Wait for the simulated loading & the actual language setting logic
    await Future.delayed(const Duration(milliseconds: 1000));
    await SettingsManager.setLanguage(lang);

    navigator.pop();
  }
}

class _SelectionOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? iconColor;

  const _SelectionOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isDestructive ? Colors.red : theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : theme.brightness == Brightness.dark
              ? theme.cardColor
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : isDestructive
                    ? Colors.red.withValues(alpha: 0.15)
                    : (iconColor != null)
                    ? iconColor!.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDestructive
                          ? Colors.red
                          : (iconColor ?? theme.iconTheme.color)),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? activeColor
                      : (isDestructive ? Colors.red : null),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: activeColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _DietarySettingsPage extends StatelessWidget {
  const _DietarySettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Filtros Dietéticos'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Selecciona las restricciones que coincidan con tus preferencias (ej: si eres vegetariano, selecciona "vegetariano"). Añadirá un indicador rojo a las recetas que no cumplen con estas restricciones.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ValueListenableBuilder<Set<DietaryRestriction>>(
              valueListenable: SettingsManager.dietaryDefaults,
              builder: (context, defaults, child) {
                final restrictions = DietaryRestriction.values.toList();

                return _SettingsSection(
                  title: 'RESTRICCIONES'.tr.tr,
                  children: List.generate(restrictions.length, (index) {
                    final restriction = restrictions[index];
                    final isSelected = defaults.contains(restriction);
                    return _SettingsTile(
                      title: restriction.displayName,
                      subtitle: restriction
                          .description, // Added description for clarity
                      isSwitch: true,
                      switchValue: isSelected,
                      onSwitchChanged: (_) =>
                          SettingsManager.toggleDietaryDefault(restriction),
                      lastItem: index == restrictions.length - 1,
                    );
                  }),
                );
              },
            ),
            SizedBox(height: 24),
            ValueListenableBuilder<Set<String>>(
              valueListenable: SettingsManager.customDietaryDefaults,
              builder: (context, customDefaults, child) {
                final allCustomTags =
                    RecipeManager.allCustomDietaryTags.toList()..sort();
                if (allCustomTags.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _SettingsSection(
                      title: 'ETIQUETAS PERSONALIZADAS'.tr.tr,
                      children: List.generate(allCustomTags.length, (index) {
                        final tag = allCustomTags[index];
                        final isSelected = customDefaults.contains(tag);
                        return _SettingsTile(
                          title: tag,
                          isSwitch: true,
                          switchValue: isSelected,
                          onSwitchChanged: (_) =>
                              SettingsManager.toggleCustomDietaryDefault(tag),
                          lastItem: index == allCustomTags.length - 1,
                        );
                      }),
                    ),
                    SizedBox(height: 24),
                  ],
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsManager.applyDietaryToDefaults,
              builder: (context, applyToDefaults, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: SettingsManager.hideIncompatibleRecipes,
                  builder: (context, hideIncompatible, _) {
                    return _SettingsSection(
                      title: 'OPCIONES'.tr.tr,
                      children: [
                        _SettingsTile(
                          title: 'Aplicar a recetas predeterminadas'.tr.tr,
                          subtitle:
                              'Mostrar indicador rojo también en recetas incluidas en la app'
                                  .tr
                                  .tr
                                  .tr,
                          isSwitch: true,
                          switchValue: applyToDefaults,
                          onSwitchChanged: (value) =>
                              SettingsManager.setApplyDietaryToDefaults(value),
                          lastItem: false,
                        ),
                        _SettingsTile(
                          title: 'Ocultar recetas incompatibles'.tr.tr,
                          subtitle:
                              'No mostrar recetas que no cumplan con los filtros'
                                  .tr
                                  .tr
                                  .tr,
                          isSwitch: true,
                          switchValue: hideIncompatible,
                          onSwitchChanged: (val) =>
                              SettingsManager.setHideIncompatibleRecipes(val),

                          lastItem: true,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSettingsPage extends StatefulWidget {
  @override
  State<_AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<_AiSettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiEndpointController = TextEditingController();
  String _provider = 'gemini';

  @override
  void initState() {
    super.initState();
    _provider = SettingsManager.aiProvider.value.isEmpty
        ? 'gemini'
        : SettingsManager.aiProvider.value;
    _apiKeyController.text = SettingsManager.aiApiKey.value;
    _apiEndpointController.text = SettingsManager.aiApiEndpoint.value.isEmpty
        ? 'https://api.openai.com/v1/chat/completions'
        : SettingsManager.aiApiEndpoint.value;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiEndpointController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await SettingsManager.setAiProvider(_provider);
    await SettingsManager.setAiApiKey(_apiKeyController.text.trim());
    await SettingsManager.setAiApiEndpoint(_apiEndpointController.text.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openLink(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Configuración de IA'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            CupertinoIcons.sparkles,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Escaneo de Recetas Inteligente'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Para que la aplicación pueda leer fotos de recetas y convertirlas automáticamente en texto, necesitas conectar un servicio de Inteligencia Artificial.'
                .tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 32),

          Text(
            '1. Elige tu proveedor de IA'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: RadioGroup<String>(
              groupValue: _provider,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _provider = val);
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Google Gemini (Recomendado, Gratis)'.tr),
                    value: 'gemini',
                    activeColor: theme.colorScheme.primary,
                  ),
                  RadioListTile<String>(
                    title: Text('OpenAI / Otros compatibles'.tr),
                    value: 'openai',
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),

          Text(
            '2. Consigue tu Clave (API Key)'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (_provider == 'gemini') ...[
            Text(
              'Gemini ofrece una clave gratuita y es muy fácil de obtener. Solo entra a Google AI Studio pulsando el botón de abajo, inicia sesión con tu cuenta de Google, y pulsa en "Get API key" o "Crear clave de API".'
                  .tr,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _openLink('https://aistudio.google.com/app/apikey'),
              icon: Icon(Icons.open_in_new),
              label: Text('Obtener clave de Gemini'.tr),
            ),
          ] else ...[
            Text(
              'Para usar OpenAI (ChatGPT) necesitas una cuenta de desarrollador de pago con saldo en platform.openai.com. También puedes usar servicios compatibles como OpenRouter editando el Endpoint.'
                  .tr,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _openLink('https://platform.openai.com/api-keys'),
              icon: Icon(Icons.open_in_new),
              label: Text('Obtener clave de OpenAI'.tr),
            ),
          ],
          SizedBox(height: 32),

          Text(
            '3. Pega tu API Key aquí'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'Clave de API (API Key)'.tr,
              hintText: _provider == 'gemini' ? 'AIzaSy...' : 'sk-...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
          ),

          if (_provider != 'gemini') ...[
            SizedBox(height: 24),
            Text(
              'Opciones Avanzadas'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: _apiEndpointController,
              decoration: InputDecoration(
                labelText: 'API Endpoint Url (Opcional)'.tr,
                hintText: 'https://api.openai.com/v1/chat/completions',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          SizedBox(height: 48),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  theme.colorScheme.primary, // using simple primary
            ),
            child: Text(
              'Guardar Configuración'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Legal'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Política de Privacidad'),
              Tab(text: 'Términos de Uso'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalContent(isPrivacy: true),
            _LegalContent(isPrivacy: false),
          ],
        ),
      ),
    );
  }
}

class BodyProfileSettingsPage extends StatefulWidget {
  const BodyProfileSettingsPage({super.key});

  @override
  State<BodyProfileSettingsPage> createState() => _BodyProfileSettingsPageState();
}

class _BodyProfileSettingsPageState extends State<BodyProfileSettingsPage> {
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  String? _sex;
  double? _activityLevel;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: SettingsManager.userWeight.value?.toString() ?? '');
    _heightController = TextEditingController(text: SettingsManager.userHeight.value?.toString() ?? '');
    _ageController = TextEditingController(text: SettingsManager.userAge.value?.toString() ?? '');
    _sex = SettingsManager.userSex.value;
    _activityLevel = SettingsManager.userActivityLevel.value;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);
    
    await SettingsManager.setUserWeight(weight);
    await SettingsManager.setUserHeight(height);
    await SettingsManager.setUserAge(age);
    await SettingsManager.setUserSex(_sex);
    await SettingsManager.setUserActivityLevel(_activityLevel);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Perfil Físico'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Estos datos se usan para calcular recomendaciones nutricionales personalizadas'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Peso (kg)'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Altura (cm)'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Edad'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _sex,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
            icon: Icon(CupertinoIcons.chevron_down, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            decoration: InputDecoration(
              labelText: 'Sexo'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: [
              DropdownMenuItem(value: 'male', child: Text('Masculino'.tr)),
              DropdownMenuItem(value: 'female', child: Text('Femenino'.tr)),
            ],
            onChanged: (val) {
              setState(() {
                _sex = val;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<double>(
            initialValue: _activityLevel ?? 1.55,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
            icon: Icon(CupertinoIcons.chevron_down, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            decoration: InputDecoration(
              labelText: 'Nivel de Actividad'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              helperMaxLines: 3,
              helperText: _activityLevel == 1.2 ? 'Sedentario: Trabajo de oficina, poco o ningún ejercicio.'.tr :
                          _activityLevel == 1.375 ? 'Ligeramente activo: Ejercicio ligero 1-3 días a la semana.'.tr :
                          _activityLevel == 1.55 || _activityLevel == null ? 'Moderadamente activo: Ejercicio 3-5 días a la semana.'.tr :
                          _activityLevel == 1.725 ? 'Muy activo: Ejercicio fuerte 6-7 días a la semana.'.tr :
                          'Extremadamente activo: Trabajo físico duro o entrenamiento doble.'.tr,
            ),
            items: [
              DropdownMenuItem(value: 1.2, child: Text('Sedentario (Poco/ningún ejercicio)'.tr)),
              DropdownMenuItem(value: 1.375, child: Text('Ligero (1-3 días/sem)'.tr)),
              DropdownMenuItem(value: 1.55, child: Text('Moderado (3-5 días/sem)'.tr)),
              DropdownMenuItem(value: 1.725, child: Text('Muy activo (6-7 días/sem)'.tr)),
              DropdownMenuItem(value: 1.9, child: Text('Extremo (Trabajo físico/Atleta)'.tr)),
            ],
            onChanged: (val) {
              setState(() {
                _activityLevel = val;
              });
            },
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Guardar Configuración'.tr),
          ),
        ],
      ),
    );
  }
}
