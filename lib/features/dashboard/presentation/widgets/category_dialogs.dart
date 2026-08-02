import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form_field.dart';
import '../../../../core/widgets/async_action_button.dart';
import '../../data/category_mock_data.dart';
import '../../data/products_mock_data.dart';

String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

Future<void> showCategoryFormDialog(
  BuildContext context, {
  CategoryRow? category,
  required VoidCallback onSaved,
}) {
  final isEdit = category != null;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: category?.name ?? '');
  final kindNotifier = ValueNotifier<CategoryKind>(category?.kind ?? CategoryKind.abarrotes);

  return showAppDialog(
    context: context,
    title: isEdit ? 'Editar categoría' : 'Nueva categoría',
    width: 420,
    contentBuilder: (_) => Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormField(label: 'Nombre', controller: nameController, validator: _requiredValidator),
          const SizedBox(height: AppSpacing.md),
          Text('Tipo', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<CategoryKind>(
            valueListenable: kindNotifier,
            builder: (context, kind, _) => Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final k in CategoryKind.values)
                  ChoiceChip(
                    label: Text(k.label),
                    selected: kind == k,
                    onSelected: (_) => kindNotifier.value = k,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
      const SizedBox(width: AppSpacing.sm),
      AsyncActionButton(
        label: isEdit ? 'Guardar cambios' : 'Crear categoría',
        loadingLabel: isEdit ? 'Guardando...' : 'Creando...',
        onPressed: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          await Future.delayed(const Duration(milliseconds: 800));

          upsertCategory(CategoryRow(
            id: category?.id ?? nextCategoryId(),
            name: nameController.text.trim(),
            kind: kindNotifier.value,
          ));

          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          onSaved();
          ToastService.success(
            isEdit ? 'Los cambios de "${nameController.text.trim()}" se guardaron.' : '"${nameController.text.trim()}" se creó correctamente.',
            title: isEdit ? 'Categoría actualizada' : 'Categoría creada',
          );
        },
      ),
    ],
  );
}

Future<void> showCategoryDeleteDialog(
  BuildContext context,
  CategoryRow category, {
  required VoidCallback onDeleted,
}) {
  final inUse = productsInCategory(category.id);

  return showAppDialog(
    context: context,
    title: 'Eliminar categoría',
    width: 420,
    contentBuilder: (_) => Text(
      inUse
          ? 'No puedes eliminar "${category.name}": todavía hay productos asignados a esta categoría. Reasígnalos primero.'
          : '¿Seguro que deseas eliminar "${category.name}"? Esta acción no se puede deshacer.',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
    actionsBuilder: (dialogContext) => [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(inUse ? 'Entendido' : 'Cancelar')),
      if (!inUse) ...[
        const SizedBox(width: AppSpacing.sm),
        AsyncActionButton(
          label: 'Eliminar',
          loadingLabel: 'Eliminando...',
          icon: Icons.delete_outline_rounded,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            await Future.delayed(const Duration(milliseconds: 700));
            deleteCategory(category.id);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            onDeleted();
            ToastService.success('"${category.name}" se eliminó correctamente.', title: 'Categoría eliminada');
          },
        ),
      ],
    ],
  );
}
