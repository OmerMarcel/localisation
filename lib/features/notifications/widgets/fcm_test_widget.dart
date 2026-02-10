import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../services/fcm_service.dart';
import '../services/notification_initializer.dart';

class FCMTestWidget extends ConsumerStatefulWidget {
  const FCMTestWidget({super.key});

  @override
  ConsumerState<FCMTestWidget> createState() => _FCMTestWidgetState();
}

class _FCMTestWidgetState extends ConsumerState<FCMTestWidget> {
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() => _isLoading = true);
    try {
      final token = await NotificationInitializer.getDeviceToken();
      setState(() => _token = token);
    } catch (e) {
      _showError('Erreur lors du chargement du token: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);
    try {
      await NotificationInitializer.testNotifications();
      _showSuccess('Notification de test envoyée !');
    } catch (e) {
      _showError('Erreur lors de l\'envoi: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _subscribeToTopic() async {
    final topic = await _showTopicDialog();
    if (topic != null && topic.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await FCMService.subscribeToTopic(topic);
        _showSuccess('Abonné au topic: $topic');
      } catch (e) {
        _showError('Erreur abonnement: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showTopicDialog() async {
    String? topic;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('S\'abonner à un topic'),
        content: TextField(
          onChanged: (value) => topic = value,
          decoration: const InputDecoration(
            hintText: 'Nom du topic (ex: cotonou_test)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, topic),
            child: const Text('S\'abonner'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(AppDimensions.spacingM),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion FCM',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
            SizedBox(height: AppDimensions.spacingM),

            // Token FCM
            if (_token != null) ...[
              Text(
                'Token FCM:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppDimensions.spacingS),
              Container(
                padding: EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  _token!,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: AppDimensions.spacingM),
            ],

            // Boutons d'action
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer notification test'),
                ),
              ),
              SizedBox(height: AppDimensions.spacingS),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _subscribeToTopic,
                  icon: const Icon(Icons.topic),
                  label: const Text('S\'abonner à un topic'),
                ),
              ),
              SizedBox(height: AppDimensions.spacingS),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadToken,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recharger token'),
                ),
              ),
            ],

            SizedBox(height: AppDimensions.spacingM),

            // Informations
            Container(
              padding: EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Informations FCM',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingS),
                  Text(
                    '• Le token FCM identifie votre appareil de manière unique\n'
                    '• Utilisez-le pour envoyer des notifications ciblées\n'
                    '• Les topics permettent d\'envoyer des notifications à des groupes\n'
                    '• Testez avec Firebase Console ou votre backend',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
