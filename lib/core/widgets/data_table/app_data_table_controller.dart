import 'dart:async';
import 'package:flutter/foundation.dart';

import 'models/app_data_request.dart';

/// Owns every piece of mutable state an [AppDataTable] needs: current page,
/// page size, sort, filter selections, search term and row selection.
///
/// Create one per table instance (it's cheap) and pass it to [AppDataTable].
/// Keeping it separate from the widget means a screen can trigger reloads,
/// read the current selection, or clear filters from a button that lives
/// outside the table (e.g. a page-level "Add" button that needs to know
/// how many rows are selected).
class AppDataTableController<T> extends ChangeNotifier {
  AppDataTableController({
    required this.fetcher,
    required this.rowId,
    this.pageSize = 10,
    AppDataSort? initialSort,
    this.selectionMode = AppDataTableSelectionMode.none,
    this.searchDebounce = const Duration(milliseconds: 350),
  }) : _sort = initialSort;

  /// Loads one page of data. Any exception is captured and exposed via
  /// [error] instead of crashing the widget tree.
  final AppDataFetcher<T> fetcher;

  /// Extracts a stable unique id from a row, used to track selection.
  final String Function(T row) rowId;

  final AppDataTableSelectionMode selectionMode;
  final Duration searchDebounce;

  int _page = 1;
  int pageSize;
  AppDataSort? _sort;
  final Map<String, Set<String>> _filters = {};
  String _search = '';
  final Set<String> _selectedIds = {};

  List<T> _items = const [];
  int _totalCount = 0;
  bool _isLoading = false;
  Object? _error;
  Timer? _debounceTimer;
  int _requestToken = 0;

  // ---- Read-only state -----------------------------------------------
  List<T> get items => _items;
  int get totalCount => _totalCount;
  int get page => _page;
  int get pageCount => _totalCount == 0 ? 1 : (( _totalCount - 1) ~/ pageSize) + 1;
  AppDataSort? get sort => _sort;
  Map<String, Set<String>> get filters => Map.unmodifiable(_filters);
  String get search => _search;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get hasSelection => _selectedIds.isNotEmpty;
  bool get hasActiveFilters => _filters.values.any((v) => v.isNotEmpty) || _search.isNotEmpty;

  bool isSelected(T row) => _selectedIds.contains(rowId(row));

  bool get allOnPageSelected => _items.isNotEmpty && _items.every((r) => isSelected(r));

  // ---- Lifecycle --------------------------------------------------------

  /// Fetches the first page. Call once when the table is mounted.
  Future<void> load() => _fetch(resetPage: false);

  Future<void> refresh() => _fetch(resetPage: false);

  Future<void> _fetch({required bool resetPage}) async {
    if (resetPage) _page = 1;
    final token = ++_requestToken;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await fetcher(
        AppDataRequest(
          page: _page,
          pageSize: pageSize,
          sort: _sort,
          filters: _filters,
          search: _search.isEmpty ? null : _search,
        ),
      );
      if (token != _requestToken) return; // a newer request superseded this one
      _items = result.items;
      _totalCount = result.totalCount;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (token != _requestToken) return;
      _error = e;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Pagination ---------------------------------------------------

  void goToPage(int page) {
    if (page < 1 || page > pageCount || page == _page) return;
    _page = page;
    _fetch(resetPage: false);
  }

  void nextPage() => goToPage(_page + 1);
  void previousPage() => goToPage(_page - 1);

  void setPageSize(int size) {
    if (size == pageSize) return;
    pageSize = size;
    _fetch(resetPage: true);
  }

  // ---- Sorting --------------------------------------------------------

  /// Cycles a column through ascending -> descending -> unsorted.
  void toggleSort(String columnId) {
    if (_sort == null || _sort!.columnId != columnId) {
      _sort = AppDataSort(columnId, AppSortDirection.ascending);
    } else if (_sort!.direction == AppSortDirection.ascending) {
      _sort = _sort!.toggled();
    } else {
      _sort = null;
    }
    _fetch(resetPage: true);
  }

  // ---- Filters ----------------------------------------------------------

  void setFilter(String filterId, Set<String> values) {
    if (values.isEmpty) {
      _filters.remove(filterId);
    } else {
      _filters[filterId] = values;
    }
    _fetch(resetPage: true);
  }

  void clearFilters() {
    _filters.clear();
    _search = '';
    _fetch(resetPage: true);
  }

  /// Debounced so typing doesn't trigger a request per keystroke.
  void setSearch(String value) {
    _search = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(searchDebounce, () => _fetch(resetPage: true));
  }

  // ---- Selection ------------------------------------------------------

  void toggleRowSelection(T row) {
    if (selectionMode == AppDataTableSelectionMode.none) return;
    final id = rowId(row);
    if (selectionMode == AppDataTableSelectionMode.single) {
      _selectedIds
        ..clear()
        ..add(id);
    } else if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAllOnPage() {
    if (selectionMode != AppDataTableSelectionMode.multiple) return;
    if (allOnPageSelected) {
      for (final r in _items) {
        _selectedIds.remove(rowId(r));
      }
    } else {
      for (final r in _items) {
        _selectedIds.add(rowId(r));
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
