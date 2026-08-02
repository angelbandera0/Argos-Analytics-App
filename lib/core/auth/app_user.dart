import 'app_role.dart';
import 'permission.dart';

/// A user account. `password` is plaintext on purpose — this is a mock
/// auth system for the demo; swap [AuthSession.login] for a real API
/// call and this field disappears client-side.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.permissions = const [],
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final AppRole role;

  /// Which module options this user can access, and with which CRUD
  /// actions. Ignored for [AppRole.superAdmin], which always has full
  /// access — see [AuthSession.can].
  final List<ModulePermission> permissions;

  final bool active;

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    AppRole? role,
    List<ModulePermission>? permissions,
    bool? active,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      active: active ?? this.active,
    );
  }
}
