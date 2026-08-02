import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/auth/permission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_table/app_data_table.dart';
import '../../../../core/widgets/data_table/widgets/data_table_pagination.dart';
import '../../data/stores_mock_data.dart';
import '../widgets/stat_card.dart';
import '../widgets/store_card.dart';
import '../widgets/store_dialogs.dart';

/// `/dashboard/tiendas` (Nomencladores > Gestión de Tiendas).
///
/// Deliberately not another data table — reuses the same underlying
/// engine ([AppDataTableController]: async loading, search, filters,
/// sort, pagination) but renders it as a responsive grid of
/// [StoreCard]s for a more visual, "at a glance" management surface,
/// with a small stats header on top.
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  late final AppDataTableController<StoreRow> _controller = AppDataTableController<StoreRow>(
    fetcher: fetchStores,
    rowId: (s) => s.id,
    pageSize: 9,
    initialSort: const AppDataSort('name', AppSortDirection.ascending),
  );

  late final TextEditingController _searchController = TextEditingController();

  bool get _canWrite => AuthSession.instance.can('nomencladores', 'tiendas', PermissionAction.write);
  bool get _canEdit => AuthSession.instance.can('nomencladores', 'tiendas', PermissionAction.edit);
  bool get _canDelete => AuthSession.instance.can('nomencladores', 'tiendas', PermissionAction.delete);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
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
                  Text('Gestión de Tiendas', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('Administra las sucursales, su personal y su desempeño.', style: AppTextStyles.bodySmall),
                ],
              ),
              if (_canWrite)
                ElevatedButton.icon(
                  onPressed: () => showStoreFormDialog(context, onSaved: _controller.refresh),
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  label: const Text('Nueva Tienda'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Rebuilds whenever the controller refreshes (after create/edit/
          // delete), so the totals never go stale.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final stats = storeStats();
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  StatCard(icon: Icons.storefront_rounded, value: '${stats.total}', label: 'Tiendas totales', accent: AppColors.primary),
                  StatCard(icon: Icons.check_circle_outline_rounded, value: '${stats.active}', label: 'Activas', accent: AppColors.success),
                  StatCard(icon: Icons.groups_2_outlined, value: '${stats.employees}', label: 'Empleados', accent: AppColors.statusInProgress),
                  StatCard(icon: Icons.payments_outlined, value: '\$${stats.sales.toStringAsFixed(0)}', label: 'Ventas / mes', accent: AppColors.statusReview),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _Toolbar(controller: _controller, searchController: _searchController),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.items.isEmpty) {
                  return const _GridSkeleton();
                }
                if (_controller.error != null) {
                  return _StateMessage(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.error,
                    title: 'No se pudieron cargar las tiendas',
                    action: TextButton(onPressed: _controller.refresh, child: const Text('Reintentar')),
                  );
                }
                if (_controller.items.isEmpty) {
                  return const _StateMessage(icon: Icons.storefront_outlined, color: AppColors.textMuted, title: 'No hay tiendas que coincidan');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1300
                              ? 4
                              : constraints.maxWidth >= 980
                                  ? 3
                                  : constraints.maxWidth >= 620
                                      ? 2
                                      : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisExtent: 300,
                            ),
                            itemCount: _controller.items.length,
                            itemBuilder: (context, index) {
                              final store = _controller.items[index];
                              return StoreCard(
                                store: store,
                                onTap: () => showStoreDetailDialog(context, store, onSaved: _controller.refresh),
                                onEdit: _canEdit ? () => showStoreFormDialog(context, store: store, onSaved: _controller.refresh) : null,
                                onDelete: _canDelete ? () => showStoreDeleteDialog(context, store, onDeleted: _controller.refresh) : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DataTablePagination<StoreRow>(controller: _controller),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller, required this.searchController});
  final AppDataTableController<StoreRow> controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: controller.setSearch,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, ciudad o encargado...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusFilterMenu(controller: controller),
            const SizedBox(width: AppSpacing.sm),
            _CityFilterMenu(controller: controller),
            if (controller.hasActiveFilters) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {
                  searchController.clear();
                  controller.clearFilters();
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatusFilterMenu extends StatelessWidget {
  const _StatusFilterMenu({required this.controller});
  final AppDataTableController<StoreRow> controller;

  @override
  Widget build(BuildContext context) {
    final active = controller.filters['status'] ?? const <String>{};
    return PopupMenuButton<String>(
      tooltip: 'Estado',
      itemBuilder: (context) => [
        for (final s in StoreStatus.values)
          PopupMenuItem(
            value: s.value,
            onTap: () {
              final next = Set<String>.from(active);
              next.contains(s.value) ? next.remove(s.value) : next.add(s.value);
              controller.setFilter('status', next);
            },
            child: Row(
              children: [
                Icon(
                  active.contains(s.value) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: active.contains(s.value) ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(s.label, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
      ],
      child: _FilterPillLabel(label: 'Estado', count: active.length),
    );
  }
}

class _CityFilterMenu extends StatelessWidget {
  const _CityFilterMenu({required this.controller});
  final AppDataTableController<StoreRow> controller;

  @override
  Widget build(BuildContext context) {
    final active = controller.filters['city'] ?? const <String>{};
    return PopupMenuButton<String>(
      tooltip: 'Ciudad',
      itemBuilder: (context) => [
        for (final c in storeCities)
          PopupMenuItem(
            value: c,
            onTap: () {
              final next = Set<String>.from(active);
              next.contains(c) ? next.remove(c) : next.add(c);
              controller.setFilter('city', next);
            },
            child: Row(
              children: [
                Icon(
                  active.contains(c) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: active.contains(c) ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(c, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
      ],
      child: _FilterPillLabel(label: 'Ciudad', count: active.length),
    );
  }
}

class _FilterPillLabel extends StatelessWidget {
  const _FilterPillLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: active ? AppColors.primary : AppColors.border),
        color: active ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune_rounded, size: 16, color: active ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(active ? '$label ($count)' : label, style: AppTextStyles.bodySmall.copyWith(color: active ? AppColors.primary : AppColors.textSecondary)),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1300
            ? 4
            : constraints.maxWidth >= 980
                ? 3
                : constraints.maxWidth >= 620
                    ? 2
                    : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 300,
          ),
          itemCount: columns * 2,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        );
      },
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.color, required this.title, this.action});
  final IconData icon;
  final Color color;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
        ],
      ),
    );
  }
}
