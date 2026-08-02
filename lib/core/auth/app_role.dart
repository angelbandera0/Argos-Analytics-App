/// The four roles in Argos Analytics, in management order: each role
/// (except Trabajador) manages the accounts of the role right below it.
///
///   SuperAdmin -> Admin -> Propietario -> Trabajador
enum AppRole { superAdmin, admin, propietario, trabajador }

extension AppRoleX on AppRole {
  String get label => switch (this) {
        AppRole.superAdmin => 'Super Admin',
        AppRole.admin => 'Admin',
        AppRole.propietario => 'Propietario',
        AppRole.trabajador => 'Trabajador',
      };

  /// The role this one is allowed to create/edit/delete and grant
  /// permissions to. `null` for Trabajador, which manages no one.
  AppRole? get managedRole => switch (this) {
        AppRole.superAdmin => AppRole.admin,
        AppRole.admin => AppRole.propietario,
        AppRole.propietario => AppRole.trabajador,
        AppRole.trabajador => null,
      };

  /// SuperAdmin bypasses every permission check — it always has full
  /// access to every module/option/action.
  bool get hasUnrestrictedAccess => this == AppRole.superAdmin;
}
