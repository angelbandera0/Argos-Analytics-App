import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../data/products_mock_data.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/stores_mock_data.dart';

/// `/dashboard/asignacion-productos` — Nomencladores > Asignación de
/// Productos a Tienda.
///
/// Catalog-level relationship: which products a store is allowed to
/// carry at all, independent of quantity. This is what later limits the
/// product pickers when creating a Transfer into that store or a Sale
/// at that store — you can't transfer/sell something the store was
/// never assigned to sell.
class ProductStoreAssignmentScreen extends StatefulWidget {
  const ProductStoreAssignmentScreen({super.key});

  @override
  State<ProductStoreAssignmentScreen> createState() =>
      _ProductStoreAssignmentScreenState();
}

class _ProductStoreAssignmentScreenState
    extends State<ProductStoreAssignmentScreen> {
  late final AppDataTableController<ProductRow> _controller =
      AppDataTableController<ProductRow>(
        fetcher: fetchProducts,
        rowId: (p) => p.id,
        pageSize: 10,
      );

  String? _selectedStoreId;
  Set<String> _selected = {};
  bool _dirty = false;

  bool get _canWrite =>
      AuthSession.instance.can(
        'nomencladores',
        'asignacion',
        PermissionAction.write,
      ) ||
      AuthSession.instance.can(
        'nomencladores',
        'asignacion',
        PermissionAction.edit,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectStore(String storeId) {
    setState(() {
      _selectedStoreId = storeId;
      _selected = Set.of(assignedProductIds(storeId));
      _dirty = false;
    });
  }

  void _toggle(String productId) {
    setState(() {
      _selected.contains(productId)
          ? _selected.remove(productId)
          : _selected.add(productId);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stores = allStoresUnpaged;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignación de Productos a Tienda', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'Define qué productos puede vender cada tienda.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _StorePicker(
            stores: stores,
            selectedId: _selectedStoreId,
            onSelect: _selectStore,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_selectedStoreId == null)
            Expanded(
              child: Center(
                child: Text(
                  'Selecciona una tienda para editar su catálogo asignado.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selected.length} producto(s) asignado(s)',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_dirty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '· cambios sin guardar',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.statusReview,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_canWrite)
                  AsyncActionButton(
                    label: 'Guardar asignación',
                    loadingLabel: 'Guardando...',
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 800));
                      setStoreAssignments(_selectedStoreId!, _selected);
                      setState(() => _dirty = false);
                      final store = findStoreById(_selectedStoreId!);
                      ToastService.success(
                        'El catálogo de "${store?.name}" se actualizó correctamente.',
                        title: 'Asignación guardada',
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: AppDataTable<ProductRow>(
                controller: _controller,
                searchHint: 'Buscar producto...',
                columns: [
                  AppDataColumn<ProductRow>(
                    id: 'assigned',
                    label: '',
                    width: 48,
                    cellBuilder: (context, row) => Checkbox(
                      value: _selected.contains(row.id),
                      onChanged: _canWrite ? (_) => _toggle(row.id) : null,
                    ),
                  ),
                  AppDataColumn<ProductRow>(
                    id: 'name',
                    label: 'Producto',
                    flex: 3,
                    cellBuilder: (context, row) => Text(
                      row.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppDataColumn<ProductRow>(
                    id: 'sku',
                    label: 'SKU',
                    flex: 2,
                    cellBuilder: (context, row) =>
                        Text(row.sku, style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StorePicker extends StatelessWidget {
  const _StorePicker({
    required this.stores,
    required this.selectedId,
    required this.onSelect,
  });
  final List<StoreRow> stores;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final store = stores[index];
          final active = store.id == selectedId;
          return ChoiceChip(
            label: Text(store.name),
            selected: active,
            onSelected: (_) => onSelect(store.id),
            selectedColor: AppColors.primary.withValues(alpha: 0.16),
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: active ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.border,
            ),
            backgroundColor: AppColors.surface,
          );
        },
      ),
    );
  }
}
