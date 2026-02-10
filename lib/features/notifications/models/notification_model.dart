enum NotificationType { infrastructure, proximity, system, update, alert }

enum NotificationPriority { low, normal, high }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final NotificationPriority priority;
  final Map<String, dynamic>? actionData;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
    this.actionData,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    NotificationPriority? priority,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      actionData: actionData ?? this.actionData,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${json['priority']}',
        orElse: () => NotificationPriority.normal,
      ),
      actionData: json['actionData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'priority': priority.toString().split('.').last,
      'actionData': actionData,
    };
  }
}

// Extension pour créer des notifications facilement
extension NotificationModelExtension on NotificationModel {
  static NotificationModel createInfrastructureNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.infrastructure,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: actionData,
    );
  }

  static NotificationModel createProximityNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.proximity,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: actionData,
    );
  }

  static NotificationModel createSystemNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.system,
      timestamp: DateTime.now(),
      priority: priority,
    );
  }

  static NotificationModel createUpdateNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.update,
      timestamp: DateTime.now(),
      priority: priority,
    );
  }

  static NotificationModel createAlertNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.high,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.alert,
      timestamp: DateTime.now(),
      priority: priority,
      actionData: actionData,
    );
  }
}
