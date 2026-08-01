/// Direction a column is currently sorted in.
enum AppSortDirection { ascending, descending }

/// Active sort state for a table: which column, which direction.
class AppDataSort {
  const AppDataSort(this.columnId, this.direction);

  final String columnId;
  final AppSortDirection direction;

  AppDataSort toggled() => AppDataSort(
        columnId,
        direction == AppSortDirection.ascending ? AppSortDirection.descending : AppSortDirection.ascending,
      );

  @override
  bool operator ==(Object other) =>
      other is AppDataSort && other.columnId == columnId && other.direction == direction;

  @override
  int get hashCode => Object.hash(columnId, direction);
}

/// Whether/how rows can be selected.
enum AppDataTableSelectionMode { none, single, multiple }

/// Everything the table currently needs from the data source: page,
/// page size, sort, active filter values and the free-text search term.
/// Passed as a single object to [AppDataFetcher] so any backend (REST,
/// local list, GraphQL...) can translate it into its own query shape.
class AppDataRequest {
  const AppDataRequest({
    required this.page,
    required this.pageSize,
    this.sort,
    this.filters = const {},
    this.search,
  });

  /// 1-based page number.
  final int page;
  final int pageSize;
  final AppDataSort? sort;

  /// filterId -> set of selected option values.
  final Map<String, Set<String>> filters;

  final String? search;
}

/// Response expected back from [AppDataFetcher]: the rows for the
/// requested page plus the total row count (used for pagination).
class AppDataResult<T> {
  const AppDataResult({required this.items, required this.totalCount});
  final List<T> items;
  final int totalCount;
}

/// Signature every data source must implement to feed an [AppDataTable].
typedef AppDataFetcher<T> = Future<AppDataResult<T>> Function(AppDataRequest request);
