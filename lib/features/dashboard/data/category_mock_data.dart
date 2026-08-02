import '../../../core/widgets/data_table/app_data_table.dart';

/// Two broad handling groups: perishables usually need faster turnover
/// / different shelf logic than packaged goods. Not enforced anywhere
/// yet, but keeping it on the model now means it's ready for things like
/// expiration tracking later without a schema change.
enum CategoryKind { abarrotes, perecedero }

extension CategoryKindX on CategoryKind {
  String get label => switch (this) {
        CategoryKind.abarrotes => 'Abarrotes',
        CategoryKind.perecedero => 'Perecedero',
      };
}

class CategoryRow {
  const CategoryRow({required this.id, required this.name, required this.kind});
  final String id;
  final String name;
  final CategoryKind kind;
}

/// Seeded with exactly the taxonomy described: canned goods / cleaning /
/// other packaged goods (Abarrotes) vs. fruits / vegetables / greens
/// (Perecedero). Add more from the Categorías screen — every Producto
/// picks one of these via `categoryId`.
final List<CategoryRow> _allCategories = [
  const CategoryRow(id: 'c_enlatados', name: 'Alimentos Enlatados', kind: CategoryKind.abarrotes),
  const CategoryRow(id: 'c_aseo', name: 'Productos de Aseo', kind: CategoryKind.abarrotes),
  const CategoryRow(id: 'c_otros', name: 'Otros Abarrotes', kind: CategoryKind.abarrotes),
  const CategoryRow(id: 'c_frutas', name: 'Frutas', kind: CategoryKind.perecedero),
  const CategoryRow(id: 'c_verduras', name: 'Verduras', kind: CategoryKind.perecedero),
  const CategoryRow(id: 'c_hortalizas', name: 'Hortalizas', kind: CategoryKind.perecedero),
];

List<CategoryRow> get allCategories => List.unmodifiable(_allCategories);

CategoryRow? findCategoryById(String id) {
  for (final c in _allCategories) {
    if (c.id == id) return c;
  }
  return null;
}

Future<AppDataResult<CategoryRow>> fetchCategories(AppDataRequest request) async {
  await Future.delayed(const Duration(milliseconds: 400));

  var items = List<CategoryRow>.from(_allCategories);

  if (request.search != null && request.search!.trim().isNotEmpty) {
    final q = request.search!.trim().toLowerCase();
    items = items.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  final kindFilter = request.filters['kind'];
  if (kindFilter != null && kindFilter.isNotEmpty) {
    items = items.where((c) => kindFilter.contains(c.kind.name)).toList();
  }

  items.sort((a, b) => a.name.compareTo(b.name));
  if (request.sort?.direction == AppSortDirection.descending) items = items.reversed.toList();

  final total = items.length;
  final start = (request.page - 1) * request.pageSize;
  final end = (start + request.pageSize).clamp(0, total);
  final pageItems = start >= total ? <CategoryRow>[] : items.sublist(start, end);
  return AppDataResult(items: pageItems, totalCount: total);
}

void upsertCategory(CategoryRow category) {
  final index = _allCategories.indexWhere((c) => c.id == category.id);
  if (index >= 0) {
    _allCategories[index] = category;
  } else {
    _allCategories.insert(0, category);
  }
}

/// Deletes the category outright. Callers (see `categories_screen.dart`)
/// should check `productsInCategory(categoryId)` from
/// `products_mock_data.dart` first and block/warn instead of leaving
/// products with a dangling `categoryId` — kept out of this function to
/// avoid a circular import between the two data files.
void deleteCategory(String id) {
  _allCategories.removeWhere((c) => c.id == id);
}

String nextCategoryId() => 'c_new_${DateTime.now().microsecondsSinceEpoch}';
