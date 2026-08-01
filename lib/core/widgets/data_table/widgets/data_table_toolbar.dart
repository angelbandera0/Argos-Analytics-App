import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_text_styles.dart';
import '../app_data_table_controller.dart';
import '../models/app_data_filter.dart';

/// Search box + one dropdown per configured [AppDataFilter] + a
/// "Clear filters" action that only appears once something is active.
class DataTableToolbar<T> extends StatefulWidget {
  const DataTableToolbar({
    super.key,
    required this.controller,
    required this.filters,
    required this.searchable,
    required this.searchHint,
  });

  final AppDataTableController<T> controller;
  final List<AppDataFilter> filters;
  final bool searchable;
  final String searchHint;

  @override
  State<DataTableToolbar<T>> createState() => _DataTableToolbarState<T>();
}

class _DataTableToolbarState<T> extends State<DataTableToolbar<T>> {
  late final TextEditingController _searchController =
      TextEditingController(text: widget.controller.search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Row(
          children: [
            if (widget.searchable)
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.controller.setSearch,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
              ),
            if (widget.searchable) const SizedBox(width: AppSpacing.sm),
            for (final filter in widget.filters) ...[
              _FilterDropdown(controller: widget.controller, filter: filter),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (widget.controller.hasActiveFilters)
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  widget.controller.clearFilters();
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
          ],
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.controller, required this.filter});

  final AppDataTableController controller;
  final AppDataFilter filter;

  @override
  Widget build(BuildContext context) {
    final active = controller.filters[filter.id] ?? <String>{};

    return PopupMenuButton<String>(
      tooltip: filter.label,
      itemBuilder: (context) => [
        for (final option in filter.options)
          PopupMenuItem<String>(
            value: option.value,
            onTap: () {
              final next = Set<String>.from(active);
              if (filter.multiple) {
                next.contains(option.value) ? next.remove(option.value) : next.add(option.value);
              } else {
                next
                  ..clear()
                  ..add(option.value);
              }
              // PopupMenuButton closes before onTap's setState would apply,
              // so mutate the controller directly (safe: it's a ChangeNotifier).
              controller.setFilter(filter.id, next);
            },
            child: Row(
              children: [
                Icon(
                  active.contains(option.value) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: active.contains(option.value) ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(option.label, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: active.isNotEmpty ? AppColors.primary : AppColors.border),
          color: active.isNotEmpty ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 16, color: active.isNotEmpty ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              active.isEmpty ? filter.label : '${filter.label} (${active.length})',
              style: AppTextStyles.bodySmall.copyWith(color: active.isNotEmpty ? AppColors.primary : AppColors.textSecondary),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
