import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/products_mock_data.dart';
import '../../data/stores_mock_data.dart';
import '../widgets/order_lines_editor.dart';

/// `/dashboard/ventas-registrar` — Ventas > Registrar Venta.
///
/// A store's own warehouse is what a sale deducts from, so the product
/// picker here is limited to whatever that store was assigned (same
/// rule as Traslados) — and further limited to what's actually in stock
/// right now, so nobody can sell something the store doesn't have.
class RegisterSaleScreen extends StatefulWidget {
  const RegisterSaleScreen({super.key});

  @override
  State<RegisterSaleScreen> createState() => _RegisterSaleScreenState();
}

class _RegisterSaleScreenState extends State<RegisterSaleScreen> {
  String? _storeId;
  List<OrderLineDraft> _currentLines = [];
  int _formVersion = 0;

  @override
  void initState() {
    super.initState();
    final stores = allStoresUnpaged;
    if (stores.isNotEmpty) _storeId = stores.first.id;
  }

  double get _total => _currentLines.fold(0, (sum, l) => sum + (l.quantity * (l.unitValue ?? 0)));

  @override
  Widget build(BuildContext context) {
    final stores = allStoresUnpaged;
    final assignedIds = _storeId == null ? const <String>{} : assignedProductIds(_storeId!);
    final availableProducts = allProducts.where((p) => assignedIds.contains(p.id) && stockAt(_storeId!, p.id) > 0).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registrar Venta', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('Descuenta automáticamente del almacén de la tienda seleccionada.', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tienda', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    value: _storeId,
                    items: [for (final s in stores) DropdownMenuItem(value: s.id, child: Text(s.name))],
                    onChanged: (value) => setState(() => _storeId = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Productos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  if (availableProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text('Esta tienda no tiene productos con existencia disponible.', style: AppTextStyles.bodySmall),
                    )
                  else
                    OrderLinesEditor(
                      key: ValueKey('${_storeId}_$_formVersion'),
                      products: availableProducts,
                      showUnitValue: true,
                      unitValueLabel: 'Precio unitario',
                      defaultUnitValue: (productId) => findProductById(productId)?.price,
                      onChanged: (lines) => setState(() => _currentLines = lines),
                    ),
                  const Divider(height: AppSpacing.xl, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.h3),
                      Text('\$${_total.toStringAsFixed(2)}', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: AsyncActionButton(
                      label: 'Registrar venta',
                      loadingLabel: 'Procesando...',
                      icon: Icons.point_of_sale_rounded,
                      onPressed: () async {
                        final storeId = _storeId;
                        final lines = _currentLines;
                        if (storeId == null || lines.isEmpty) {
                          ToastService.warning('Selecciona una tienda y al menos un producto.', title: 'Faltan datos');
                          return;
                        }

                        await Future.delayed(const Duration(milliseconds: 900));

                        final shortfalls = registerSale(Sale(
                          id: nextSaleId(),
                          code: nextSaleCode(),
                          storeId: storeId,
                          date: DateTime.now(),
                          lines: [
                            for (final l in lines) SaleLine(productId: l.productId!, quantity: l.quantity, unitPrice: l.unitValue ?? 0),
                          ],
                        ));

                        if (shortfalls.isNotEmpty) {
                          final names = shortfalls.map((id) => findProductById(id)?.name ?? id).join(', ');
                          ToastService.error('No hay suficiente existencia de: $names.', title: 'Venta no registrada');
                          return;
                        }

                        final total = _total;
                        setState(() {
                          _currentLines = [];
                          _formVersion++;
                        });
                        ToastService.success('Venta por \$${total.toStringAsFixed(2)} registrada correctamente.', title: 'Venta registrada');
                      },
                    ),
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
