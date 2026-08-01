import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Left navigation: a thin icon rail plus the wider contextual panel.
///
/// The panel content depends on which rail icon is active: each
/// [_SidebarSection] owns its own list of options, and only the section
/// matching the current route is shown — exactly like "Projects" only
/// belongs to the Board icon. Selecting any option navigates to its own
/// route, which renders the matching "coming soon" screen (or the real
/// board for Publications).
class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final activeSection = _resolveActiveSection(currentPath);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IconRail(activeSectionId: activeSection.id),
        Container(width: 1, color: AppColors.border),
        _SectionPanel(section: activeSection, currentPath: currentPath),
      ],
    );
  }
}

/// A single navigable option shown inside the contextual panel.
class _NavEntry {
  const _NavEntry(this.icon, this.label, this.path);
  final IconData icon;
  final String label;
  final String path;
}

/// One rail icon + everything it owns: its own panel title and its own
/// list of options. `matchPrefixes` decides when this section should be
/// considered "active" (and therefore highlighted + shown in the panel)
/// for a given route.
class _SidebarSection {
  const _SidebarSection({
    required this.id,
    required this.icon,
    required this.label,
    required this.items,
    required this.matchPrefixes,
  });

  final String id;
  final IconData icon;
  final String label;
  final List<_NavEntry> items;
  final List<String> matchPrefixes;

  /// Route used when the rail icon itself is tapped: always the first
  /// option of the section.
  String get railPath => items.first.path;
}

const List<_SidebarSection> _railSections = [
  _SidebarSection(
    id: 'home',
    icon: Icons.home_rounded,
    label: 'Home',
    matchPrefixes: ['home'],
    items: [
      _NavEntry(Icons.grid_view_rounded, 'Overview', '/dashboard/home'),
      _NavEntry(Icons.timeline_rounded, 'Recent Activity', '/dashboard/home-activity'),
      _NavEntry(Icons.bolt_rounded, 'Shortcuts', '/dashboard/home-shortcuts'),
    ],
  ),
  _SidebarSection(
    id: 'chat',
    icon: Icons.chat_bubble_rounded,
    label: 'Chat',
    matchPrefixes: ['chat'],
    items: [
      _NavEntry(Icons.forum_rounded, 'All Messages', '/dashboard/chat'),
      _NavEntry(Icons.tag_rounded, 'Channels', '/dashboard/chat-channels'),
      _NavEntry(Icons.alternate_email_rounded, 'Mentions', '/dashboard/chat-mentions'),
    ],
  ),
  _SidebarSection(
    id: 'board',
    icon: Icons.dashboard_rounded,
    label: 'Projects',
    matchPrefixes: ['board', 'publications', 'campaigns', 'topics', 'planning', 'design-internal', 'development'],
    items: [
      _NavEntry(Icons.campaign_rounded, 'Campaigns', '/dashboard/campaigns'),
      _NavEntry(Icons.menu_book_rounded, 'Publications', '/dashboard/board'),
      _NavEntry(Icons.topic_rounded, 'Topics', '/dashboard/topics'),
      _NavEntry(Icons.event_note_rounded, 'Planning', '/dashboard/planning'),
      _NavEntry(Icons.design_services_rounded, 'Design Internal', '/dashboard/design-internal'),
      _NavEntry(Icons.code_rounded, 'Development', '/dashboard/development'),
    ],
  ),
  _SidebarSection(
    id: 'favorites',
    icon: Icons.favorite_rounded,
    label: 'Favorites',
    matchPrefixes: ['favorites'],
    items: [
      _NavEntry(Icons.star_rounded, 'Starred Projects', '/dashboard/favorites'),
      _NavEntry(Icons.check_circle_outline_rounded, 'Starred Tasks', '/dashboard/favorites-tasks'),
      _NavEntry(Icons.description_outlined, 'Starred Docs', '/dashboard/favorites-docs'),
    ],
  ),
  _SidebarSection(
    id: 'insights',
    icon: Icons.pie_chart_rounded,
    label: 'Insights',
    matchPrefixes: ['insights'],
    items: [
      _NavEntry(Icons.summarize_rounded, 'Reports', '/dashboard/insights'),
      _NavEntry(Icons.bar_chart_rounded, 'Analytics', '/dashboard/insights-analytics'),
      _NavEntry(Icons.space_dashboard_rounded, 'Dashboards', '/dashboard/insights-dashboards'),
    ],
  ),
  _SidebarSection(
    id: 'nomencladores',
    icon: Icons.category_rounded,
    label: 'Nomencladores',
    matchPrefixes: ['productos', 'nomencladores'],
    items: [
      _NavEntry(Icons.inventory_2_outlined, 'Productos', '/dashboard/productos'),
      _NavEntry(Icons.sell_outlined, 'Categorías', '/dashboard/nomencladores-categorias'),
      _NavEntry(Icons.local_offer_outlined, 'Marcas', '/dashboard/nomencladores-marcas'),
    ],
  ),
  _SidebarSection(
    id: 'history',
    icon: Icons.history_rounded,
    label: 'History',
    matchPrefixes: ['history'],
    items: [
      _NavEntry(Icons.restore_rounded, 'Recent Changes', '/dashboard/history'),
      _NavEntry(Icons.list_alt_rounded, 'Activity Log', '/dashboard/history-activity'),
      _NavEntry(Icons.difference_rounded, 'Version History', '/dashboard/history-versions'),
    ],
  ),
];

