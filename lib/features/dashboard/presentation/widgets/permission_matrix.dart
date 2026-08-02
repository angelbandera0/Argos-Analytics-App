import 'package:flutter/material.dart';

import '../../../../core/auth/module_registry.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Editable grid of Módulo > Opción > (Leer/Crear/Editar/Eliminar)
/// checkboxes. Used both inline in the "Roles y Permisos" screen and
/// inside the "Permisos" dialog opened from "Gestión de Usuarios".
///
/// Fully self-contained: owns its own working copy of the permissions so
/// the caller doesn't need a `StatefulBuilder` — read the current value
/// back out via [PermissionMatrixState.currentPermissions] through the
/// [GlobalKey], or just use [onChanged] to keep a copy as the user edits.
class PermissionMatrix extends StatefulWidget {
  const PermissionMatrix({
    super.key,
    required this.initialPermissions,
    this.onChanged,
    this.availableModules,
  });

  final List<ModulePermission> initialPermissions;
  final ValueChanged<List<ModulePermission>>? onChanged;

  /// Restrict which modules can be granted (defaults to every module in
  /// the app). Useful if a manager should only be able to grant access
  /// to modules they themselves have.
  final List<AppModule>? availableModules;

  @override
  State<PermissionMatrix> createState() => PermissionMatrixState();
}

class PermissionMatrixState extends State<PermissionMatrix> {
  late Map<String, Set<PermissionAction>> _grants; // "$moduleId::$optionId" -> actions

  @override
  void initState() {
    super.initState();
    _grants = {
      for (final p in widget.initialPermissions) '${p.moduleId}::${p.optionId}': Set.of(p.actions),
    };
  }

  List<ModulePermission> get currentPermissions => [
        for (final entry in _grants.entries)
          if (entry.value.isNotEmpty)
            ModulePermission(
              moduleId: entry.key.split('::').first,
              optionId: entry.key.split('::').last,
              actions: entry.value,
            ),
      ];

  void _toggle(String moduleId, String optionId, PermissionAction action) {
    final key = '$moduleId::$optionId';
    setState(() {
      final actions = Set<PermissionAction>.from(_grants[key] ?? const {});
      if (actions.contains(action)) {
        actions.remove(action);
      } else {
        actions.add(action);
        // Write/edit/delete implicitly require read so the option stays
        // visible in the sidebar once any access is granted.
        actions.add(PermissionAction.read);
      }
      _grants[key] = actions;
    });
    widget.onChanged?.call(currentPermissions);
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.availableModules ?? kAllModules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final module in modules) _ExpandableModuleSection(module: module, grants: _grants, onToggle: _toggle)],
    );
  }
}

/// Custom expand/collapse section — deliberately not `ExpansionTile`
/// (which wraps a `ListTile` internally and can print "background color
/// or ink splashes may be invisible" when its Material ancestor's color
/// doesn't match, e.g. inside a dialog). Wrapping in our own
/// `Material(color: transparent)` guarantees a well-defined ink surface
/// regardless of where this widget is used (dialog or inline screen).
class _ExpandableModuleSection extends StatefulWidget {
  const _ExpandableModuleSection({required this.module, required this.grants, required this.onToggle});

  final AppModule module;
  final Map<String, Set<PermissionAction>> grants;
  final void Function(String moduleId, String optionId, PermissionAction action) onToggle;

  @override
  State<_ExpandableModuleSection> createState() => _ExpandableModuleSectionState();
}

class _ExpandableModuleSectionState extends State<_ExpandableModuleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(widget.module.icon, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(widget.module.label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                children: [
                  // Column header for the 4 action checkboxes.
                  Padding(
                    padding: const EdgeInsets.only(left: 34, right: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Expanded(flex: 3, child: SizedBox.shrink()),
                        for (final action in PermissionAction.values)
                          Expanded(child: Center(child: Text(action.label, style: AppTextStyles.caption))),
                      ],
                    ),
                  ),
                  for (final option in widget.module.options)
                    _OptionRow(module: widget.module, option: option, grants: widget.grants, onToggle: widget.onToggle),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.module, required this.option, required this.grants, required this.onToggle});

  final AppModule module;
  final ModuleOption option;
  final Map<String, Set<PermissionAction>> grants;
  final void Function(String moduleId, String optionId, PermissionAction action) onToggle;

  @override
  Widget build(BuildContext context) {
    final actions = grants['${module.id}::${option.id}'] ?? const <PermissionAction>{};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl),
              child: Text(option.label, style: AppTextStyles.bodySmall),
            ),
          ),
          for (final action in PermissionAction.values)
            Expanded(
              child: Center(
                child: Checkbox(
                  value: actions.contains(action),
                  onChanged: (_) => onToggle(module.id, option.id, action),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
