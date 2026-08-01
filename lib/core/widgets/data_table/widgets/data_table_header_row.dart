import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_text_styles.dart';
import '../app_data_table_controller.dart';
import '../column_width_resolver.dart';
import '../models/app_data_column.dart';
import '../models/app_data_request.dart';

/// Renders the header using pre-resolved pixel widths ([widths]) instead
/// of `Expanded`/flex, so it always matches the body row widths exactly —
/// this is what keeps header and cells aligned once the table scrolls
/// horizontally.
class DataTableHeaderRow<T> extends StatelessWidget {
  const DataTableHeaderRow({
    super.key,
    required this.columns,
    required this.controller,
    required this.showSelectionColumn,
    required this.widths,
  });

  final List<AppDataColumn<T>> columns;
  final AppDataTableController<T> controller;
  final bool showSelectionColumn;
  final ResolvedColumnWidths widths;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (showSelectionColumn)
                SizedBox(
                  width: widths.selectionWidth,
                  child: controller.selectionMode == AppDataTableSelectionMode.multiple
                      ? Checkbox(
                          value: controller.allOnPageSelected,
                          onChanged: (_) => controller.toggleSelectAllOnPage(),
                        )
                      : null,
                ),
              for (var i = 0; i < columns.length; i++)
                SizedBox(
                  width: widths.columnWidths[i],
                  child: _HeaderCell(column: columns[i], controller: controller),
                ),
              SizedBox(width: widths.actionsWidth),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({required this.column, required this.controller});

  final AppDataColumn<T> column;
  final AppDataTableController<T> controller;

  @override
  Widget build(BuildContext context) {
    final activeSort = controller.sort;
    final isSorted = activeSort?.columnId == column.id;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: column.headerBuilder?.call(context) ??
              Text(
                column.label,
                style: AppTextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        if (column.sortable) ...[
          const SizedBox(width: 4),
          Icon(
            !isSorted
                ? Icons.unfold_more_rounded
                : activeSort!.direction == AppSortDirection.ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
            size: 14,
            color: isSorted ? AppColors.primary : AppColors.textMuted,
          ),
        ],
      ],
    );

    final cell = Align(alignment: column.alignment, child: content);

    return column.sortable
        ? InkWell(onTap: () => controller.toggleSort(column.id), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: cell))
        : Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: cell);
  }
}
