import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/screens/products_screen.dart';
import '../../features/dashboard/presentation/screens/projects_board_screen.dart';
import '../../features/dashboard/presentation/screens/roles_screen.dart';
import '../../features/dashboard/presentation/screens/usuarios_screen.dart';
import '../auth/auth_session.dart';
import '../services/toast_service.dart';
import '../widgets/coming_soon_view.dart';

part 'app_router.g.dart';

/// Central place that maps every nav-item slug shown in the sidebar / icon
/// rail to a human readable label. Used both by the sidebar (to build links)
/// and by the generic "coming soon" screen (to render the route name).
///
/// Adding a new section later only means adding one entry here plus a
/// sidebar item — no new route class, no new screen.
const Map<String, String> kDashboardSectionLabels = {
  'home': 'Home · Overview',
  'home-activity': 'Home · Recent Activity',
  'home-shortcuts': 'Home · Shortcuts',
  'chat': 'Chat · All Messages',
  'chat-channels': 'Chat · Channels',
  'chat-mentions': 'Chat · Mentions',
  'favorites': 'Favorites · Starred Projects',
  'favorites-tasks': 'Favorites · Starred Tasks',
  'favorites-docs': 'Favorites · Starred Docs',
  'insights': 'Insights · Reports',
  'insights-analytics': 'Insights · Analytics',
  'insights-dashboards': 'Insights · Dashboards',
  'library': 'Library · Templates',
  'library-assets': 'Library · Assets',
  'library-docs': 'Library · Documentation',
  'nomencladores-categorias': 'Nomencladores · Categorías',
  'nomencladores-marcas': 'Nomencladores · Marcas',
  'history': 'History · Recent Changes',
  'history-activity': 'History · Activity Log',
  'history-versions': 'History · Version History',
  'notifications': 'Notifications · All',
  'notifications-mentions': 'Notifications · Mentions',
  'notifications-updates': 'Notifications · Updates',
  'settings': 'Settings · General',
  'settings-team': 'Settings · Team',
  'settings-billing': 'Settings · Billing',
  'campaigns': 'Campaigns',
  'topics': 'Topics',
  'planning': 'Planning',
  'design-internal': 'Design Internal',
  'development': 'Development',
  'publications-list': 'Publications · List',
  'publications-workflow': 'Publications · Workflow',
  'publications-calendar': 'Publications · Calendar',
};

/// GoRouter instance for the whole app. Route trees are declared with
/// go_router_builder ([TypedGoRoute] / [TypedShellRoute]) below; run
///   flutter pub run build_runner build --delete-conflicting-outputs
/// to (re)generate `app_router.g.dart` whenever a route is added or changed.
final GoRouter appRouter = GoRouter(
  navigatorKey: ToastService.navigatorKey,
  initialLocation: '/login',
  debugLogDiagnostics: false,
  refreshListenable: AuthSession.instance,
  redirect: (context, state) {
    final loggedIn = AuthSession.instance.isLoggedIn;
    final goingToLogin = state.matchedLocation == '/login';
    if (!loggedIn && !goingToLogin) return '/login';
    if (loggedIn && goingToLogin) return '/dashboard/board';
    return null;
  },
  routes: $appRoutes,
);

/// `/login`
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginScreen();
}

/// `/dashboard` — persistent shell (sidebar + top icon rail) that hosts every
/// dashboard sub-view. This is the reusable "route level layout" requested:
/// any child route renders inside [DashboardShell] automatically.
@TypedShellRoute<DashboardShellRouteData>(
  routes: [
    TypedGoRoute<PublicationsBoardRoute>(path: '/dashboard/board'),
    TypedGoRoute<ProductosRoute>(path: '/dashboard/productos'),
    TypedGoRoute<UsuariosRoute>(path: '/dashboard/usuarios'),
    TypedGoRoute<RolesRoute>(path: '/dashboard/roles'),
    TypedGoRoute<DashboardSectionRoute>(path: '/dashboard/:section'),
  ],
)
class DashboardShellRouteData extends ShellRouteData {
  const DashboardShellRouteData();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return DashboardShell(child: navigator);
  }
}

/// `/dashboard/board` — the one fully implemented view (Publications board),
/// matching the provided design.
class PublicationsBoardRoute extends GoRouteData {
  const PublicationsBoardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ProjectsBoardScreen();
}

/// `/dashboard/productos` — product catalog, built on the reusable
/// `AppDataTable` component.
class ProductosRoute extends GoRouteData {
  const ProductosRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ProductsScreen();
}

/// `/dashboard/usuarios` — user management (Nomencladores > Gestión de
/// Usuarios): create/edit/delete the accounts the current role manages.
class UsuariosRoute extends GoRouteData {
  const UsuariosRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const UsuariosScreen();
}

/// `/dashboard/roles` — permission matrix editor (Nomencladores > Roles
/// y Permisos): pick a managed user, grant read/write/edit/delete per
/// module option.
class RolesRoute extends GoRouteData {
  const RolesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const RolesScreen();
}

/// `/dashboard/:section` — generic catch-all for every other sidebar / rail
/// item (home, chat, campaigns, topics, planning, design-internal,
/// development, favorites, insights, library, history, notifications,
/// settings, and the other Publications tabs: list/workflow/calendar).
/// Renders a "coming soon" placeholder with the route name.
class DashboardSectionRoute extends GoRouteData {
  const DashboardSectionRoute(this.section);

  final String section;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final label = kDashboardSectionLabels[section] ?? section;
    return ComingSoonView(routeName: label, path: '/dashboard/$section');
  }
}
