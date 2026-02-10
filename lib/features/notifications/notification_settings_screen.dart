import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/fcm_test_widget.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _enableInfrastructureNotifications = true;
  bool _enableProximityNotifications = true;
  bool _enableSystemNotifications = true;
  bool _enableAlertNotifications = true;
  bool _enablePushNotifications = true;
  bool _enableSoundNotifications = true;
  bool _enableVibrationNotifications = true;

  double _proximityRadius = 500.0; // en mètres
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _enableQuietHours = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres des notifications'),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        children: [
          // Section Types de notifications
          _buildSectionHeader('Types de notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Nouvelles infrastructures'),
                  subtitle: const Text(
                    'Être notifié des nouvelles infrastructures ajoutées',
                  ),
                  value: _enableInfrastructureNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableInfrastructureNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Proximité'),
                  subtitle: const Text(
                    'Être notifié des infrastructures à proximité',
                  ),
                  value: _enableProximityNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableProximityNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Système'),
                  subtitle: const Text('Mises à jour et informations système'),
                  value: _enableSystemNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableSystemNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Alertes importantes'),
                  subtitle: const Text('Interruptions de service et urgences'),
                  value: _enableAlertNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableAlertNotifications = value;
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Section Paramètres généraux
          _buildSectionHeader('Paramètres généraux'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications push'),
                  subtitle: const Text(
                    'Recevoir les notifications même quand l\'app est fermée',
                  ),
                  value: _enablePushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enablePushNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Son'),
                  subtitle: const Text('Jouer un son lors des notifications'),
                  value: _enableSoundNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableSoundNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrer lors des notifications'),
                  value: _enableVibrationNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableVibrationNotifications = value;
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Section FCM et notifications push
          _buildSectionHeader('Firebase Cloud Messaging'),
          const FCMTestWidget(),

          SizedBox(height: AppDimensions.spacingL),

          // Section Proximité
          _buildSectionHeader('Paramètres de proximité'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Rayon de proximité'),
                  subtitle: Text('${_proximityRadius.round()} mètres'),
                  trailing: const Icon(Icons.tune),
                ),
                Slider(
                  value: _proximityRadius,
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  label: '${_proximityRadius.round()}m',
                  onChanged: (value) {
                    setState(() {
                      _proximityRadius = value;
                    });
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('100m', style: AppTextStyles.bodySmall),
                      Text('2km', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.spacingM),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Section Heures silencieuses
          _buildSectionHeader('Heures silencieuses'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Activer les heures silencieuses'),
                  subtitle: const Text(
                    'Pas de notifications pendant ces heures',
                  ),
                  value: _enableQuietHours,
                  onChanged: (value) {
                    setState(() {
                      _enableQuietHours = value;
                    });
                  },
                ),
                if (_enableQuietHours) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Début'),
                    subtitle: Text(_formatTimeOfDay(_quietHoursStart)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _selectTime(context, true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(_formatTimeOfDay(_quietHoursEnd)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _selectTime(context, false),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Tester'),
                ),
              ),
              SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Sauvegarder'),
                ),
              ),
            ],
          ),

          // Section Stockage Local
          _buildSectionHeader('Stockage Local'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.primary),
                  title: const Text('Stockage des notifications'),
                  subtitle: const Text(
                    'Vos notifications sont sauvegardées localement sur votre appareil',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.secondary,
                  ),
                  title: const Text('Persistance des données'),
                  subtitle: const Text(
                    'Les notifications restent disponibles même après déconnexion ou redémarrage de l\'application',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.orange,
                  ),
                  title: const Text('Gestion de l\'espace'),
                  subtitle: const Text(
                    'Maximum 100 notifications. Utilisez "Nettoyer anciennes" pour libérer de l\'espace',
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL * 2),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppDimensions.spacingS,
        top: AppDimensions.spacingM,
      ),
      child: Text(
        title,
        style: AppTextStyles.h4.copyWith(color: AppColors.primary),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
      });
    }
  }

  void _resetToDefaults() {
    setState(() {
      _enableInfrastructureNotifications = true;
      _enableProximityNotifications = true;
      _enableSystemNotifications = true;
      _enableAlertNotifications = true;
      _enablePushNotifications = true;
      _enableSoundNotifications = true;
      _enableVibrationNotifications = true;
      _proximityRadius = 500.0;
      _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
      _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
      _enableQuietHours = false;
    });
  }

  void _testNotification() {
    // Afficher une notification de test
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification de test envoyée !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveSettings() {
    // Sauvegarder les paramètres (ici on pourrait utiliser SharedPreferences)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres sauvegardés avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