const List<_SidebarSection> _bottomRailSections = [
  _SidebarSection(
    id: 'notifications',
    icon: Icons.notifications_rounded,
    label: 'Notifications',
    matchPrefixes: ['notifications'],
    items: [
      _NavEntry(Icons.notifications_none_rounded, 'All', '/dashboard/notifications'),
      _NavEntry(Icons.alternate_email_rounded, 'Mentions', '/dashboard/notifications-mentions'),
      _NavEntry(Icons.system_update_alt_rounded, 'Updates', '/dashboard/notifications-updates'),
    ],
  ),
  _SidebarSection(
    id: 'settings',
    icon: Icons.settings_rounded,
    label: 'Settings',
    matchPrefixes: ['settings'],
    items: [
      _NavEntry(Icons.tune_rounded, 'General', '/dashboard/settings'),
      _NavEntry(Icons.groups_rounded, 'Team', '/dashboard/settings-team'),
      _NavEntry(Icons.receipt_long_rounded, 'Billing', '/dashboard/settings-billing'),
    ],
  ),
];

List<_SidebarSection> get _allSections => [..._railSections, ..._bottomRailSections];

/// Resolves which section owns the current route by matching the path
/// segment right after `/dashboard/` against each section's prefixes.
/// Defaults to the Projects/Board section (the app's landing area).
_SidebarSection _resolveActiveSection(String currentPath) {
  final segment = currentPath.startsWith('/dashboard/') ? currentPath.substring('/dashboard/'.length) : '';

  for (final section in _allSections) {
    final matches = section.matchPrefixes.any((prefix) => segment == prefix || segment.startsWith('$prefix-'));
    if (matches) return section;
  }
  return _railSections.firstWhere((s) => s.id == 'board');
}

class _IconRail extends StatelessWidget {
  const _IconRail({required this.activeSectionId});
  final String activeSectionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          for (final section in _railSections) _RailButton(section: section, activeSectionId: activeSectionId),
          const Spacer(),
          for (final section in _bottomRailSections) _RailButton(section: section, activeSectionId: activeSectionId),
          const SizedBox(height: AppSpacing.md),
          const CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 18)),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.section, required this.activeSectionId});
  final _SidebarSection section;
  final String activeSectionId;

  bool get _active => activeSectionId == section.id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: section.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.go(section.railPath),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              section.icon,
              size: 20,
              color: _active ? AppColors.textOnPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The contextual panel next to the rail. Its title and its list of
/// options come entirely from the currently active [_SidebarSection].
class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.section, required this.currentPath});

  final _SidebarSection section;
  final String currentPath;

  static const _members = [
    ('Liam Carter', 'Frontend Development', AppColors.primary),
    ('Mia Reynolds', 'Product Design', AppColors.statusInProgress),
    ('Chloe Turner', 'Growth Marketing', AppColors.statusReview),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title switches with a subtle fade so it's clear the
          // panel content changed together with the rail selection.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(section.label, key: ValueKey(section.id), style: AppTextStyles.h3),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Column(
              key: ValueKey(section.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final entry in section.items) _NavTile(entry: entry, active: currentPath == entry.path)],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Members', style: AppTextStyles.label),
              Text('View All', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final m in _members) _MemberTile(name: m.$1, role: m.$2, color: m.$3),
          const Spacer(),
          _PromoCard(),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.entry, required this.active});
  final _NavEntry entry;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: active ? AppColors.surfaceSunken : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => context.go(entry.path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(entry.icon, size: 18, color: active ? AppColors.ink : AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.label,
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
  const _MemberTile({required this.name, required this.role, required this.color});
  final String name;
  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.15), child: Icon(Icons.person, size: 14, color: color)),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
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
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
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
