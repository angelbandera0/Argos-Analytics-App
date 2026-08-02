import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../data/products_mock_data.dart';
import '../widgets/product_dialogs.dart';
import '../widgets/status_pill.dart';

/// `/dashboard/productos` — catalog table built entirely on top of the
/// reusable [AppDataTable]. Everything here (columns, filters, actions)
/// is just configuration; the table itself has no product-specific code.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final AppDataTableController<ProductRow> _controller = AppDataTableController<ProductRow>(
    fetcher: fetchProducts,
    rowId: (row) => row.id,
    pageSize: 14,
    selectionMode: AppDataTableSelectionMode.multiple,
    initialSort: const AppDataSort('name', AppSortDirection.ascending),
  );

  String _statusTab = 'all';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(String tab) {
    setState(() => _statusTab = tab);
    switch (tab) {
      case 'active':
        _controller.setFilter('status', {ProductStatus.active.value});
        break;
      case 'pending':
        _controller.setFilter('status', {ProductStatus.pending.value});
        break;
      case 'inactive':
        _controller.setFilter('status', {ProductStatus.inactive.value, ProductStatus.canceled.value});
        break;
      default:
        _controller.setFilter('status', {});
    }
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
              Text('All Products', style: AppTextStyles.h1),
              if (AuthSession.instance.can('nomencladores', 'productos', PermissionAction.write))
                ElevatedButton.icon(
                  onPressed: () => showProductFormDialog(context, onSaved: _controller.refresh),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add New Product'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusTabs(current: _statusTab, onChanged: _selectTab),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<ProductRow>(
              controller: _controller,
              searchHint: 'Type to search',
              showSelectionColumn: true,
              actionsWidth: 140,
              filters: const [
                AppDataFilter(
                  id: 'status',
                  label: 'Status',
                  options: [
                    AppFilterOption('active', 'Active'),
                    AppFilterOption('pending', 'Pending'),
                    AppFilterOption('canceled', 'Canceled'),
                    AppFilterOption('rejected', 'Rejected'),
                    AppFilterOption('inactive', 'Inactive'),
                  ],
                ),
              ],
              columns: [
                AppDataColumn<ProductRow>(
                  id: 'code',
                  label: 'ID',
                  width: 64,
                  cellBuilder: (context, row) => Text(row.code, style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<ProductRow>(
                  id: 'name',
                  label: 'Product',
                  flex: 3,
                  sortable: true,
                  cellBuilder: (context, row) => Text(row.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                AppDataColumn<ProductRow>(
                  id: 'sku',
                  label: 'SKU',
                  flex: 2,
                  cellBuilder: (context, row) => Text(row.sku, style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<ProductRow>(
                  id: 'status',
                  label: 'Status',
                  flex: 2,
                  minWidth: 140,
                  cellBuilder: (context, row) => StatusPill(status: row.status),
                ),
                AppDataColumn<ProductRow>(
                  id: 'price',
                  label: 'Price',
                  flex: 2,
                  sortable: true,
                  cellBuilder: (context, row) => Text('\$${row.price.toStringAsFixed(0)}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<ProductRow>(
                  id: 'cost',
                  label: 'Cost',
                  flex: 2,
                  sortable: true,
                  cellBuilder: (context, row) => Text('\$${row.cost.toStringAsFixed(0)}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<ProductRow>(
                  id: 'stock',
                  label: 'Stock',
                  flex: 1,
                  sortable: true,
                  cellBuilder: (context, row) => Text('${row.stock}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<ProductRow>(
                  id: 'sales',
                  label: 'Sales',
                  flex: 1,
                  sortable: true,
                  cellBuilder: (context, row) => Text('${row.sales}', style: AppTextStyles.bodySmall),
                ),
              ],
              rowActionsBuilder: (context, row) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textMuted),
                    onPressed: () => showProductDetailDialog(context, row, onSaved: _controller.refresh),
                    tooltip: 'Ver detalle',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (AuthSession.instance.can('nomencladores', 'productos', PermissionAction.edit))
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                      onPressed: () => showProductFormDialog(context, product: row, onSaved: _controller.refresh),
                      tooltip: 'Editar',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (AuthSession.instance.can('nomencladores', 'productos', PermissionAction.delete))
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                      onPressed: () => showProductDeleteDialog(context, row, onDeleted: _controller.refresh),
                      tooltip: 'Eliminar',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              onRowTap: (row) => showProductDetailDialog(context, row, onSaved: _controller.refresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  static const _tabs = [('all', 'All'), ('active', 'Active'), ('pending', 'Pending'), ('inactive', 'Inactive')];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in _tabs)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: InkWell(
              onTap: () => onChanged(tab.$1),
              child: Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: current == tab.$1 ? AppColors.primary : Colors.transparent, width: 2)),
                ),
                child: Text(
                  tab.$2,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: current == tab.$1 ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: current == tab.$1 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
