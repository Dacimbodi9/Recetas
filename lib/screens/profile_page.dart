part of '../main.dart';

class _ShareQRCodePage extends StatelessWidget {
  final Recipe recipe;

  const _ShareQRCodePage({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = recipe.toShareableData();

    return Scaffold(
      appBar: AppBar(title: Text('Código QR'.tr)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                recipe.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Otros pueden escanear este código para añadir la receta a su aplicación'
                    .tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 250.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: Text('Listo'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        final recipe = Recipe.fromShareableData(code);
        if (recipe != null) {
          setState(() => _isScanning = false);
          _importRecipe(recipe);
          break;
        }
      }
    }
  }

  Future<void> _importRecipe(Recipe recipe) async {

    final exists = RecipeManager.recipes.any((r) => r.title == recipe.title);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Receta detectada'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'¿Quieres importar la receta'.tr} "${recipe.title}"?'),
            if (exists) ...[
              const SizedBox(height: 12),
              Text(
                'Nota: Ya tienes una receta con este nombre.'.tr,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await RecipeManager.addRecipe(recipe);
              if (!RecipeManager.isFavorite(recipe)) {
                await RecipeManager.toggleFavorite(recipe);
              }
              nav.pop(); // Close dialog
              nav.pop(); // Close scanner
              messenger.showSnackBar(
                SnackBar(content: Text('Receta importada correctamente'.tr)),
              );
            },
            child: Text('Importar'.tr),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Escanear código QR'.tr)),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código QR de la receta'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: SettingsManager.userName.value,
    );
    RecipeManager.addListener(_onRecipesChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    RecipeManager.removeListener(_onRecipesChanged);
    super.dispose();
  }

  void _onRecipesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      await SettingsManager.setUserPhotoPath(image.path);
    }
  }

  void _showEditProfileMenu() {
    final theme = Theme.of(context);
    _nameController.text = SettingsManager.userName.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Editar perfil'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Editing photo
              GestureDetector(
                onTap: () => _showPhotoOptions(context),
                child: ValueListenableBuilder<String?>(
                  valueListenable: SettingsManager.userPhotoPath,
                  builder: (context, photoPath, _) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage:
                          (photoPath != null && photoPath.isNotEmpty)
                          ? FileImage(File(photoPath))
                          : null,
                      child: (photoPath == null || photoPath.isEmpty)
                          ? Icon(
                              CupertinoIcons.person_fill,
                              size: 50,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca para cambiar'.tr,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Editing name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    SettingsManager.setUserName(_nameController.text);
                    Navigator.pop(context);
                  },
                  child: Text('Guardar perfil'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.photo),
              title: Text('Galería'.tr),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.camera),
              title: Text('Cámara'.tr),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar (Centered vertically)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _showEditProfileMenu,
                            child: Stack(
                              children: [
                                ValueListenableBuilder<String?>(
                                  valueListenable:
                                      SettingsManager.userPhotoPath,
                                  builder: (context, photoPath, _) {
                                    return CircleAvatar(
                                      radius: 36,
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      backgroundImage:
                                          (photoPath != null &&
                                              photoPath.isNotEmpty)
                                          ? FileImage(File(photoPath))
                                          : null,
                                      child:
                                          (photoPath == null ||
                                              photoPath.isEmpty)
                                          ? Icon(
                                              CupertinoIcons.person_fill,
                                              size: 36,
                                              color: theme.colorScheme.primary,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.cardColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.camera_fill,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Name display
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ValueListenableBuilder<String>(
                                  valueListenable: SettingsManager.userName,
                                  builder: (context, name, _) {
                                    return Text(
                                      name,
                                      maxLines: 1,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontFamily:
                                                GoogleFonts.playfairDisplay()
                                                    .fontFamily,
                                          ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Settings button
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.settings,
                          size: 20,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<String>>(
                valueListenable: SettingsManager.bottomMenuFeatures,
                builder: (context, features, _) {
                  return Column(
                    children: [
                      if (!features.contains('search')) ...[
                        _buildProfileFeatureCard(
                          theme,
                          title: 'Buscar'.tr,
                          subtitle: 'Busca recetas e ingredientes'.tr,
                          icon: CupertinoIcons.search,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!features.contains('saved')) ...[
                        _buildProfileFeatureCard(
                          theme,
                          title: 'Guardados'.tr,
                          subtitle: 'Tus recetas guardadas y favoritas'.tr,
                          icon: CupertinoIcons.book,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!features.contains('mealPlanner')) ...[
                        _buildProfileFeatureCard(
                          theme,
                          title: 'Planificador de comidas'.tr,
                          subtitle: 'Organiza tus comidas de la semana'.tr,
                          icon: Icons.calendar_month_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _MealPlannerPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!features.contains('shopping')) ...[
                        _buildProfileFeatureCard(
                          theme,
                          title: 'Lista de Compra'.tr,
                          subtitle: 'Gestión de despensa e ingredientes'.tr,
                          icon: CupertinoIcons.cart,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _ShoppingPage(showAppBar: true),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
              const _NutritionalGraphCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileFeatureCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          size: 18,
          color: Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onTap: onTap,
      ),
    );
  }
}
