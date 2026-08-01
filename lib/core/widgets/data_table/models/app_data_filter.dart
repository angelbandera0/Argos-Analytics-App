/// One selectable value inside an [AppDataFilter].
class AppFilterOption {
  const AppFilterOption(this.value, this.label);
  final String value;
  final String label;
}

/// Declarative definition of a filter shown in the table toolbar.
/// The table only knows how to *render* and *collect* filter values —
/// applying them to the actual dataset is the fetcher's responsibility,
/// which keeps [AppDataTable] usable with any backend (REST, local list,
/// GraphQL, etc).
class AppDataFilter {
  const AppDataFilter({
    required this.id,
    required this.label,
    required this.options,
    this.multiple = true,
  });

  /// Key used in [AppDataRequest.filters].
  final String id;

  /// Label shown on the filter's dropdown button.
  final String label;

  /// Available options for this filter.
  final List<AppFilterOption> options;

  /// Whether more than one option can be selected at once.
  final bool multiple;
}
