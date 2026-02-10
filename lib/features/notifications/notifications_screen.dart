import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'models/notification_model.dart';
import 'providers/notifications_provider.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _bottomNavAnimationController;
  late Animation<Offset> _bottomNavAnimation;
  bool _isBottomNavVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bottomNavAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0)).animate(
          CurvedAnimation(
            parent: _bottomNavAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isBottomNavVisible) {
        _isBottomNavVisible = false;
        _bottomNavAnimationController.forward();
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isBottomNavVisible) {
        _isBottomNavVisible = true;
        _bottomNavAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final notificationsNotifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Toutes (${notifications.length})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle_notifications, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Non lues (${notifications.where((n) => !n.isRead).length})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active, size: 16),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Importantes',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: () {
                notificationsNotifier.markAllAsRead();
              },
              icon: const Icon(Icons.done_all, color: Colors.white70),
              label: const Text(
                'Tout marquer lu',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog(context, notificationsNotifier);
                  break;
                case 'clean_old':
                  _showCleanOldDialog(context, notificationsNotifier);
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clean_old',
                child: ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Nettoyer anciennes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text('Effacer tout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(notifications, notificationsNotifier),
          _buildNotificationsList(
            notifications.where((n) => !n.isRead).toList(),
            notificationsNotifier,
          ),
          _buildNotificationsList(
            notifications
                .where((n) => n.priority == NotificationPriority.high)
                .toList(),
            notificationsNotifier,
          ),
        ],
      ),
      bottomNavigationBar: SlideTransition(
        position: _bottomNavAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vos notifications sont sauvegardées sur votre téléphone',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    List<NotificationModel> notifications,
    NotificationsNotifier notifier,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez notifié des nouvelles infrastructures \n et services près de vous',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simuler le rechargement des notifications
        await Future.delayed(const Duration(seconds: 1));
        notifier.refreshNotifications();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: AppDimensions.spacingM,
          right: AppDimensions.spacingM,
          top: AppDimensions.spacingM,
          bottom:
              AppDimensions.spacingM + 80, // Espace pour la barre de navigation
        ),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationTile(notification, notifier);
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    NotificationModel notification,
    NotificationsNotifier notifier,
  ) {
    final isUnread = !notification.isRead;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Card(
        elevation: isUnread ? 2 : 1,
        color: isUnread ? AppColors.secondary.withOpacity(0.7) : null,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingS,
          ),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: _getNotificationColor(notification.type),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 16,
            ),
          ),
          title: Text(
            notification.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 10,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 2),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  if (notification.priority == NotificationPriority.high) ...[
                    SizedBox(width: 4),
                    Icon(Icons.priority_high, size: 10, color: Colors.red),
                    SizedBox(width: 1),
                    Text(
                      'Important',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            iconSize: 18,
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  notifier.markAsRead(notification.id);
                  break;
                case 'mark_unread':
                  notifier.markAsUnread(notification.id);
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(context, notifier, notification.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: isUnread ? 'mark_read' : 'mark_unread',
                child: ListTile(
                  leading: Icon(
                    isUnread ? Icons.mark_email_read : Icons.mark_email_unread,
                  ),
                  title: Text(
                    isUnread ? 'Marquer comme lu' : 'Marquer comme non lu',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Supprimer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          onTap: () {
            if (isUnread) {
              notifier.markAsRead(notification.id);
            }
            _showNotificationDetails(context, notification);
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.infrastructure:
        return AppColors.primary;
      case NotificationType.proximity:
        return AppColors.secondary;
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.update:
        return Colors.green;
      case NotificationType.alert:
        return Colors.orange;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.infrastructure:
        return Icons.location_on;
      case NotificationType.proximity:
        return Icons.near_me;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.update:
        return Icons.update;
      case NotificationType.alert:
        return Icons.warning;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getNotificationColor(notification.type),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(notification.title, style: AppTextStyles.h3),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 24,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(notification.message, style: AppTextStyles.bodyLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (notification.actionData != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleNotificationAction(notification);
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Voir sur la carte'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationAction(NotificationModel notification) {
    if (notification.actionData != null) {
      // Naviguer vers la carte avec les données spécifiques
      Navigator.pushNamed(context, '/map', arguments: notification.actionData);
    }
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les notifications'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les notifications de votre téléphone ? Cette action est irréversible et supprimera toutes les données locales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ Toutes les notifications ont été supprimées',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    NotificationsNotifier notifier,
    String notificationId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text(
          'Voulez-vous supprimer cette notification de votre téléphone ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.deleteNotification(notificationId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Notification supprimée'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showCleanOldDialog(
    BuildContext context,
    NotificationsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer anciennes notifications'),
        content: const Text(
          'Supprimer les notifications de plus de 30 jours pour libérer de l\'espace sur votre téléphone ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.cleanOldNotifications(daysToKeep: 30);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Anciennes notifications nettoyées'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );
  }
}
