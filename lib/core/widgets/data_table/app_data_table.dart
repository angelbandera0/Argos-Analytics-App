import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import 'app_data_table_controller.dart';
import 'column_width_resolver.dart';
import 'models/app_data_column.dart';
import 'models/app_data_filter.dart';
import 'widgets/data_table_body.dart';
import 'widgets/data_table_header_row.dart';
import 'widgets/data_table_pagination.dart';
import 'widgets/data_table_toolbar.dart';

export 'app_data_table_controller.dart';
export 'models/app_data_column.dart';
export 'models/app_data_filter.dart';
export 'models/app_data_request.dart';

/// A professional, fully configurable, fully responsive data table:
/// - columns, widths and cell rendering are declared by the caller
/// - sorting toggles per-column via the header
/// - filters are declarative (dropdown + "clear filters")
/// - pagination is numeric with ellipsis, driven by the fetcher's
///   reported `totalCount`
/// - data loads asynchronously through a single `fetcher` callback and
///   shows a shimmer skeleton while loading
/// - row selection is optional and independently configurable from
///   whether the checkbox column is shown
///
/// ## Responsiveness
/// Every flexible column has a guaranteed minimum width (see
/// [AppDataColumn.minWidth]/[AppDataColumn.flex]), so cells never get
/// squeezed below what their content needs — on narrow viewports
/// (tablet portrait, mobile) the table scrolls horizontally instead of
/// overflowing. Vertically, when [height] is left null the table expects
/// to be given bounded height by its parent (e.g. wrapped in `Expanded`)
/// and fills it; pass [height] explicitly to use a fixed height instead
/// (e.g. when placing the table inside a scrollable page).
///
/// See `lib/core/widgets/data_table/README.md` for full usage docs.
class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.controller,
    required this.columns,
    this.filters = const [],
    this.showSelectionColumn = false,
    this.searchable = true,
    this.searchHint = 'Type to search',
    this.rowActionsBuilder,
    this.actionsWidth = 120,
    this.onRowTap,
    this.emptyMessage = 'No results found',
    this.skeletonRowCount = 8,
    this.height,
  });

  /// Owns state (page, sort, filters, selection) and talks to the data
  /// source. See [AppDataTableController].
  final AppDataTableController<T> controller;

  /// Column definitions (label, width/flex/minWidth, sortable, cell builder).
  final List<AppDataColumn<T>> columns;

  /// Declarative filters rendered as dropdowns in the toolbar. Leave empty
  /// to hide the filters row entirely.
  final List<AppDataFilter> filters;

  /// Shows the leading checkbox column. Independent from
  /// `controller.selectionMode`: you can enable selection logic while
  /// keeping the checkbox hidden (e.g. select via row tap instead).
  final bool showSelectionColumn;

  /// Shows/hides the search box.
  final bool searchable;
  final String searchHint;

  /// Builds the trailing action icons for a row (edit/approve/delete...).
  /// Leave null to hide the actions column.
  final Widget Function(BuildContext context, T row)? rowActionsBuilder;

  /// Reserved width for [rowActionsBuilder]'s content.
  final double actionsWidth;

  final void Function(T row)? onRowTap;
  final String emptyMessage;

  /// How many shimmer rows to show during the initial load.
  final int skeletonRowCount;

  /// Optional fixed height for the whole table (toolbar + rows +
  /// pagination). When null (default), the table expects bounded height
  /// from its parent — wrap it in `Expanded`/`SizedBox` — and the rows
  /// area fills whatever vertical space remains, which is what keeps the
  /// table from overflowing when the surrounding chrome (tabs, header)
  /// takes up more room, e.g. in tablet portrait.
  final double? height;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = (widget.searchable || widget.filters.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: DataTableToolbar<T>(
              controller: widget.controller,
              filters: widget.filters,
              searchable: widget.searchable,
              searchHint: widget.searchHint,
            ),
          )
        : const SizedBox.shrink();

    final pagination = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DataTablePagination<T>(controller: widget.controller),
    );

    final table = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widths = resolveColumnWidths(
            columns: widget.columns,
            viewportWidth: constraints.maxWidth - (AppSpacing.md * 2),
            showSelectionColumn: widget.showSelectionColumn,
            actionsWidth: widget.rowActionsBuilder != null ? widget.actionsWidth : 0,
          );

          final scrollableContent = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: widths.totalWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DataTableHeaderRow<T>(
                    columns: widget.columns,
                    controller: widget.controller,
                    showSelectionColumn: widget.showSelectionColumn,
                    widths: widths,
                  ),
                  Expanded(
                    child: DataTableBody<T>(
                      controller: widget.controller,
                      columns: widget.columns,
                      showSelectionColumn: widget.showSelectionColumn,
                      rowActionsBuilder: widget.rowActionsBuilder,
                      widths: widths,
                      onRowTap: widget.onRowTap,
                      emptyMessage: widget.emptyMessage,
                      skeletonRowCount: widget.skeletonRowCount,
                    ),
                  ),
                ],
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: scrollableContent,
          );
        },
      ),
    );

    if (widget.height != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [toolbar, SizedBox(height: widget.height, child: table), pagination],
      );
    }

    // No fixed height: assume the parent gives bounded height (e.g. via
    // `Expanded`) and let the table fill it, so it never overflows
    // vertically regardless of how much chrome sits above/below it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [toolbar, Expanded(child: table), pagination],
    );
  }
}
