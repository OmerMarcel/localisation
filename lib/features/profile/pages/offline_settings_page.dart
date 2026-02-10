import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';

class OfflineSettingsPage extends StatefulWidget {
  const OfflineSettingsPage({super.key});

  @override
  State<OfflineSettingsPage> createState() => _OfflineSettingsPageState();
}

class _OfflineSettingsPageState extends State<OfflineSettingsPage> {
  final StorageService _storageService = StorageService();
  final double _maxCacheSize = 100.0; // MB

  double _cacheSize = 0.0;
  bool _autoDownload = false;
  bool _wifiOnly = true;
  bool _isLoading = true;
  Map<String, double> _storageDetails = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _calculateCacheSize();
  }

  Future<void> _loadSettings() async {
    await _storageService.init();
    setState(() {
      _autoDownload = _storageService.isAutoDownloadEnabled();
      _wifiOnly = _storageService.isWifiOnlyEnabled();
    });
  }

  Future<void> _calculateCacheSize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculer la taille des données stockées dans SharedPreferences
      double storedDataSize = _storageService.getStoredDataSize();

      // Calculer la taille des fichiers temporaires
      double tempCacheSize = 0.0;
      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          tempCacheSize = await _getDirectorySize(tempDir);
        }
      } catch (e) {
        print('Erreur calcul taille cache temporaire: $e');
      }

      // Calculer la taille des documents de l'application
      double appDataSize = 0.0;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        if (appDir.existsSync()) {
          appDataSize = await _getDirectorySize(appDir);
        }
      } catch (e) {
        print('Erreur calcul taille données app: $e');
      }

      // Taille totale en MB
      final totalSize = storedDataSize + tempCacheSize + appDataSize;

      // Récupérer les détails de stockage
      _storageDetails = _storageService.getStorageDetails();
      _storageDetails['Cache temporaire'] = tempCacheSize;
      _storageDetails['Données application'] = appDataSize;

      setState(() {
        _cacheSize = totalSize;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur calcul taille cache: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<double> _getDirectorySize(Directory dir) async {
    double size = 0.0;
    try {
      if (dir.existsSync()) {
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              size += await entity.length();
            } catch (e) {
              // Ignorer les fichiers inaccessibles
            }
          }
        }
      }
    } catch (e) {
      print('Erreur calcul taille répertoire: $e');
    }
    // Convertir en MB
    return size / (1024 * 1024);
  }

  String _formatSize(double sizeInMB) {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Données hors ligne')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _calculateCacheSize,
            child: ListView(
              padding: EdgeInsets.only(
                left: AppDimensions.spacingM,
                right: AppDimensions.spacingM,
                top: AppDimensions.spacingM,
                bottom: AppDimensions.spacingM + 60,
              ),
              children: [_buildStorageSection(), _buildSettingsSection()],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(1),
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    final percentage = _cacheSize > _maxCacheSize
        ? 100
        : (_cacheSize / _maxCacheSize * 100).round();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stockage local', style: AppTextStyles.h4),
            SizedBox(height: AppDimensions.spacingM),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: AppColors.primary),
                      SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espace utilisé: ${_formatSize(_cacheSize)} / ${_maxCacheSize.toInt()} MB',
                            ),
                            SizedBox(height: AppDimensions.spacingS),
                            LinearProgressIndicator(
                              value: _cacheSize > _maxCacheSize
                                  ? 1.0
                                  : _cacheSize / _maxCacheSize,
                              backgroundColor: AppColors.textSecondary
                                  .withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage > 80
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('$percentage%'),
                    ],
                  ),
                  SizedBox(height: AppDimensions.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cacheSize > 0
                              ? _showClearCacheDialog
                              : null,
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Vider le cache'),
                        ),
                      ),
                      SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showStorageDetails,
                          icon: const Icon(Icons.info),
                          label: const Text('Détails'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      margin: EdgeInsets.only(top: AppDimensions.spacingM),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paramètres de cache', style: AppTextStyles.h4),
            SizedBox(height: AppDimensions.spacingXs),
            SwitchListTile(
              title: const Text('Cache automatique'),
              subtitle: const Text(
                'Sauvegarder automatiquement les données consultées',
              ),
              value: _autoDownload,
              onChanged: (value) async {
                setState(() {
                  _autoDownload = value;
                });
                await _storageService.setAutoDownloadEnabled(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Cache automatique activé'
                          : 'Cache automatique désactivé',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              secondary: Icon(Icons.cached, color: AppColors.primary),
            ),
            SwitchListTile(
              title: const Text('Wi-Fi uniquement'),
              subtitle: const Text(
                'Utiliser le Wi-Fi pour les téléchargements de gros fichiers',
              ),
              value: _wifiOnly,
              onChanged: (value) async {
                setState(() {
                  _wifiOnly = value;
                });
                await _storageService.setWifiOnlyEnabled(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Téléchargements Wi-Fi uniquement activés'
                          : 'Téléchargements sur toutes les connexions activés',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              secondary: Icon(Icons.wifi, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text(
          'Êtes-vous sûr de vouloir vider le cache ?\n\nCela supprimera les données temporaires et les données hors ligne. L\'application redémarrera après le nettoyage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearCacheAndRestart();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Vider et Redémarrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCacheAndRestart() async {
    try {
      // Affiche un message pendant le nettoyage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nettoyage du cache en cours...')),
        );
      }

      // Supprimer les données hors ligne (mais garder les favoris et le profil)
      await _storageService.saveOfflineData([]);

      // Supprimer les recherches récentes
      await _storageService.clearRecentSearches();

      // Vider le répertoire de cache temporaire
      try {
        final cacheDir = await getTemporaryDirectory();
        if (cacheDir.existsSync()) {
          await cacheDir.delete(recursive: true);
        }
      } catch (e) {
        print('Erreur suppression cache temporaire: $e');
      }

      // Vider le répertoire de documents de l'application (sauf les données importantes)
      try {
        final appDir = await getApplicationDocumentsDirectory();
        if (appDir.existsSync()) {
          // Ne supprimer que les fichiers temporaires, pas tout le répertoire
          // car il peut contenir des données importantes
          final files = appDir.listSync();
          for (final file in files) {
            if (file is File) {
              try {
                await file.delete();
              } catch (e) {
                // Ignorer les fichiers qui ne peuvent pas être supprimés
              }
            }
          }
        }
      } catch (e) {
        print('Erreur nettoyage documents: $e');
      }

      // Recalculer la taille du cache
      await _calculateCacheSize();

      // Redémarre l'application après un court délai
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Phoenix.rebirth(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors du nettoyage: $e')));
      }
    }
  }

  void _showStorageDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du stockage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_storageDetails.isEmpty)
                const Text('Aucune donnée disponible')
              else
                ..._storageDetails.entries.map(
                  (entry) =>
                      _buildStorageItem(entry.key, _formatSize(entry.value)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String name, String size) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(size, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
