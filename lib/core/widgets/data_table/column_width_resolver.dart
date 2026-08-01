import 'models/app_data_column.dart';

/// Resolved pixel widths for every column plus the selection/actions
/// slots, computed for a given viewport width.
///
/// Strategy: every flexible column gets a guaranteed minimum width
/// (`minWidth` or `flex * kFlexBaseWidth`) so nothing is ever squeezed
/// below what it needs to render without overflowing (badges, pills,
/// currency values...). If all minimums fit inside the viewport, leftover
/// space is distributed among flexible columns proportional to `flex` so
/// the table still looks natural on wide screens. If they don't fit, the
/// resolved total exceeds the viewport and [AppDataTable] wraps the
/// content in a horizontal scroll view instead of shrinking anything.
class ResolvedColumnWidths {
  const ResolvedColumnWidths({
    required this.columnWidths,
    required this.selectionWidth,
    required this.actionsWidth,
    required this.totalWidth,
  });

  final List<double> columnWidths;
  final double selectionWidth;
  final double actionsWidth;
  final double totalWidth;
}

const double kFlexBaseWidth = 120;

ResolvedColumnWidths resolveColumnWidths({
  required List<AppDataColumn> columns,
  required double viewportWidth,
  required bool showSelectionColumn,
  required double actionsWidth,
  double selectionColumnWidth = 48,
}) {
  final selection = showSelectionColumn ? selectionColumnWidth : 0.0;

  final baseWidths = <double>[
    for (final c in columns) c.width ?? c.minWidth ?? (c.flex * kFlexBaseWidth),
  ];

  final fixedTotal = baseWidths.fold<double>(0, (sum, w) => sum + w) + selection + actionsWidth;
  final remaining = viewportWidth - fixedTotal;

  if (remaining <= 0) {
    return ResolvedColumnWidths(
      columnWidths: baseWidths,
      selectionWidth: selection,
      actionsWidth: actionsWidth,
      totalWidth: fixedTotal,
    );
  }

  // Distribute leftover space among flexible (non fixed-width) columns.
  var flexSum = 0;
  for (final c in columns) {
    if (c.width == null) flexSum += c.flex;
  }

  final widths = List<double>.from(baseWidths);
  if (flexSum > 0) {
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].width == null) {
        widths[i] += remaining * (columns[i].flex / flexSum);
      }
    }
  }

  final total = widths.fold<double>(0, (sum, w) => sum + w) + selection + actionsWidth;
  return ResolvedColumnWidths(
    columnWidths: widths,
    selectionWidth: selection,
    actionsWidth: actionsWidth,
    totalWidth: total < viewportWidth ? viewportWidth : total,
  );
}
