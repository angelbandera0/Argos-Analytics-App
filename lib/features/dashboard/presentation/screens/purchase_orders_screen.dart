import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../data/inventory_mock_data.dart';
import '../widgets/purchase_order_dialogs.dart';

/// `/dashboard/ordenes-compra` — Inventario > Órdenes de Compra.
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  late final AppDataTableController<PurchaseOrder> _controller = AppDataTableController<PurchaseOrder>(
    fetcher: fetchPurchaseOrders,
    rowId: (o) => o.id,
    pageSize: 10,
  );

  bool get _canWrite => AuthSession.instance.can('inventario', 'ordenes-compra', PermissionAction.write);

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
                  Text('Órdenes de Compra', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('Cada orden recibida entra al Almacén Central y actualiza el costo del producto.', style: AppTextStyles.bodySmall),
                ],
              ),
              if (_canWrite)
                ElevatedButton.icon(
                  onPressed: () => showPurchaseOrderFormDialog(context, onSaved: _controller.refresh),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Nueva Orden'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AppDataTable<PurchaseOrder>(
              controller: _controller,
              searchHint: 'Buscar por proveedor o folio...',
              columns: [
                AppDataColumn<PurchaseOrder>(
                  id: 'code',
                  label: 'Folio',
                  width: 110,
                  cellBuilder: (context, row) => Text(row.code, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                ),
                AppDataColumn<PurchaseOrder>(
                  id: 'supplier',
                  label: 'Proveedor',
                  flex: 3,
                  cellBuilder: (context, row) => Text(row.supplier, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                AppDataColumn<PurchaseOrder>(
                  id: 'lines',
                  label: 'Líneas',
                  minWidth: 90,
                  cellBuilder: (context, row) => Text('${row.lines.length}', style: AppTextStyles.bodySmall),
                ),
                AppDataColumn<PurchaseOrder>(
                  id: 'total',
                  label: 'Total',
                  minWidth: 110,
                  cellBuilder: (context, row) => Text('\$${row.total.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                ),
                AppDataColumn<PurchaseOrder>(
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
