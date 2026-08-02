import 'package:flutter/material.dart';

/// One navigable option inside a module (what the sidebar's contextual
/// panel lists, and what the permission matrix grants CRUD actions on).
class ModuleOption {
  const ModuleOption({required this.id, required this.label, required this.path, required this.icon});

  /// Stable id used in [ModulePermission.optionId] — keep in sync with
  /// whatever a manager grants in the Roles screen.
  final String id;
  final String label;

  /// Route this option navigates to.
  final String path;
  final IconData icon;
}

/// One entry in the left navigation rail: an icon, a label, and the list
/// of options shown in the sidebar's contextual panel when it's active.
/// Also doubles as a "module" in the permission model
/// ([ModulePermission.moduleId]).
class AppModule {
  const AppModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.options,
    this.extraMatchPrefixes = const [],
  });

  final String id;
  final String label;
  final IconData icon;
  final List<ModuleOption> options;

  /// Extra route-path prefixes (the segment right after `/dashboard/`)
  /// that should also count as "this module is active" even though they
  /// don't match any option's own path 1:1 — e.g. Publications' List /
  /// Workflow / Calendar tabs all belong to the Board module.
  final List<String> extraMatchPrefixes;

  /// Route used when the module's rail icon itself is tapped.
  String get railPath => options.first.path;
}

/// Modules shown in the top group of the rail.
const List<AppModule> kAppModules = [
  AppModule(
    id: 'home',
    label: 'Home',
    icon: Icons.home_rounded,
    options: [
      ModuleOption(id: 'overview', label: 'Overview', path: '/dashboard/home', icon: Icons.grid_view_rounded),
      ModuleOption(id: 'activity', label: 'Recent Activity', path: '/dashboard/home-activity', icon: Icons.timeline_rounded),
      ModuleOption(id: 'shortcuts', label: 'Shortcuts', path: '/dashboard/home-shortcuts', icon: Icons.bolt_rounded),
    ],
  ),
  AppModule(
    id: 'chat',
    label: 'Chat',
    icon: Icons.chat_bubble_rounded,
    options: [
      ModuleOption(id: 'all-messages', label: 'All Messages', path: '/dashboard/chat', icon: Icons.forum_rounded),
      ModuleOption(id: 'channels', label: 'Channels', path: '/dashboard/chat-channels', icon: Icons.tag_rounded),
      ModuleOption(id: 'mentions', label: 'Mentions', path: '/dashboard/chat-mentions', icon: Icons.alternate_email_rounded),
    ],
  ),
  AppModule(
    id: 'board',
    label: 'Projects',
    icon: Icons.dashboard_rounded,
    extraMatchPrefixes: ['publications'],
    options: [
      ModuleOption(id: 'campaigns', label: 'Campaigns', path: '/dashboard/campaigns', icon: Icons.campaign_rounded),
      ModuleOption(id: 'publications', label: 'Publications', path: '/dashboard/board', icon: Icons.menu_book_rounded),
      ModuleOption(id: 'topics', label: 'Topics', path: '/dashboard/topics', icon: Icons.topic_rounded),
      ModuleOption(id: 'planning', label: 'Planning', path: '/dashboard/planning', icon: Icons.event_note_rounded),
      ModuleOption(id: 'design-internal', label: 'Design Internal', path: '/dashboard/design-internal', icon: Icons.design_services_rounded),
      ModuleOption(id: 'development', label: 'Development', path: '/dashboard/development', icon: Icons.code_rounded),
    ],
  ),
  AppModule(
    id: 'nomencladores',
    label: 'Nomencladores',
    icon: Icons.category_rounded,
    options: [
      ModuleOption(id: 'productos', label: 'Productos', path: '/dashboard/productos', icon: Icons.inventory_2_outlined),
      ModuleOption(id: 'tiendas', label: 'Gestión de Tiendas', path: '/dashboard/tiendas', icon: Icons.storefront_outlined),
      ModuleOption(id: 'categorias', label: 'Categorías', path: '/dashboard/nomencladores-categorias', icon: Icons.sell_outlined),
      ModuleOption(id: 'marcas', label: 'Marcas', path: '/dashboard/nomencladores-marcas', icon: Icons.local_offer_outlined),
      ModuleOption(id: 'usuarios', label: 'Gestión de Usuarios', path: '/dashboard/usuarios', icon: Icons.people_alt_outlined),
      ModuleOption(id: 'roles', label: 'Roles y Permisos', path: '/dashboard/roles', icon: Icons.admin_panel_settings_outlined),
    ],
  ),
  AppModule(
    id: 'favorites',
    label: 'Favorites',
    icon: Icons.favorite_rounded,
    options: [
      ModuleOption(id: 'starred-projects', label: 'Starred Projects', path: '/dashboard/favorites', icon: Icons.star_rounded),
      ModuleOption(id: 'starred-tasks', label: 'Starred Tasks', path: '/dashboard/favorites-tasks', icon: Icons.check_circle_outline_rounded),
      ModuleOption(id: 'starred-docs', label: 'Starred Docs', path: '/dashboard/favorites-docs', icon: Icons.description_outlined),
    ],
  ),
  AppModule(
    id: 'insights',
    label: 'Insights',
    icon: Icons.pie_chart_rounded,
    options: [
      ModuleOption(id: 'reports', label: 'Reports', path: '/dashboard/insights', icon: Icons.summarize_rounded),
      ModuleOption(id: 'analytics', label: 'Analytics', path: '/dashboard/insights-analytics', icon: Icons.bar_chart_rounded),
      ModuleOption(id: 'dashboards', label: 'Dashboards', path: '/dashboard/insights-dashboards', icon: Icons.space_dashboard_rounded),
    ],
  ),
  AppModule(
    id: 'history',
    label: 'History',
    icon: Icons.history_rounded,
    options: [
      ModuleOption(id: 'recent-changes', label: 'Recent Changes', path: '/dashboard/history', icon: Icons.restore_rounded),
      ModuleOption(id: 'activity-log', label: 'Activity Log', path: '/dashboard/history-activity', icon: Icons.list_alt_rounded),
      ModuleOption(id: 'version-history', label: 'Version History', path: '/dashboard/history-versions', icon: Icons.difference_rounded),
    ],
  ),
];

/// Modules shown in the bottom (pinned) group of the rail.
const List<AppModule> kBottomRailModules = [
  AppModule(
    id: 'notifications',
    label: 'Notifications',
    icon: Icons.notifications_rounded,
    options: [
      ModuleOption(id: 'all', label: 'All', path: '/dashboard/notifications', icon: Icons.notifications_none_rounded),
      ModuleOption(id: 'mentions', label: 'Mentions', path: '/dashboard/notifications-mentions', icon: Icons.alternate_email_rounded),
      ModuleOption(id: 'updates', label: 'Updates', path: '/dashboard/notifications-updates', icon: Icons.system_update_alt_rounded),
    ],
  ),
  AppModule(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_rounded,
    options: [
      ModuleOption(id: 'general', label: 'General', path: '/dashboard/settings', icon: Icons.tune_rounded),
      ModuleOption(id: 'team', label: 'Team', path: '/dashboard/settings-team', icon: Icons.groups_rounded),
      ModuleOption(id: 'billing', label: 'Billing', path: '/dashboard/settings-billing', icon: Icons.receipt_long_rounded),
    ],
  ),
];

/// All modules, top + bottom, e.g. for building the permission matrix.
List<AppModule> get kAllModules => [...kAppModules, ...kBottomRailModules];
