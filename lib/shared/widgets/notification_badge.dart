import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(badgeSize ?? 10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: BoxConstraints(
                minWidth: badgeSize ?? 16,
                minHeight: badgeSize ?? 16,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: (badgeSize ?? 16) * 0.6,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? iconSize;

  const NotificationIcon({
    super.key,
    required this.unreadCount,
    this.onPressed,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      count: unreadCount,
      child: IconButton(
        icon: Icon(Icons.notifications, color: iconColor, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }
}
