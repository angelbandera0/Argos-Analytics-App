import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_field.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../data/inventory_mock_data.dart';
import '../../data/products_mock_data.dart';
import 'order_lines_editor.dart';

String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

/// Creating a Purchase Order always brings stock into the Almacén
/// Central (never directly into a store) and updates each line's
/// product cost — see `receivePurchaseOrder` in `inventory_mock_data.dart`.
Future<void> showPurchaseOrderFormDialog(
  BuildContext context, {
  required VoidCallback onSaved,
}) {
  final formKey = GlobalKey<FormState>();
  final supplierController = TextEditingController();
  final linesKey = GlobalKey<OrderLinesEditorState>();

  return showAppDialog(
    context: context,
    title: 'Nueva Orden de Compra',
    width: 620,
    contentBuilder: (_) {
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormField(label: 'Proveedor', controller: supplierController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.lg),
            Text('Productos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            OrderLinesEditor(
              key: linesKey,
              products: allProducts,
              showUnitValue: true,
              unitValueLabel: 'Costo unitario',
            ),
          ],
        ),
      );
    },
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: 'Registrar orden',
        loadingLabel: 'Registrando...',
        onPressed: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          final lines = linesKey.currentState?.validLines ?? const [];
          if (lines.isEmpty || lines.any((l) => l.unitValue == null || l.unitValue! <= 0)) {
            ToastService.warning('Agrega al menos un producto con costo unitario válido.', title: 'Faltan datos');
            return;
          }

          await Future.delayed(const Duration(milliseconds: 1100));

          receivePurchaseOrder(PurchaseOrder(
            id: nextPurchaseOrderId(),
            code: nextPurchaseOrderCode(),
            supplier: supplierController.text.trim(),
            date: DateTime.now(),
            lines: [
              for (final l in lines) PurchaseOrderLine(productId: l.productId!, quantity: l.quantity, unitCost: l.unitValue!),
            ],
          ));

          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          ToastService.success('La mercancía se agregó al Almacén Central y los costos se actualizaron.', title: 'Orden de compra registrada');
        },
      ),
    ],
  );
}
