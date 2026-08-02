import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_text_styles.dart';
import '../app_data_table_controller.dart';
import '../column_width_resolver.dart';
import '../models/app_data_column.dart';
import '../models/app_data_request.dart';

class DataTableBody<T> extends StatelessWidget {
  const DataTableBody({
    super.key,
    required this.controller,
    required this.columns,
    required this.showSelectionColumn,
    required this.rowActionsBuilder,
    required this.widths,
    required this.onRowTap,
    required this.emptyMessage,
    required this.skeletonRowCount,
  });

  final AppDataTableController<T> controller;
  final List<AppDataColumn<T>> columns;
  final bool showSelectionColumn;
  final Widget Function(BuildContext context, T row)? rowActionsBuilder;
  final ResolvedColumnWidths widths;
  final void Function(T row)? onRowTap;
  final String emptyMessage;
  final int skeletonRowCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading && controller.items.isEmpty) {
          return _SkeletonRows(count: skeletonRowCount, showSelectionColumn: showSelectionColumn, widths: widths);
        }

        if (controller.error != null) {
          return _StateMessage(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error,
            title: 'No se pudieron cargar los datos',
            subtitle: '${controller.error}',
            action: TextButton(onPressed: controller.refresh, child: const Text('Reintentar')),
          );
        }

        if (controller.items.isEmpty) {
          return _StateMessage(icon: Icons.inbox_rounded, iconColor: AppColors.textMuted, title: emptyMessage);
        }

        return Stack(
          children: [
            ListView.separated(
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final row = controller.items[index];
                return _DataRow<T>(
                  row: row,
                  index: index,
                  controller: controller,
                  columns: columns,
                  showSelectionColumn: showSelectionColumn,
                  rowActionsBuilder: rowActionsBuilder,
                  widths: widths,
                  onTap: onRowTap,
                );
              },
            ),
            // Subtle overlay while refetching a page that already has data,
            // so the previous rows stay visible instead of flashing to a
            // blank/skeleton state.
            if (controller.isLoading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: AppColors.surface.withValues(alpha: 0.5)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DataRow<T> extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.index,
    required this.controller,
    required this.columns,
    required this.showSelectionColumn,
    required this.rowActionsBuilder,
    required this.widths,
    required this.onTap,
  });

  final T row;
  final int index;
  final AppDataTableController<T> controller;
  final List<AppDataColumn<T>> columns;
  final bool showSelectionColumn;
  final Widget Function(BuildContext context, T row)? rowActionsBuilder;
  final ResolvedColumnWidths widths;
  final void Function(T row)? onTap;

  @override
  Widget build(BuildContext context) {
    final selected = controller.isSelected(row);

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(row),
      child: Container(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : index.isEven
                ? AppColors.surface
                : AppColors.surfaceMuted.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            if (showSelectionColumn)
              SizedBox(
                width: widths.selectionWidth,
                child: controller.selectionMode == AppDataTableSelectionMode.none
                    ? null
                    : Checkbox(value: selected, onChanged: (_) => controller.toggleRowSelection(row)),
              ),
            for (var i = 0; i < columns.length; i++)
              SizedBox(
                width: widths.columnWidths[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Align(alignment: columns[i].alignment, child: columns[i].cellBuilder(context, row)),
                ),
              ),
            SizedBox(
              width: widths.actionsWidth,
              child: rowActionsBuilder != null
                  ? Align(alignment: Alignment.centerRight, child: rowActionsBuilder!(context, row))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows({required this.count, required this.showSelectionColumn, required this.widths});
  final int count;
  final bool showSelectionColumn;
  final ResolvedColumnWidths widths;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              if (showSelectionColumn) SizedBox(width: widths.selectionWidth),
              for (final w in widths.columnWidths)
                SizedBox(
                  width: w,
                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: _ShimmerBlock()),
                ),
              SizedBox(width: widths.actionsWidth),
            ],
          ),
        );
      },
    );
  }
}

/// Lightweight shimmer without external dependencies: an opacity pulse.
class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock();

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        height: 14,
        decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.iconColor, required this.title, this.subtitle, this.action});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
          ],
        ),
      ),
    );
  }
}
