import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_field.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../../../core/widgets/status_dot_pill.dart';
import '../../data/stores_mock_data.dart';
import 'store_card.dart' show storeStatusColor;

String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

String? _intValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
  if (int.tryParse(v.trim()) == null) return 'Ingresa un número entero';
  return null;
}

String? _numberValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
  if (double.tryParse(v.trim()) == null) return 'Ingresa un número válido';
  return null;
}

/// Create/edit dialog for a store. Confirming validates, simulates the
/// request, mutates the in-memory catalog, refreshes the caller and
/// shows a toast — same pattern as the product dialogs.
Future<void> showStoreFormDialog(
  BuildContext context, {
  StoreRow? store,
  required VoidCallback onSaved,
}) {
  final isEdit = store != null;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: store?.name ?? '');
  final cityController = TextEditingController(text: store?.city ?? '');
  final addressController = TextEditingController(text: store?.address ?? '');
  final phoneController = TextEditingController(text: store?.phone ?? '');
  final managerController = TextEditingController(text: store?.managerName ?? '');
  final employeesController = TextEditingController(text: store?.employees.toString() ?? '');
  final salesController = TextEditingController(text: store?.monthlySales.toStringAsFixed(0) ?? '');
  final statusNotifier = ValueNotifier<StoreStatus>(store?.status ?? StoreStatus.active);

  return showAppDialog(
    context: context,
    title: isEdit ? 'Editar tienda' : 'Nueva tienda',
    width: 560,
    contentBuilder: (_) {
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFormField(label: 'Nombre de la tienda', controller: nameController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AppFormField(label: 'Ciudad', controller: cityController, validator: _requiredValidator)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: AppFormField(label: 'Teléfono', controller: phoneController, validator: _requiredValidator)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppFormField(label: 'Dirección', controller: addressController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            AppFormField(label: 'Encargado', controller: managerController, validator: _requiredValidator),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    label: 'Empleados',
                    controller: employeesController,
                    keyboardType: TextInputType.number,
                    validator: _intValidator,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppFormField(
                    label: 'Ventas mensuales',
                    controller: salesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Estado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            ValueListenableBuilder<StoreStatus>(
              valueListenable: statusNotifier,
              builder: (context, status, _) => Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final s in StoreStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: status == s,
                      onSelected: (_) => statusNotifier.value = s,
                      selectedColor: storeStatusColor(s).withValues(alpha: 0.16),
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: status == s ? storeStatusColor(s) : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(color: status == s ? storeStatusColor(s) : AppColors.border),
                      backgroundColor: AppColors.surface,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: isEdit ? 'Guardar cambios' : 'Crear tienda',
        loadingLabel: isEdit ? 'Guardando...' : 'Creando...',
        onPressed: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          await Future.delayed(const Duration(milliseconds: 1100));

          final String id;
          final String code;
          if (store != null) {
            id = store.id;
            code = store.code;
          } else {
            final identity = nextStoreIdentity();
            id = identity.id;
            code = identity.code;
          }

          upsertStore(StoreRow(
            id: id,
            code: code,
            name: nameController.text.trim(),
            city: cityController.text.trim(),
            address: addressController.text.trim(),
            phone: phoneController.text.trim(),
            managerName: managerController.text.trim(),
            status: statusNotifier.value,
            employees: int.parse(employeesController.text.trim()),
            monthlySales: double.parse(salesController.text.trim()),
            openedAt: store?.openedAt ?? DateTime.now(),
          ));

          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          ToastService.success(
            isEdit ? 'Los cambios de "${nameController.text.trim()}" se guardaron correctamente.' : '"${nameController.text.trim()}" se creó correctamente.',
            title: isEdit ? 'Tienda actualizada' : 'Tienda creada',
          );
        },
      ),
    ],
  );
}

Future<void> showStoreDeleteDialog(
  BuildContext context,
  StoreRow store, {
  required VoidCallback onDeleted,
}) {
  return showAppDialog(
    context: context,
    title: 'Eliminar tienda',
    width: 420,
    contentBuilder: (_) => Text(
      '¿Seguro que deseas eliminar "${store.name}"? Esta acción no se puede deshacer.',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: 'Eliminar',
        loadingLabel: 'Eliminando...',
        icon: Icons.delete_outline_rounded,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 900));
          deleteStore(store.id);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onDeleted();
          ToastService.success('"${store.name}" se eliminó correctamente.', title: 'Tienda eliminada');
        },
      ),
    ],
  );
}

Future<void> showStoreDetailDialog(
  BuildContext context,
  StoreRow store, {
  required VoidCallback onSaved,
}) {
  return showAppDialog(
    context: context,
    title: 'Detalle de la tienda',
    width: 480,
    contentBuilder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Código', value: store.code),
        _DetailRow(label: 'Nombre', value: store.name),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text('Estado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
              StatusDotPill(label: store.status.label, color: storeStatusColor(store.status)),
            ],
          ),
        ),
        _DetailRow(label: 'Ciudad', value: store.city),
        _DetailRow(label: 'Dirección', value: store.address),
        _DetailRow(label: 'Teléfono', value: store.phone),
        _DetailRow(label: 'Encargado', value: store.managerName),
        _DetailRow(label: 'Empleados', value: '${store.employees}'),
        _DetailRow(label: 'Ventas mensuales', value: '\$${store.monthlySales.toStringAsFixed(2)}'),
        _DetailRow(label: 'Apertura', value: '${store.openedAt.day}/${store.openedAt.month}/${store.openedAt.year}'),
      ],
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar')),
      const SizedBox(width: AppSpacing.sm),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.of(dialogContext).pop();
          showStoreFormDialog(context, store: store, onSaved: onSaved);
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
