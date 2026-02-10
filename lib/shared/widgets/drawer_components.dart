import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isSelected;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isSelected = false,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? (isSelected ? AppColors.primary : AppColors.textSecondary);
    final effectiveTextColor =
        textColor ?? (isSelected ? AppColors.primary : AppColors.textPrimary);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: effectiveIconColor,
          size: AppDimensions.iconL,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: effectiveTextColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }
}

class CustomDrawerHeader extends StatelessWidget {
  final String userName;
  final String? userEmail;
  final String? userAvatar;
  final VoidCallback? onProfileTap;

  const CustomDrawerHeader({
    super.key,
    this.userName = 'Utilisateur',
    this.userEmail,
    this.userAvatar,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: AppColors.textLight.withOpacity(0.2),
                      backgroundImage: userAvatar != null
                          ? NetworkImage(userAvatar!)
                          : null,
                      child: userAvatar == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.textLight,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (userEmail != null) ...[
                          SizedBox(height: AppDimensions.spacingXs),
                          Text(
                            userEmail!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showDivider;

  const DrawerSection({
    super.key,
    required this.title,
    required this.children,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          Divider(
            color: AppColors.textSecondary.withOpacity(0.2),
            thickness: 1,
            height: 1,
          ),
        SizedBox(height: AppDimensions.spacingM),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingS),
        ...children,
        SizedBox(height: AppDimensions.spacingM),
      ],
    );
  }
}

class QuickStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const QuickStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXs,
      ),
      padding: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconM),
          SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h4.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
