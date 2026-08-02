// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************
//
// NOTE: this file is hand-authored to match the exact output shape of
// `go_router_builder` so the project runs without requiring build_runner
// on first clone. If you add / change any @TypedGoRoute or @TypedShellRoute
// declaration in app_router.dart, regenerate this file with:
//
//   flutter pub run build_runner build --delete-conflicting-outputs

List<RouteBase> get $appRoutes => [
      $loginRoute,
      $dashboardShellRouteData,
    ];

RouteBase get $loginRoute => GoRouteData.$route(
      path: '/login',
      factory: $LoginRouteExtension._fromState,
    );

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  String get location => GoRouteData.$location('/login');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $dashboardShellRouteData => ShellRouteData.$route(
      factory: $DashboardShellRouteDataExtension._fromState,
      routes: [
        $publicationsBoardRoute,
        $productosRoute,
        $tiendasRoute,
        $usuariosRoute,
        $rolesRoute,
        $dashboardSectionRoute,
      ],
    );

extension $DashboardShellRouteDataExtension on DashboardShellRouteData {
  static DashboardShellRouteData _fromState(GoRouterState state) => const DashboardShellRouteData();
}

RouteBase get $publicationsBoardRoute => GoRouteData.$route(
      path: '/dashboard/board',
      factory: $PublicationsBoardRouteExtension._fromState,
    );

extension $PublicationsBoardRouteExtension on PublicationsBoardRoute {
  static PublicationsBoardRoute _fromState(GoRouterState state) => const PublicationsBoardRoute();

  String get location => GoRouteData.$location('/dashboard/board');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $productosRoute => GoRouteData.$route(
      path: '/dashboard/productos',
      factory: $ProductosRouteExtension._fromState,
    );

extension $ProductosRouteExtension on ProductosRoute {
  static ProductosRoute _fromState(GoRouterState state) => const ProductosRoute();

  String get location => GoRouteData.$location('/dashboard/productos');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $tiendasRoute => GoRouteData.$route(
      path: '/dashboard/tiendas',
      factory: $TiendasRouteExtension._fromState,
    );

extension $TiendasRouteExtension on TiendasRoute {
  static TiendasRoute _fromState(GoRouterState state) => const TiendasRoute();

  String get location => GoRouteData.$location('/dashboard/tiendas');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $usuariosRoute => GoRouteData.$route(
      path: '/dashboard/usuarios',
      factory: $UsuariosRouteExtension._fromState,
    );

extension $UsuariosRouteExtension on UsuariosRoute {
  static UsuariosRoute _fromState(GoRouterState state) => const UsuariosRoute();

  String get location => GoRouteData.$location('/dashboard/usuarios');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $rolesRoute => GoRouteData.$route(
      path: '/dashboard/roles',
      factory: $RolesRouteExtension._fromState,
    );

extension $RolesRouteExtension on RolesRoute {
  static RolesRoute _fromState(GoRouterState state) => const RolesRoute();

  String get location => GoRouteData.$location('/dashboard/roles');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $dashboardSectionRoute => GoRouteData.$route(
      path: '/dashboard/:section',
      factory: $DashboardSectionRouteExtension._fromState,
    );

extension $DashboardSectionRouteExtension on DashboardSectionRoute {
  static DashboardSectionRoute _fromState(GoRouterState state) => DashboardSectionRoute(
        state.pathParameters['section']!,
      );

  String get location => GoRouteData.$location(
        '/dashboard/${Uri.encodeComponent(section)}',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
