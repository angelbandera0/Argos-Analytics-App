import 'package:flutter/material.dart';

import '../../../../core/auth/app_role.dart';
import '../../../../core/auth/app_user.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/mock_users_repository.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../widgets/permission_matrix.dart';

/// `/dashboard/roles` (Nomencladores > Roles y Permisos).
///
/// Left: pick one of the users the current role manages — reuses
/// [AppDataTable] (single-selection mode) with search, exactly like any
/// other listing in the app. Right: the [PermissionMatrix] for whoever is
/// selected, with its own "Guardar" action.
///
/// Responsive: side-by-side on wide layouts, stacked on mobile/tablet
/// portrait.
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  late final AppDataTableController<AppUser> _pickerController = AppDataTableController<AppUser>(
    fetcher: _fetchUsers,
    rowId: (u) => u.id,
    pageSize: 8,
    selectionMode: AppDataTableSelectionMode.single,
    initialSort: const AppDataSort('name', AppSortDirection.ascending),
  );

  AppUser? _selectedUser;

  AppUser get _manager => AuthSession.instance.currentUser!;

  Future<AppDataResult<AppUser>> _fetchUsers(AppDataRequest request) async {
    await Future.delayed(const Duration(milliseconds: 450));

    var items = usersManagedBy(_manager);
    if (request.search != null && request.search!.trim().isNotEmpty) {
      final q = request.search!.trim().toLowerCase();
      items = items.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
    }
    items.sort((a, b) => a.name.compareTo(b.name));
    if (request.sort?.direction == AppSortDirection.descending) items = items.reversed.toList();

    final total = items.length;
    final start = (request.page - 1) * request.pageSize;
    final end = (start + request.pageSize).clamp(0, total);
    final pageItems = start >= total ? <AppUser>[] : items.sublist(start, end);
    return AppDataResult(items: pageItems, totalCount: total);
  }

  void _selectUser(AppUser user) {
    _pickerController.toggleRowSelection(user);
    setState(() => _selectedUser = user);
  }

  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managedRole = _manager.role.managedRole;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roles y Permisos', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            managedRole == null
                ? 'No tienes usuarios a tu cargo para asignarles permisos.'
                : 'Selecciona un ${managedRole.label.toLowerCase()} y define a qué módulos y opciones puede acceder, y si puede leer, crear, editar o eliminar en cada una.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                final picker = _UserPickerCard(
                  controller: _pickerController,
                  selectedId: _selectedUser?.id,
                  onSelect: _selectUser,
                  height: isWide ? null : 360,
                );

                final matrix = _selectedUser == null
                    ? const _EmptyMatrixState()
                    : _MatrixCard(key: ValueKey(_selectedUser!.id), user: _selectedUser!, onSaved: () => setState(() {}));

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: picker),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 3, child: matrix),
                    ],
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [picker, const SizedBox(height: AppSpacing.lg), matrix],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPickerCard extends StatelessWidget {
  const _UserPickerCard({required this.controller, required this.selectedId, required this.onSelect, required this.height});

  final AppDataTableController<AppUser> controller;
  final String? selectedId;
  final ValueChanged<AppUser> onSelect;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AppDataTable<AppUser>(
      controller: controller,
      searchHint: 'Buscar usuario...',
      height: height,
      onRowTap: onSelect,
      columns: [
        AppDataColumn<AppUser>(
          id: 'name',
          label: 'Usuario',
          flex: 3,
          cellBuilder: (context, row) => Text(row.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ),
        AppDataColumn<AppUser>(
          id: 'email',
          label: 'Correo',
          flex: 3,
          minWidth: 180,
          cellBuilder: (context, row) => Text(row.email, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }
}

class _MatrixCard extends StatefulWidget {
  const _MatrixCard({super.key, required this.user, required this.onSaved});
  final AppUser user;
  final VoidCallback onSaved;

  @override
  State<_MatrixCard> createState() => _MatrixCardState();
}

class _MatrixCardState extends State<_MatrixCard> {
  final _matrixKey = GlobalKey<PermissionMatrixState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.user.email, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              child: PermissionMatrix(key: _matrixKey, initialPermissions: widget.user.permissions),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: AsyncActionButton(
              label: 'Guardar permisos',
              loadingLabel: 'Guardando...',
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 900));
                final matrixState = _matrixKeyState();
                final updated = matrixState?.currentPermissions ?? const [];
                updateUserPermissions(widget.user.id, updated);
                widget.onSaved();
                ToastService.success('Los permisos de "${widget.user.name}" se actualizaron correctamente.', title: 'Permisos guardados');
              },
            ),
          ),
        ],
      ),
    );
  }

  PermissionMatrixState? _matrixKeyState() => _matrixKey.currentState;
}

class _EmptyMatrixState extends StatelessWidget {
  const _EmptyMatrixState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('Selecciona un usuario de la lista', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Sus permisos por módulo y opción aparecerán aquí.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
