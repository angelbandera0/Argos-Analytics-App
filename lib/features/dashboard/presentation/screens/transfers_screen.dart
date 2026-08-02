import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/stores_mock_data.dart';
import '../widgets/transfer_dialogs.dart';

/// `/dashboard/traslados` — Inventario > Traslados.
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  late final AppDataTableController<InventoryTransfer> _controller = AppDataTableController<InventoryTransfer>(
    fetcher: fetchTransfers,
    rowId: (t) => t.id,
    pageSize: 10,
  );

  bool get _canWrite => AuthSession.instance.can('inventario', 'traslados', PermissionAction.write);

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
                  Text('Traslados', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('Mueve stock del Almacén Central al almacén de una tienda.', style: AppTextStyles.bodySmall),
                ],
              ),
              if (_canWrite)
                ElevatedButton.icon(
                  onPressed: () => showTransferFormDialog(context, onSaved: _controller.refresh),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Nuevo Traslado'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<InventoryTransfer>(
              controller: _controller,
              searchHint: 'Buscar...',
              searchable: false,
              filters: [
                AppDataFilter(
                  id: 'store',
                  label: 'Tienda',
                  options: [for (final s in allStoresUnpaged) AppFilterOption(s.id, s.name)],
                ),
              ],
              columns: [
                AppDataColumn<InventoryTransfer>(
                  id: 'code',
                  label: 'Folio',
                  width: 110,
                  cellBuilder: (context, row) => Text(row.code, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                ),
                AppDataColumn<InventoryTransfer>(
                  id: 'store',
                  label: 'Tienda destino',
                  flex: 3,
                  cellBuilder: (context, row) => Text(findStoreById(row.storeId)?.name ?? '—', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                AppDataColumn<InventoryTransfer>(
                  id: 'lines',
                  label: 'Líneas',
                  minWidth: 90,
                  cellBuilder: (context, row) => Text('${row.lines.length}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<InventoryTransfer>(
                  id: 'units',
                  label: 'Unidades',
                  minWidth: 100,
                  cellBuilder: (context, row) => Text('${row.lines.fold<int>(0, (sum, l) => sum + l.quantity)}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<InventoryTransfer>(
                  id: 'date',
                  label: 'Fecha',
                  minWidth: 110,
                  cellBuilder: (context, row) => Text('${row.date.day}/${row.date.month}/${row.date.year}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
