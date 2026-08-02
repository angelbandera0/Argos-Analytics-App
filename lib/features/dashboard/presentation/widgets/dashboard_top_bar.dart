import 'package:flutter/material.dart';

import '../../../../core/auth/app_role.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Slim bar on top of every `/dashboard/*` screen: the sidebar
/// show/hide toggle (always available, on every layout — desktop can
/// collapse it for more room, mobile/tablet-portrait use it to open the
/// drawer) plus the current user + logout.
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthSession.instance,
      builder: (context, _) {
        final user = AuthSession.instance.currentUser;
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Mostrar/ocultar menú',
                onPressed: onMenuTap,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Argos Analytics', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (user != null) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user.name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    Text(user.role.label, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textMuted),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => AuthSession.instance.logout(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
