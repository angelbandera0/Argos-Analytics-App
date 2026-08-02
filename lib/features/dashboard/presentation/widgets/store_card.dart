import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/status_dot_pill.dart';
import '../../data/stores_mock_data.dart';

Color storeStatusColor(StoreStatus status) => switch (status) {
      StoreStatus.active => AppColors.success,
      StoreStatus.inactive => AppColors.textMuted,
      StoreStatus.maintenance => AppColors.statusReview,
    };

/// Visual card representing one store — this is the "attractive,
/// professional" surface the person asked for instead of a plain table
/// row: an accent header strip, a monogram avatar, key metrics and
/// quick actions, laid out to look good in a responsive grid.
class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final StoreRow store;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = storeStatusColor(store.status);
    final currency = '\$${store.monthlySales.toStringAsFixed(0)}';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent strip ties the card's color to its status at a glance.
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: Text(
                            store.name.isNotEmpty ? store.name[0].toUpperCase() : '?',
                            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                              Text(store.code, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                            itemBuilder: (context) => [
                              if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text('Editar')),
                              if (onDelete != null) const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') onEdit?.call();
                              if (value == 'delete') onDelete?.call();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StatusDotPill(label: store.status.label, color: accent),
                    const SizedBox(height: AppSpacing.md),
                    _InfoLine(icon: Icons.location_on_outlined, text: '${store.address}, ${store.city}'),
                    const SizedBox(height: 6),
                    _InfoLine(icon: Icons.person_outline_rounded, text: store.managerName),
                    const SizedBox(height: 6),
                    _InfoLine(icon: Icons.call_outlined, text: store.phone),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(icon: Icons.groups_2_outlined, value: '${store.employees}', label: 'Empleados'),
                        ),
                        Expanded(
                          child: _MetricTile(icon: Icons.trending_up_rounded, value: currency, label: 'Ventas / mes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}
