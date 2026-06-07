import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:recetas/l10n.dart';
import 'package:recetas/services/data_management_service.dart';
import 'package:recetas/services/settings_manager.dart';
import 'package:recetas/services/snackbar_service.dart';
import 'package:recetas/screens/onboarding_page.dart';

class DataSettingsPage extends StatefulWidget {
  const DataSettingsPage({super.key});

  @override
  State<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends State<DataSettingsPage> {
  bool _isLoading = false;
  List<File> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final backups = await DataManagementService.getAvailableBackups();
    setState(() {
      _backups = backups;
    });
  }

  Future<void> _exportData() async {
    bool expSettings = true;
    bool expRecipes = true;
    bool expMeals = true;
    bool expShopping = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Selecciona qué exportar'.tr),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: Text('Ajustes y Perfil'.tr),
                      value: expSettings,
                      onChanged: (v) => setDialogState(() => expSettings = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('Recetas y Carpetas'.tr),
                      value: expRecipes,
                      onChanged: (v) => setDialogState(() => expRecipes = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('Planificador y Plantillas'.tr),
                      value: expMeals,
                      onChanged: (v) => setDialogState(() => expMeals = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('Lista de la compra'.tr),
                      value: expShopping,
                      onChanged: (v) => setDialogState(() => expShopping = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar'.tr),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Continuar'.tr),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;
    if (!expSettings && !expRecipes && !expMeals && !expShopping) {
      SnackbarService.showMessage('Selecciona al menos una opción'.tr);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await DataManagementService.exportData(
        exportSettings: expSettings,
        exportRecipes: expRecipes,
        exportMeals: expMeals,
        exportShopping: expShopping,
      );
      final jsonStr = jsonEncode(data);

      if (!mounted) return;
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text('Compartir'.tr),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: const Icon(Icons.save),
                  title: Text('Guardar en dispositivo'.tr),
                  onTap: () => Navigator.pop(context, 'save'),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return;

      if (choice == 'share') {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/recetas_full_backup.json');
        await file.writeAsString(jsonStr);

        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Copia de seguridad completa de Recetas',
          ),
        );

        if (result.status == ShareResultStatus.success && mounted) {
          SnackbarService.showMessage('Copia de seguridad compartida'.tr);
        }
      } else if (choice == 'save') {
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar copia de seguridad',
          fileName: 'recetas_full_backup.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );

        if (outputFile != null && mounted) {
          SnackbarService.showMessage('Datos guardados exitosamente'.tr);
        }
      }
    } catch (e) {
      if (mounted) SnackbarService.showError('${'Error al exportar'.tr}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _showImportSelection(Map<String, dynamic> data) async {
    bool impSettings = true;
    bool impRecipes = true;
    bool impMeals = true;
    bool impShopping = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Selecciona qué importar'.tr),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Los datos importados se añadirán a los actuales. Las recetas o plantillas existentes no se sobrescribirán.'.tr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text('Ajustes y Perfil'.tr),
                      value: impSettings,
                      onChanged: (v) => setDialogState(() => impSettings = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('Recetas y Carpetas'.tr),
                      value: impRecipes,
                      onChanged: (v) => setDialogState(() => impRecipes = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('Planificador y Plantillas'.tr),
                      value: impMeals,
                      onChanged: (v) => setDialogState(() => impMeals = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('Lista de la compra'.tr),
                      value: impShopping,
                      onChanged: (v) => setDialogState(() => impShopping = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar'.tr),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Importar'.tr),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return null;

    final recipeKeys = {
      'saved_recipes',
      'favorite_recipes',
      'favorite_folders',
      'custom_ingredient_mappings',
      'custom_recipe_images',
    };
    final mealKeys = {'planned_meals', 'meal_templates'};
    final shoppingKeys = {
      'shopping_checked_items',
      'shopping_manual_items',
      'shopping_days_ahead',
      'shopping_bought_until',
    };

    final filteredData = Map<String, dynamic>.from(data);

    if (!impRecipes) {
      for (var key in recipeKeys) filteredData.remove(key);
    }
    if (!impMeals) {
      for (var key in mealKeys) filteredData.remove(key);
    }
    if (!impShopping) {
      for (var key in shoppingKeys) filteredData.remove(key);
    }
    if (!impSettings) {
      filteredData.remove('secure_storage');
      final nonSettingsKeys = [...recipeKeys, ...mealKeys, ...shoppingKeys, '_version', '_timestamp'];
      final allKeys = filteredData.keys.toList();
      for (var key in allKeys) {
        if (!nonSettingsKeys.contains(key)) filteredData.remove(key);
      }
    }

    return filteredData;
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);

        if (data is! Map<String, dynamic>) {
          throw Exception('Formato de archivo inválido'.tr);
        }

        setState(() => _isLoading = false);
        final filteredData = await _showImportSelection(data);
        if (filteredData == null) return;
        setState(() => _isLoading = true);

        await DataManagementService.importAllData(filteredData);
        if (mounted) {
          SnackbarService.showMessage('Datos restaurados exitosamente'.tr);
        }
      }
    } catch (e) {
      if (mounted) SnackbarService.showError('${'Error al importar'.tr}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar todos los datos?'.tr),
        content: Text(
          'Esta acción no se puede deshacer. Perderás todas tus recetas, planificaciones, configuraciones y perfil físico.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Borrar'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Estás absolutamente seguro?'.tr),
          content: Text('Por favor confirma por última vez.'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Borrar'.tr),
            ),
          ],
        ),
      );

      if (confirm2 == true) {
        setState(() => _isLoading = true);
        await DataManagementService.clearAllData();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
            (route) => false,
          );
        }
      }
    }
  }

  Future<void> _restoreBackup(File file) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      final filteredData = await _showImportSelection(data);
      if (filteredData == null) return;

      setState(() => _isLoading = true);
      await DataManagementService.importAllData(filteredData);
      if (mounted) SnackbarService.showMessage('Copia restaurada exitosamente'.tr);
    } catch (e) {
      if (mounted) SnackbarService.showError('${'Error al restaurar'.tr}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Gestión de Datos'.tr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('COPIAS MANUALES'.tr, theme),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(CupertinoIcons.share),
                        title: Text('Exportar todos los datos'.tr),
                        onTap: _exportData,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(CupertinoIcons.arrow_down_doc),
                        title: Text('Importar datos'.tr),
                        onTap: _importData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('COPIAS AUTOMÁTICAS (LOCALES)'.tr, theme),
                ValueListenableBuilder<String>(
                  valueListenable: SettingsManager.autoBackupFrequency,
                  builder: (context, frequency, child) {
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(CupertinoIcons.time),
                            title: Text('Frecuencia de copia'.tr),
                            trailing: Theme(
                              data: Theme.of(context).copyWith(focusColor: Colors.transparent),
                              child: DropdownButton<String>(
                                value: frequency,
                                underline: const SizedBox(),
                                elevation: 0,
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: theme.brightness == Brightness.dark
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : theme.cardColor,
                                icon: Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                items: [
                                DropdownMenuItem(value: 'off', child: Text('Desactivado'.tr)),
                                DropdownMenuItem(value: 'daily', child: Text('Diaria'.tr)),
                                DropdownMenuItem(value: 'weekly', child: Text('Semanal'.tr)),
                                DropdownMenuItem(value: 'monthly', child: Text('Mensual'.tr)),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  SettingsManager.setAutoBackupFrequency(val);
                                }
                              },
                            ),
                            ),
                          ),
                          if (frequency != 'off') ...[

                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Contenido de la copia'.tr.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: SettingsManager.autoBackupSettings,
                              builder: (context, value, child) => SwitchListTile.adaptive(
                                title: Text('Ajustes y Perfil'.tr, style: theme.textTheme.bodyMedium),
                                value: value,
                                onChanged: (v) => SettingsManager.setAutoBackupSettings(v),
                                activeColor: theme.colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: SettingsManager.autoBackupRecipes,
                              builder: (context, value, child) => SwitchListTile.adaptive(
                                title: Text('Recetas y Carpetas'.tr, style: theme.textTheme.bodyMedium),
                                value: value,
                                onChanged: (v) => SettingsManager.setAutoBackupRecipes(v),
                                activeColor: theme.colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: SettingsManager.autoBackupMeals,
                              builder: (context, value, child) => SwitchListTile.adaptive(
                                title: Text('Planificador y Plantillas'.tr, style: theme.textTheme.bodyMedium),
                                value: value,
                                onChanged: (v) => SettingsManager.setAutoBackupMeals(v),
                                activeColor: theme.colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: SettingsManager.autoBackupShopping,
                              builder: (context, value, child) => SwitchListTile.adaptive(
                                title: Text('Lista de la compra'.tr, style: theme.textTheme.bodyMedium),
                                value: value,
                                onChanged: (v) => SettingsManager.setAutoBackupShopping(v),
                                activeColor: theme.colorScheme.primary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                visualDensity: VisualDensity.compact,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                          if (_backups.isNotEmpty) ...[

                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Restaurar copia automática'.tr.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ..._backups.map((file) {
                              final name = file.path.split('/').last.split('\\').last;
                              return ListTile(
                                leading: Icon(CupertinoIcons.doc_text, color: theme.colorScheme.primary),
                                title: Text(name.replaceAll('.json', '').replaceAll('backup_', 'Backup ')),
                                trailing: const Icon(CupertinoIcons.refresh),
                                onTap: () => _restoreBackup(file),
                              );
                            }),
                          ]
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('PELIGRO'.tr, theme),
                Card(
                  elevation: 0,
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.delete, color: Colors.red),
                    title: Text(
                      'Borrar todos los datos'.tr,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    onTap: _clearData,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
