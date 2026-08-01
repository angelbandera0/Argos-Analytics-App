import 'package:flutter/material.dart';

/// Describes one column of an [AppDataTable]: how its header looks, whether
/// it participates in sorting, and how each cell renders for a row of
/// type [T].
class AppDataColumn<T> {
  const AppDataColumn({
    required this.id,
    required this.label,
    required this.cellBuilder,
    this.width,
    this.flex = 1,
    this.minWidth,
    this.sortable = false,
    this.alignment = Alignment.centerLeft,
    this.headerBuilder,
  });

  /// Stable identifier used for sorting (matched against
  /// [AppDataSort.columnId]) and for the request sent to the fetcher.
  final String id;

  /// Header text. Ignored if [headerBuilder] is provided.
  final String label;

  /// Optional custom header (icon + label, tooltip, etc). Falls back to a
  /// plain [Text] built from [label] when omitted.
  final WidgetBuilder? headerBuilder;

  /// Builds the cell content for a given row.
  final Widget Function(BuildContext context, T row) cellBuilder;

  /// Fixed column width. When null, the column is "flexible": it gets at
  /// least [minWidth] (or `flex * 120` if [minWidth] is also null) and
  /// grows to share any extra horizontal space, proportional to [flex].
  final double? width;

  /// Flex weight used to (a) size a flexible column's default minimum
  /// width when [minWidth] is omitted, and (b) distribute extra space
  /// among flexible columns once every column already has its minimum.
  final int flex;

  /// Explicit minimum width for a flexible column (ignored if [width] is
  /// set). Use this to guarantee enough room for badges/pills/long text
  /// regardless of screen size — this is what keeps the table from
  /// overflowing on narrow / portrait layouts: columns never shrink below
  /// this, the table scrolls horizontally instead.
  final double? minWidth;

  /// Whether tapping the header cycles through ascending/descending sort.
  final bool sortable;

  /// Content alignment for both header and cells.
  final Alignment alignment;
}
