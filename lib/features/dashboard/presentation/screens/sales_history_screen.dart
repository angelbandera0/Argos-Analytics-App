import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/stores_mock_data.dart';
import '../widgets/stat_card.dart';

/// `/dashboard/ventas-historial` — Ventas > Historial de Ventas.
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late final AppDataTableController<Sale> _controller = AppDataTableController<Sale>(
    fetcher: fetchSales,
    rowId: (s) => s.id,
    pageSize: 10,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = salesStats();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de Ventas', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('Todas las ventas registradas, por tienda.', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              StatCard(icon: Icons.receipt_long_rounded, value: '${stats.count}', label: 'Ventas registradas', accent: AppColors.primary),
              StatCard(icon: Icons.payments_outlined, value: '\$${stats.revenue.toStringAsFixed(0)}', label: 'Ingresos totales', accent: AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<Sale>(
              controller: _controller,
              searchable: false,
              filters: [
                AppDataFilter(
                  id: 'store',
                  label: 'Tienda',
                  options: [for (final s in allStoresUnpaged) AppFilterOption(s.id, s.name)],
                ),
              ],
              columns: [
                AppDataColumn<Sale>(
                  id: 'code',
                  label: 'Folio',
                  width: 110,
                  cellBuilder: (context, row) => Text(row.code, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                ),
                AppDataColumn<Sale>(
                  id: 'store',
                  label: 'Tienda',
                  flex: 3,
                  cellBuilder: (context, row) => Text(findStoreById(row.storeId)?.name ?? '—', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                AppDataColumn<Sale>(
                  id: 'lines',
                  label: 'Productos',
                  minWidth: 100,
                  cellBuilder: (context, row) => Text('${row.lines.length}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<Sale>(
                  id: 'total',
                  label: 'Total',
                  minWidth: 110,
                  cellBuilder: (context, row) => Text('\$${row.total.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
                AppDataColumn<Sale>(
                  id: 'date',
                  label: 'Fecha',
                  minWidth: 140,
                  cellBuilder: (context, row) => Text(
                    '${row.date.day}/${row.date.month}/${row.date.year} ${row.date.hour.toString().padLeft(2, '0')}:${row.date.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
