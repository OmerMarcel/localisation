import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';

class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> {
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

  bool _backgroundLocation = false;
  bool _locationHistory = true;
  bool _preciseLocation = true;
  bool _isLoading = true;
  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _isLocationServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _loadSettings() async {
    await _storageService.init();
    setState(() {
      _backgroundLocation = _storageService.isBackgroundLocationEnabled();
      _locationHistory = _storageService.isLocationHistoryEnabled();
      _preciseLocation = _storageService.isPreciseLocationEnabled();
    });
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si le service de localisation est activé
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      // Vérifier le statut des permissions
      final permission = await Geolocator.checkPermission();

      setState(() {
        _permissionStatus = permission;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur vérification permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPermissionStatusText() {
    switch (_permissionStatus) {
      case LocationPermission.denied:
        return 'Non autorisée';
      case LocationPermission.deniedForever:
        return 'Refusée définitivement';
      case LocationPermission.whileInUse:
        return 'Autorisée (en cours d\'utilisation)';
      case LocationPermission.always:
        return 'Autorisée (toujours)';
      default:
        return 'Inconnu';
    }
  }

  Color _getPermissionStatusColor() {
    switch (_permissionStatus) {
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        return AppColors.error;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getPermissionStatusIcon() {
    switch (_permissionStatus) {
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        return Icons.location_off;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _requestLocationPermission() async {
    if (!_isLocationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez activer le service de localisation dans les paramètres',
          ),
        ),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    final hasPermission = await _locationService.requestLocationPermission();

    if (hasPermission) {
      // Demander la permission en arrière-plan si nécessaire
      if (_backgroundLocation) {
        final permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pour utiliser la localisation en arrière-plan, veuillez autoriser "Toujours" dans les paramètres',
              ),
            ),
          );
          await openAppSettings();
        }
      }
    }

    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres de localisation')),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              left: AppDimensions.spacingM,
              right: AppDimensions.spacingM,
              top: AppDimensions.spacingM,
              bottom: 100, // Espace pour le menu simulé
            ),
            children: [
              _buildPermissionsSection(),
              _buildSettingsSection(),
              _buildPrivacySection(),
            ],
          ),
          // Dégradé pour simuler un menu de navigation en bas
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
                    Colors.white,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingM),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Autorisations', style: AppTextStyles.h4),
            SizedBox(height: AppDimensions.spacingXs),
            ListTile(
              leading: Icon(
                _getPermissionStatusIcon(),
                color: _getPermissionStatusColor(),
              ),
              title: const Text('Localisation'),
              subtitle: Text(_getPermissionStatusText()),
              trailing:
                  _permissionStatus == LocationPermission.denied ||
                      _permissionStatus == LocationPermission.deniedForever
                  ? TextButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('Autoriser'),
                    )
                  : Icon(
                      Icons.check_circle,
                      color: _getPermissionStatusColor(),
                    ),
              onTap:
                  _permissionStatus == LocationPermission.denied ||
                      _permissionStatus == LocationPermission.deniedForever
                  ? _requestLocationPermission
                  : null,
            ),
            ListTile(
              leading: Icon(Icons.gps_fixed, color: AppColors.primary),
              title: const Text('GPS haute précision'),
              subtitle: Text(_preciseLocation ? 'Activé' : 'Désactivé'),
              trailing: Switch(
                value: _preciseLocation,
                onChanged: (value) async {
                  setState(() {
                    _preciseLocation = value;
                  });
                  await _storageService.setPreciseLocationEnabled(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'GPS haute précision activé'
                            : 'GPS haute précision désactivé',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
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
            Text('Paramètres', style: AppTextStyles.h4),
            SizedBox(height: AppDimensions.spacingXs),
            SwitchListTile(
              title: const Text('Localisation en arrière-plan'),
              subtitle: const Text('Pour les notifications de proximité'),
              value: _backgroundLocation,
              onChanged: (value) async {
                if (value) {
                  // Vérifier les permissions avant d'activer
                  final permission = await Geolocator.checkPermission();
                  if (permission != LocationPermission.always) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La localisation en arrière-plan nécessite la permission "Toujours". Veuillez l\'autoriser dans les paramètres.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                    await openAppSettings();
                    await _checkPermissions();
                    return;
                  }
                }

                setState(() {
                  _backgroundLocation = value;
                });
                await _storageService.setBackgroundLocationEnabled(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Localisation en arrière-plan activée'
                          : 'Localisation en arrière-plan désactivée',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              secondary: Icon(Icons.my_location, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    final historyCount = _storageService.getLocationHistory().length;

    return Card(
      margin: EdgeInsets.only(top: AppDimensions.spacingM),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidentialité', style: AppTextStyles.h4),
            SizedBox(height: AppDimensions.spacingXs),
            SwitchListTile(
              title: const Text('Historique des positions'),
              subtitle: Text(
                _locationHistory
                    ? '$historyCount positions enregistrées'
                    : 'Historique désactivé',
              ),
              value: _locationHistory,
              onChanged: (value) async {
                setState(() {
                  _locationHistory = value;
                });
                await _storageService.setLocationHistoryEnabled(value);

                if (!value) {
                  // Si on désactive, on peut proposer de supprimer l'historique
                  _showDisableHistoryDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Historique des positions activé'),
                    ),
                  );
                }
              },
              secondary: Icon(Icons.history, color: AppColors.primary),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.error),
              title: const Text('Supprimer l\'historique'),
              subtitle: Text(
                historyCount > 0
                    ? '$historyCount positions seront supprimées'
                    : 'Aucune donnée à supprimer',
              ),
              onTap: historyCount > 0 ? _showDeleteHistoryDialog : null,
            ),
            ListTile(
              leading: Icon(Icons.download, color: AppColors.primary),
              title: const Text('Exporter les données'),
              subtitle: Text(
                historyCount > 0
                    ? 'Exporter $historyCount positions'
                    : 'Aucune donnée à exporter',
              ),
              onTap: historyCount > 0 ? _exportLocationData : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showDisableHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver l\'historique'),
        content: const Text(
          'Voulez-vous également supprimer toutes les positions déjà enregistrées ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Garder les données'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService.clearLocationHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historique supprimé')),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteHistoryDialog() {
    final historyCount = _storageService.getLocationHistory().length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'historique'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer les $historyCount positions enregistrées ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService.clearLocationHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historique supprimé')),
                );
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLocationData() async {
    try {
      final history = _storageService.getLocationHistory();

      if (history.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune donnée à exporter')),
        );
        return;
      }

      // Afficher un message de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export des données en cours...')),
        );
      }

      // Formater les données en JSON
      final jsonData = jsonEncode({
        'export_date': DateTime.now().toIso8601String(),
        'total_locations': history.length,
        'locations': history,
      });

      // Créer un fichier texte lisible
      final StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('Date,Latitude,Longitude');
      for (final location in history) {
        final timestamp = DateTime.parse(location['timestamp']);
        csvBuffer.writeln(
          '${timestamp.toIso8601String()},${location['latitude']},${location['longitude']}',
        );
      }

      // Partager les données
      await Share.share(
        'Données de localisation exportées\n\n'
        'Total: ${history.length} positions\n\n'
        'Format JSON:\n$jsonData\n\n'
        'Format CSV:\n${csvBuffer.toString()}',
        subject: 'Export données de localisation',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${history.length} positions exportées avec succès'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
      }
    }
  }
}
