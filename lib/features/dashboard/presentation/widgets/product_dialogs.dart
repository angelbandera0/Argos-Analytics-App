import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_field.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../data/products_mock_data.dart';
import 'status_pill.dart';

String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

String? _numberValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
  if (double.tryParse(v.trim()) == null) return 'Ingresa un número válido';
  return null;
}

String? _intValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
  if (int.tryParse(v.trim()) == null) return 'Ingresa un número entero';
  return null;
}

/// Opens the create/edit product dialog. Pass [product] to edit an
/// existing row, or omit it to create a new one. Confirming: validates
/// the form, simulates a network request, mutates the in-memory catalog,
/// closes the dialog, calls [onSaved] (typically `controller.refresh`)
/// and shows a success toast.
Future<void> showProductFormDialog(
  BuildContext context, {
  ProductRow? product,
  required VoidCallback onSaved,
}) {
  final isEdit = product != null;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: product?.name ?? '');
  final skuController = TextEditingController(text: product?.sku ?? '');
  final priceController = TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
  final costController = TextEditingController(text: product?.cost.toStringAsFixed(2) ?? '');
  final stockController = TextEditingController(text: product?.stock.toString() ?? '');
  final statusNotifier = ValueNotifier<ProductStatus>(product?.status ?? ProductStatus.active);

  return showAppDialog(
    context: context,
    title: isEdit ? 'Editar producto' : 'Nuevo producto',
    width: 520,
    contentBuilder: (dialogContext) {
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormField(label: 'Nombre', controller: nameController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            AppFormField(label: 'SKU', controller: skuController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'Precio',
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberValidator,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppFormField(
                    label: 'Costo',
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'Stock',
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    validator: _intValidator,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.xs),
                      ValueListenableBuilder<ProductStatus>(
                        valueListenable: statusNotifier,
                        builder: (context, status, _) {
                          return DropdownButtonFormField<ProductStatus>(
                            value: status,
                            items: [
                              for (final s in ProductStatus.values)
                                DropdownMenuItem(value: s, child: Text(s.label, style: AppTextStyles.bodyMedium)),
                            ],
                            onChanged: (value) {
                              if (value != null) statusNotifier.value = value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
    actionsBuilder: (dialogContext) => [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: isEdit ? 'Guardar cambios' : 'Crear producto',
        loadingLabel: isEdit ? 'Guardando...' : 'Creando...',
        onPressed: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;

          // Simulated request — swap for a real API call.
          await Future.delayed(const Duration(milliseconds: 1100));

          final String id;
          final String code;
          if (product != null) {
            id = product.id;
            code = product.code;
          } else {
            final identity = nextProductIdentity();
            id = identity.id;
            code = identity.code;
          }

          upsertProduct(ProductRow(
            id: id,
            code: code,
            name: nameController.text.trim(),
            sku: skuController.text.trim(),
            status: statusNotifier.value,
            price: double.parse(priceController.text.trim()),
            cost: double.parse(costController.text.trim()),
            stock: int.parse(stockController.text.trim()),
            sales: product?.sales ?? 0,
          ));

          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          ToastService.success(
            isEdit ? 'Los cambios de "${nameController.text.trim()}" se guardaron correctamente.' : '"${nameController.text.trim()}" se creó correctamente.',
            title: isEdit ? 'Producto actualizado' : 'Producto creado',
          );
        },
      ),
    ],
  );
}

/// Confirms and simulates deleting a product.
Future<void> showProductDeleteDialog(
  BuildContext context,
  ProductRow product, {
  required VoidCallback onDeleted,
}) {
  return showAppDialog(
    context: context,
    title: 'Eliminar producto',
    width: 420,
    contentBuilder: (_) => Text(
      '¿Seguro que deseas eliminar "${product.name}"? Esta acción no se puede deshacer.',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: 'Eliminar',
        loadingLabel: 'Eliminando...',
        icon: Icons.delete_outline_rounded,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 900));
          deleteProduct(product.id);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onDeleted();
          ToastService.success('"${product.name}" se eliminó correctamente.', title: 'Producto eliminado');
        },
      ),
    ],
  );
}

/// Read-only product detail dialog, with a shortcut into the edit dialog.
Future<void> showProductDetailDialog(
  BuildContext context,
  ProductRow product, {
  required VoidCallback onSaved,
}) {
  return showAppDialog(
    context: context,
    title: 'Detalle del producto',
    width: 480,
    contentBuilder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'ID', value: product.code),
        _DetailRow(label: 'Nombre', value: product.name),
        _DetailRow(label: 'SKU', value: product.sku),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text('Estado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
              StatusPill(status: product.status),
            ],
          ),
        ),
        _DetailRow(label: 'Precio', value: '\$${product.price.toStringAsFixed(2)}'),
        _DetailRow(label: 'Costo', value: '\$${product.cost.toStringAsFixed(2)}'),
        _DetailRow(label: 'Stock', value: '${product.stock}'),
        _DetailRow(label: 'Ventas', value: '${product.sales}'),
      ],
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Cerrar'),
      ),
      const SizedBox(width: AppSpacing.sm),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.of(dialogContext).pop();
          showProductFormDialog(context, product: product, onSaved: onSaved);
        },
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Editar'),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
