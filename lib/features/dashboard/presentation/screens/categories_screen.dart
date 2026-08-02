import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../../../core/widgets/status_dot_pill.dart';
import '../../data/category_mock_data.dart';
import '../widgets/category_dialogs.dart';

/// `/dashboard/nomencladores-categorias` — Nomencladores > Categorías.
/// Simple catalog CRUD, same pattern as Productos: every category has a
/// `kind` (Abarrotes/Perecedero) that groups it and drives the filter.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final AppDataTableController<CategoryRow> _controller = AppDataTableController<CategoryRow>(
    fetcher: fetchCategories,
    rowId: (c) => c.id,
    pageSize: 10,
  );

  bool get _canWrite => AuthSession.instance.can('nomencladores', 'categorias', PermissionAction.write);
  bool get _canEdit => AuthSession.instance.can('nomencladores', 'categorias', PermissionAction.edit);
  bool get _canDelete => AuthSession.instance.can('nomencladores', 'categorias', PermissionAction.delete);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Categorías', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('Clasifica los productos en Abarrotes o Perecederos.', style: AppTextStyles.bodySmall),
                ],
              ),
              if (_canWrite)
                ElevatedButton.icon(
                  onPressed: () => showCategoryFormDialog(context, onSaved: _controller.refresh),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nueva Categoría'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<CategoryRow>(
              controller: _controller,
              searchHint: 'Buscar categoría...',
              filters: const [
                AppDataFilter(
                  id: 'kind',
                  label: 'Tipo',
                  options: [
                    AppFilterOption('abarrotes', 'Abarrotes'),
                    AppFilterOption('perecedero', 'Perecedero'),
                  ],
                ),
              ],
              columns: [
                AppDataColumn<CategoryRow>(
                  id: 'name',
                  label: 'Nombre',
                  flex: 3,
                  cellBuilder: (context, row) => Text(row.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                AppDataColumn<CategoryRow>(
                  id: 'kind',
                  label: 'Tipo',
                  flex: 2,
                  minWidth: 140,
                  cellBuilder: (context, row) => StatusDotPill(
                    label: row.kind.label,
                    color: row.kind == CategoryKind.perecedero ? AppColors.success : AppColors.statusInProgress,
                  ),
                ),
              ],
              actionsWidth: 100,
              rowActionsBuilder: (context, row) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                      onPressed: () => showCategoryFormDialog(context, category: row, onSaved: _controller.refresh),
                      tooltip: 'Editar',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (_canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                      onPressed: () => showCategoryDeleteDialog(context, row, onDeleted: _controller.refresh),
                      tooltip: 'Eliminar',
                      visualDensity: VisualDensity.compact,
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
