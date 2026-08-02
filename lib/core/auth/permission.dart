/// CRUD-level actions that can be granted independently for a given
/// module option — "puede leer, escribir, editar o eliminar" per option.
enum PermissionAction { read, write, edit, delete }

extension PermissionActionX on PermissionAction {
  String get label => switch (this) {
        PermissionAction.read => 'Leer',
        PermissionAction.write => 'Crear',
        PermissionAction.edit => 'Editar',
        PermissionAction.delete => 'Eliminar',
      };
}

/// Grants a user access to one module option (e.g. `nomencladores` /
/// `productos`) with a specific set of CRUD actions. A user's full access
/// is just `List<ModulePermission>` — see [AppUser.permissions].
class ModulePermission {
  const ModulePermission({required this.moduleId, required this.optionId, required this.actions});

  final String moduleId;
  final String optionId;
  final Set<PermissionAction> actions;

  bool get canRead => actions.contains(PermissionAction.read);

  ModulePermission copyWith({Set<PermissionAction>? actions}) =>
      ModulePermission(moduleId: moduleId, optionId: optionId, actions: actions ?? this.actions);
}

const Set<PermissionAction> kFullCrud = {
  PermissionAction.read,
  PermissionAction.write,
  PermissionAction.edit,
  PermissionAction.delete,
};

const Set<PermissionAction> kReadOnly = {PermissionAction.read};

/// Convenience to grant the same [actions] over several options of one
/// module — used a lot when seeding demo users.
List<ModulePermission> grantModule(String moduleId, List<String> optionIds, Set<PermissionAction> actions) => [
      for (final optionId in optionIds) ModulePermission(moduleId: moduleId, optionId: optionId, actions: actions),
    ];
