import 'package:flutter/material.dart';

import '../../../../core/auth/app_role.dart';
import '../../../../core/auth/app_user.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/mock_users_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../widgets/user_dialogs.dart';

/// `/dashboard/usuarios` (Nomencladores > Gestión de Usuarios).
///
/// Lists exactly the users the current role is allowed to manage — per
/// the SuperAdmin -> Admin -> Propietario -> Trabajador hierarchy, that's
/// always the tier right below the current user's own role
/// (`role.managedRole`). Trabajadores manage no one, so this screen is
/// unreachable for them (hidden from the sidebar too).
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late final AppDataTableController<AppUser> _controller = AppDataTableController<AppUser>(
    fetcher: _fetchUsers,
    rowId: (u) => u.id,
    pageSize: 10,
    initialSort: const AppDataSort('name', AppSortDirection.ascending),
  );

  AppUser get _manager => AuthSession.instance.currentUser!;

  Future<AppDataResult<AppUser>> _fetchUsers(AppDataRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var items = usersManagedBy(_manager);

    if (request.search != null && request.search!.trim().isNotEmpty) {
      final q = request.search!.trim().toLowerCase();
      items = items.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
    }

    final statusFilter = request.filters['status'];
    if (statusFilter != null && statusFilter.isNotEmpty) {
      items = items.where((u) => statusFilter.contains(u.active ? 'active' : 'inactive')).toList();
    }

    if (request.sort?.columnId == 'name') {
      items.sort((a, b) => a.name.compareTo(b.name));
      if (request.sort!.direction == AppSortDirection.descending) items = items.reversed.toList();
    }

    final total = items.length;
    final start = (request.page - 1) * request.pageSize;
    final end = (start + request.pageSize).clamp(0, total);
    final pageItems = start >= total ? <AppUser>[] : items.sublist(start, end);
    return AppDataResult(items: pageItems, totalCount: total);
  }

  @override
  void dispose() {
    _controller.dispose();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gestión de Usuarios', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text(
                    managedRole == null ? 'No tienes usuarios a tu cargo.' : 'Cuentas de tipo ${managedRole.label} bajo tu gestión.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              if (managedRole != null)
                ElevatedButton.icon(
                  onPressed: () => showUserFormDialog(context, manager: _manager, onSaved: _controller.refresh),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text('Nuevo ${managedRole.label}'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<AppUser>(
              controller: _controller,
              searchHint: 'Buscar por nombre o correo...',
              filters: const [
                AppDataFilter(
                  id: 'status',
                  label: 'Estado',
                  options: [
                    AppFilterOption('active', 'Activo'),
                    AppFilterOption('inactive', 'Inactivo'),
                  ],
                ),
              ],
              columns: [
                AppDataColumn<AppUser>(
                  id: 'name',
                  label: 'Nombre',
                  flex: 3,
                  sortable: true,
                  cellBuilder: (context, row) => Text(row.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                AppDataColumn<AppUser>(
                  id: 'email',
                  label: 'Correo',
                  flex: 3,
                  cellBuilder: (context, row) => Text(row.email, style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<AppUser>(
                  id: 'role',
                  label: 'Rol',
                  minWidth: 130,
                  cellBuilder: (context, row) => Text(row.role.label, style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<AppUser>(
                  id: 'status',
                  label: 'Estado',
                  minWidth: 120,
                  cellBuilder: (context, row) => _StatusBadge(active: row.active),
                ),
              ],
              actionsWidth: 150,
              rowActionsBuilder: (context, row) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: AppColors.textMuted),
                    tooltip: 'Permisos',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showUserPermissionsDialog(context, row, onSaved: _controller.refresh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                    tooltip: 'Editar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showUserFormDialog(context, manager: _manager, user: row, onSaved: _controller.refresh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showUserDeleteDialog(context, row, onDeleted: _controller.refresh),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(active ? 'Activo' : 'Inactivo', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
