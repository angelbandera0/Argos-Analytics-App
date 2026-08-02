import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/products_mock_data.dart';

/// `/dashboard/existencias` — Inventario > Existencias.
///
/// Read-only view of how much of each product sits at a given location
/// (Almacén Central or a specific store's own warehouse). This is the
/// number Traslados and Ventas actually move — never edited by hand.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _locationId = kCentralWarehouseId;

  late final AppDataTableController<ProductRow> _controller = AppDataTableController<ProductRow>(
    fetcher: _fetchStockRows,
    rowId: (p) => p.id,
    pageSize: 12,
    initialSort: const AppDataSort('name', AppSortDirection.ascending),
  );

  Future<AppDataResult<ProductRow>> _fetchStockRows(AppDataRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var items = List<ProductRow>.from(allProducts);

    if (request.search != null && request.search!.trim().isNotEmpty) {
      final q = request.search!.trim().toLowerCase();
      items = items.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
    }

    items.sort((a, b) {
      if (request.sort?.columnId == 'stock') {
        return stockAt(_locationId, a.id).compareTo(stockAt(_locationId, b.id));
      }
      return a.name.compareTo(b.name);
    });
    if (request.sort?.direction == AppSortDirection.descending) items = items.reversed.toList();

    final total = items.length;
    final start = (request.page - 1) * request.pageSize;
    final end = (start + request.pageSize).clamp(0, total);
    final pageItems = start >= total ? <ProductRow>[] : items.sublist(start, end);
    return AppDataResult(items: pageItems, totalCount: total);
  }

  void _selectLocation(String id) {
    if (id == _locationId) return;
    setState(() => _locationId = id);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = inventoryLocations;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Existencias', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('Consulta cuánto stock hay en el Almacén Central o en cada tienda.', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: locations.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final loc = locations[index];
                final active = loc.id == _locationId;
                return ChoiceChip(
                  avatar: Icon(loc.isCentral ? Icons.warehouse_rounded : Icons.storefront_rounded, size: 16, color: active ? AppColors.primary : AppColors.textMuted),
                  label: Text(loc.label),
                  selected: active,
                  onSelected: (_) => _selectLocation(loc.id),
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  labelStyle: AppTextStyles.bodySmall.copyWith(color: active ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w700),
                  side: BorderSide(color: active ? AppColors.primary : AppColors.border),
                  backgroundColor: AppColors.surface,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<ProductRow>(
              controller: _controller,
              searchHint: 'Buscar producto...',
              columns: [
                AppDataColumn<ProductRow>(
                  id: 'name',
                  label: 'Producto',
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
                  id: 'stock',
                  label: 'Existencia',
                  flex: 1,
                  sortable: true,
                  minWidth: 120,
                  cellBuilder: (context, row) {
                    final qty = stockAt(_locationId, row.id);
                    final low = qty < 10;
                    return Text(
                      '$qty',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: low ? AppColors.error : AppColors.textPrimary),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
