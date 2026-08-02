import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/products_mock_data.dart';
import '../../data/stores_mock_data.dart';
import 'order_lines_editor.dart';

/// Moves stock from the Almacén Central into one store's own warehouse.
/// The product picker is limited to whatever that store was assigned in
/// "Asignación de Productos a Tienda" — you shouldn't be able to stock a
/// store with something it isn't set up to sell.
Future<void> showTransferFormDialog(
  BuildContext context, {
  required VoidCallback onSaved,
}) {
  final stores = allStoresUnpaged;
  final storeNotifier = ValueNotifier<String?>(stores.isEmpty ? null : stores.first.id);
  final linesKey = GlobalKey<OrderLinesEditorState>();

  return showAppDialog(
    context: context,
    title: 'Nuevo Traslado',
    width: 620,
    contentBuilder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tienda destino', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<String?>(
            valueListenable: storeNotifier,
            builder: (context, storeId, _) {
              final assignedIds = storeId == null ? const <String>{} : assignedProductIds(storeId);
              final availableProducts = allProducts.where((p) => assignedIds.contains(p.id)).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: storeId,
                    items: [for (final s in stores) DropdownMenuItem(value: s.id, child: Text(s.name))],
                    onChanged: (value) => storeNotifier.value = value,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Productos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  if (availableProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text(
                        'Esta tienda no tiene productos asignados todavía. Ve a "Asignación de Productos a Tienda" primero.',
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  else
                    OrderLinesEditor(key: linesKey, products: availableProducts),
                ],
              );
            },
          ),
        ],
      );
    },
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: 'Confirmar traslado',
        loadingLabel: 'Trasladando...',
        onPressed: () async {
          final storeId = storeNotifier.value;
          final lines = linesKey.currentState?.validLines ?? const [];
          if (storeId == null || lines.isEmpty) {
            ToastService.warning('Selecciona una tienda y al menos un producto.', title: 'Faltan datos');
            return;
          }

          await Future.delayed(const Duration(milliseconds: 1000));

          final shortfalls = createTransfer(InventoryTransfer(
            id: nextTransferId(),
            code: nextTransferCode(),
            storeId: storeId,
            date: DateTime.now(),
            lines: [for (final l in lines) TransferLine(productId: l.productId!, quantity: l.quantity)],
          ));

          if (shortfalls.isNotEmpty) {
            final names = shortfalls.map((id) => findProductById(id)?.name ?? id).join(', ');
            ToastService.error('No hay suficiente stock en el Almacén Central para: $names.', title: 'Traslado no realizado');
            return;
          }

          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          final store = findStoreById(storeId);
          ToastService.success('El stock se movió al almacén de "${store?.name}".', title: 'Traslado completado');
        },
      ),
    ],
  );
}
