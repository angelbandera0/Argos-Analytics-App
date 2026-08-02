import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/app_role.dart';
import '../../../../core/auth/app_user.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/mock_users_repository.dart';
import '../../../../core/auth/module_registry.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Left navigation: a thin icon rail plus a wider contextual panel.
///
/// Everything renders from [kAppModules]/[kBottomRailModules] (the
/// single source of truth also used by the permission matrix), filtered
/// live against [AuthSession.instance]'s current user — a module only
/// shows up if the user has read access to at least one of its options,
/// and only the options they can read appear inside the panel. SuperAdmin
/// always sees everything.
class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key, required this.currentPath, this.onNavigate});

  final String currentPath;

  /// Called after any navigation triggered from the sidebar — used by
  /// [DashboardShell] to auto-close the drawer on mobile/tablet portrait.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthSession.instance,
      builder: (context, _) {
        final user = AuthSession.instance.currentUser;
        final topModules = kAppModules.where((m) => _moduleVisible(m, user)).toList();
        final bottomModules = kBottomRailModules.where((m) => _moduleVisible(m, user)).toList();
        final active = _resolveActiveModule([...topModules, ...bottomModules], currentPath);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IconRail(
              topModules: topModules,
              bottomModules: bottomModules,
              activeModuleId: active?.id,
              onNavigate: onNavigate,
            ),
            Container(width: 1, color: AppColors.border),
            if (active != null && user != null)
              _SectionPanel(module: active, currentPath: currentPath, user: user, onNavigate: onNavigate)
            else
              const SizedBox(width: 267),
          ],
        );
      },
    );
  }
}

bool _moduleVisible(AppModule module, AppUser? user) {
  if (user == null) return false;
  if (user.role.hasUnrestrictedAccess) return true;
  return user.permissions.any((p) => p.moduleId == module.id && p.canRead);
}

bool _optionVisible(String moduleId, ModuleOption option, AppUser? user) {
  if (user == null) return false;
  if (user.role.hasUnrestrictedAccess) return true;
  return user.permissions.any((p) => p.moduleId == moduleId && p.optionId == option.id && p.canRead);
}

/// Finds which visible module "owns" the current route, so its rail icon
/// highlights and its panel is the one shown. Falls back to the first
/// visible module (varies per role) when nothing matches exactly.
AppModule? _resolveActiveModule(List<AppModule> modules, String currentPath) {
  final segment = currentPath.startsWith('/dashboard/') ? currentPath.substring('/dashboard/'.length) : '';

  for (final module in modules) {
    for (final option in module.options) {
      if (segment == option.path.replaceFirst('/dashboard/', '')) return module;
    }
    if (module.extraMatchPrefixes.any((p) => segment == p || segment.startsWith('$p-'))) return module;
  }
  return modules.isEmpty ? null : modules.first;
}

class _IconRail extends StatelessWidget {
  const _IconRail({required this.topModules, required this.bottomModules, required this.activeModuleId, required this.onNavigate});

  final List<AppModule> topModules;
  final List<AppModule> bottomModules;
  final String? activeModuleId;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          for (final m in topModules) _RailButton(module: m, active: m.id == activeModuleId, onNavigate: onNavigate),
          const Spacer(),
          for (final m in bottomModules) _RailButton(module: m, active: m.id == activeModuleId, onNavigate: onNavigate),
          const SizedBox(height: AppSpacing.md),
          const CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 18)),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.module, required this.active, required this.onNavigate});
  final AppModule module;
  final bool active;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: module.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            context.go(module.railPath);
            onNavigate?.call();
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(module.icon, size: 20, color: active ? AppColors.textOnPrimary : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.module, required this.currentPath, required this.user, required this.onNavigate});

  final AppModule module;
  final String currentPath;
  final AppUser user;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final visibleOptions = module.options.where((o) => _optionVisible(module.id, o, user)).toList();
    final managed = usersManagedBy(user);

    return Container(
      width: 267,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(module.label, key: ValueKey(module.id), style: AppTextStyles.h3),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Column(
              key: ValueKey(module.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final option in visibleOptions)
                  _NavTile(option: option, active: currentPath == option.path, onNavigate: onNavigate),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(user.role.managedRole == null ? 'Equipo' : '${user.role.managedRole!.label}s a cargo', style: AppTextStyles.label),
              if (managed.isNotEmpty && _optionVisible('nomencladores', const ModuleOption(id: 'usuarios', label: '', path: '', icon: Icons.people), user))
                InkWell(
                  onTap: () {
                    context.go('/dashboard/usuarios');
                    onNavigate?.call();
                  },
                  child: Text('View All', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (managed.isEmpty)
            Text(
              user.role == AppRole.trabajador ? 'No gestionas otros usuarios.' : 'Aún no hay usuarios a tu cargo.',
              style: AppTextStyles.caption,
            )
          else
            for (final m in managed.take(3)) _MemberTile(name: m.name, role: m.role.label, active: m.active),
          const Spacer(),
          _PromoCard(),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.option, required this.active, required this.onNavigate});
  final ModuleOption option;
  final bool active;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: active ? AppColors.surfaceSunken : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            context.go(option.path);
            onNavigate?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(option.icon, size: 18, color: active ? AppColors.ink : AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    option.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: active ? AppColors.ink : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.name, required this.role, required this.active});
  final String name;
  final String role;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                Text(role, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '5 Ways To Improve Team Workflow',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('7 min read', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.ink),
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('Read Post'), SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 16)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
