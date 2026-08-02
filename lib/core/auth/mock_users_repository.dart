import 'app_role.dart';
import 'app_user.dart';
import 'permission.dart';

/// In-memory user directory. Swap the functions below for real API calls
/// when wiring a backend — [AuthSession] and every screen only depend on
/// these signatures, not on how the data is stored.
///
/// Seeded with one demo account per role (used by the login screen's
/// quick-access buttons) plus a couple of extra managed users per tier so
/// the "Gestión de Usuarios" / "Roles y Permisos" tables have rows to show.
final List<AppUser> _users = [
  const AppUser(
    id: 'u_superadmin',
    name: 'Sofía Reyes',
    email: 'superadmin@argos.com',
    password: 'Super123!',
    role: AppRole.superAdmin,
  ),

  // ---- Admins (managed by SuperAdmin) ---------------------------------
  AppUser(
    id: 'u_admin_demo',
    name: 'Andrés Molina',
    email: 'admin@argos.com',
    password: 'Admin123!',
    role: AppRole.admin,
    permissions: [
      ...grantModule('board', ['campaigns', 'publications', 'topics', 'planning', 'design-internal', 'development'], kFullCrud),
      ...grantModule('nomencladores', ['productos', 'categorias', 'marcas', 'usuarios', 'roles'], kFullCrud),
      ...grantModule('home', ['overview', 'activity', 'shortcuts'], kReadOnly),
      ...grantModule('settings', ['general', 'team', 'billing'], kFullCrud),
    ],
  ),
  AppUser(
    id: 'u_admin_2',
    name: 'Paula Cortés',
    email: 'paula.cortes@argos.com',
    password: 'Admin123!',
    role: AppRole.admin,
    permissions: [
      ...grantModule('board', ['publications', 'topics', 'planning'], kFullCrud),
      ...grantModule('nomencladores', ['productos', 'usuarios', 'roles'], kFullCrud),
      ...grantModule('home', ['overview'], kReadOnly),
    ],
  ),

  // ---- Propietarios (managed by Admin) --------------------------------
  AppUser(
    id: 'u_propietario_demo',
    name: 'Rodrigo Salas',
    email: 'propietario@argos.com',
    password: 'Dueno123!',
    role: AppRole.propietario,
    permissions: [
      ...grantModule('board', ['publications', 'topics', 'planning'], kFullCrud),
      ...grantModule('nomencladores', ['productos', 'usuarios', 'roles'], kFullCrud),
      ...grantModule('home', ['overview'], kReadOnly),
    ],
  ),
  AppUser(
    id: 'u_propietario_2',
    name: 'Carla Vidal',
    email: 'carla.vidal@argos.com',
    password: 'Dueno123!',
    role: AppRole.propietario,
    permissions: [
      ...grantModule('board', ['publications'], kFullCrud),
      ...grantModule('nomencladores', ['productos', 'usuarios'], kReadOnly),
    ],
  ),

  // ---- Trabajadores (managed by Propietario) --------------------------
  AppUser(
    id: 'u_trabajador_demo',
    name: 'Marco Peña',
    email: 'trabajador@argos.com',
    password: 'Trabajo123!',
    role: AppRole.trabajador,
    permissions: [
      ...grantModule('board', ['publications'], kReadOnly),
      ...grantModule('home', ['overview'], kReadOnly),
    ],
  ),
  AppUser(
    id: 'u_trabajador_2',
    name: 'Lucía Fuentes',
    email: 'lucia.fuentes@argos.com',
    password: 'Trabajo123!',
    role: AppRole.trabajador,
    permissions: [
      ...grantModule('board', ['publications'], kReadOnly),
    ],
  ),
];

/// The seeded demo account for a given role — used by the login screen's
/// quick-access buttons to prefill credentials.
AppUser demoUserForRole(AppRole role) => _users.firstWhere((u) => u.role == role);

AppUser? findUserByEmail(String email) {
  for (final u in _users) {
    if (u.email.toLowerCase() == email.trim().toLowerCase()) return u;
  }
  return null;
}

AppUser? findUserById(String id) {
  for (final u in _users) {
    if (u.id == id) return u;
  }
  return null;
}

/// Every user whose role is exactly the one [manager] is allowed to
/// manage, per the SuperAdmin -> Admin -> Propietario -> Trabajador
/// hierarchy (see [AppRoleX.managedRole]).
List<AppUser> usersManagedBy(AppUser manager) {
  final managedRole = manager.role.managedRole;
  if (managedRole == null) return const [];
  return _users.where((u) => u.role == managedRole).toList();
}

void upsertUser(AppUser user) {
  final index = _users.indexWhere((u) => u.id == user.id);
  if (index >= 0) {
    _users[index] = user;
  } else {
    _users.insert(0, user);
  }
}

void deleteUser(String id) {
  _users.removeWhere((u) => u.id == id);
}

void updateUserPermissions(String id, List<ModulePermission> permissions) {
  final index = _users.indexWhere((u) => u.id == id);
  if (index >= 0) {
    _users[index] = _users[index].copyWith(permissions: permissions);
  }
}

String nextUserId() => 'u_new_${DateTime.now().microsecondsSinceEpoch}';
