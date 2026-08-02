import 'package:flutter/material.dart';

import '../../../../core/auth/app_role.dart';
import '../../../../core/auth/app_user.dart';
import '../../../../core/auth/mock_users_repository.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_field.dart';
import '../../../../core/widgets/async_action_button.dart';
import 'permission_matrix.dart';

String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

String? _emailValidator(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Este campo es obligatorio';
  if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Ingresa un correo válido';
  return null;
}

/// Create/edit dialog for a managed user. The role is fixed to whatever
/// [manager] is allowed to manage (`manager.role.managedRole`) — a
/// manager can only ever create accounts one tier below their own.
Future<void> showUserFormDialog(
  BuildContext context, {
  required AppUser manager,
  AppUser? user,
  required VoidCallback onSaved,
}) {
  final isEdit = user != null;
  final targetRole = manager.role.managedRole;
  if (targetRole == null) return Future.value();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: user?.name ?? '');
  final emailController = TextEditingController(text: user?.email ?? '');
  final passwordController = TextEditingController(text: user?.password ?? '');
  final activeNotifier = ValueNotifier<bool>(user?.active ?? true);

  return showAppDialog(
    context: context,
    title: isEdit ? 'Editar usuario' : 'Nuevo ${targetRole.label.toLowerCase()}',
    width: 480,
    contentBuilder: (_) {
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormField(label: 'Nombre completo', controller: nameController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            AppFormField(
              label: 'Correo electrónico',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            AppFormField(label: 'Contraseña', controller: passwordController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Text('Rol: ${targetRole.label}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<bool>(
              valueListenable: activeNotifier,
              builder: (context, active, _) => InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => activeNotifier.value = !active,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text('Cuenta activa', style: AppTextStyles.bodyMedium)),
                      Switch.adaptive(value: active, onChanged: (v) => activeNotifier.value = v),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: isEdit ? 'Guardar cambios' : 'Crear usuario',
        loadingLabel: isEdit ? 'Guardando...' : 'Creando...',
        onPressed: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          await Future.delayed(const Duration(milliseconds: 1000));

          final id = user?.id ?? nextUserId();
          upsertUser(AppUser(
            id: id,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
            role: targetRole,
            permissions: user?.permissions ?? const [],
            active: activeNotifier.value,
          ));

          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          ToastService.success(
            isEdit ? 'Los datos de "${nameController.text.trim()}" se guardaron correctamente.' : '"${nameController.text.trim()}" se creó correctamente.',
            title: isEdit ? 'Usuario actualizado' : 'Usuario creado',
          );
        },
      ),
    ],
  );
}

Future<void> showUserDeleteDialog(
  BuildContext context,
  AppUser user, {
  required VoidCallback onDeleted,
}) {
  return showAppDialog(
    context: context,
    title: 'Eliminar usuario',
    width: 420,
    contentBuilder: (_) => Text(
      '¿Seguro que deseas eliminar a "${user.name}"? Perderá acceso inmediatamente.',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: 'Eliminar',
        loadingLabel: 'Eliminando...',
        icon: Icons.delete_outline_rounded,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 800));
          deleteUser(user.id);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onDeleted();
          ToastService.success('"${user.name}" se eliminó correctamente.', title: 'Usuario eliminado');
        },
      ),
    ],
  );
}

/// Opens the permission matrix for [user] inside a dialog — same widget
/// used inline by the "Roles y Permisos" screen, just wrapped for quick
/// access from the "Gestión de Usuarios" table.
Future<void> showUserPermissionsDialog(
  BuildContext context,
  AppUser user, {
  required VoidCallback onSaved,
}) {
  final matrixKey = GlobalKey<PermissionMatrixState>();

  return showAppDialog(
    context: context,
    title: 'Permisos de ${user.name}',
    width: 560,
    contentBuilder: (_) => PermissionMatrix(key: matrixKey, initialPermissions: user.permissions),
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: 'Guardar permisos',
        loadingLabel: 'Guardando...',
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 900));
          final updated = matrixKey.currentState?.currentPermissions ?? const <ModulePermission>[];
          updateUserPermissions(user.id, updated);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          ToastService.success('Los permisos de "${user.name}" se actualizaron correctamente.', title: 'Permisos guardados');
        },
      ),
    ],
  );
}
