import '../../../core/widgets/data_table/app_data_table.dart';

enum ProductStatus { active, pending, canceled, rejected, inactive }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.pending => 'Pending',
        ProductStatus.canceled => 'Canceled',
        ProductStatus.rejected => 'Rejected',
        ProductStatus.inactive => 'Inactive',
      };

  String get value => name;
}

class ProductRow {
  const ProductRow({
    required this.id,
    required this.code,
    required this.name,
    required this.sku,
    required this.status,
    required this.price,
    required this.cost,
    required this.stock,
    required this.sales,
  });

  final String id;
  final String code; // e.g. #32
  final String name;
  final String sku;
  final ProductStatus status;
  final double price;
  final double cost;
  final int stock;
  final int sales;
}

final List<String> _names = [
  'Wireless Mouse',
  'Mechanical Keyboard',
  'USB-C Hub',
  'Noise Cancelling Headphones',
  'Portable SSD 1TB',
  '4K Monitor 27"',
  'Webcam HD',
  'Laptop Stand',
  'Bluetooth Speaker',
  'Smart Watch',
  'Ergonomic Chair',
  'Desk Lamp',
  'Graphic Tablet',
  'Ring Light',
  'Power Bank 20000mAh',
  'Gaming Mousepad',
  'Phone Case',
  'Screen Protector',
  'Charging Cable',
  'Wireless Charger',
];

/// Generates a stable, deterministic in-memory catalog so the demo works
/// without a backend. Replace `_fetchFromMemory` with a real API call to
/// wire this screen to a live service — the rest of the screen doesn't
/// need to change since it only depends on [AppDataFetcher]'s contract.
final List<ProductRow> _allProducts = List.generate(140, (i) {
  final status = ProductStatus.values[i % ProductStatus.values.length];
  return ProductRow(
    id: 'p_$i',
    code: '#${20 + (i % 40)}',
    name: '${_names[i % _names.length]} ${(i ~/ _names.length) + 1}',
    sku: 'SKU-${(1000 + i)}',
    status: status,
    price: 20 + (i * 7 % 180).toDouble(),
    cost: 10 + (i * 5 % 120).toDouble(),
    stock: (i * 13) % 300,
    sales: (i * 3) % 500,
  );
});

/// Fetcher wired to [AppDataTableController]. Applies search, status
/// filter, sort and pagination in memory, with a simulated network delay
/// so the loading skeleton is visible — mirrors exactly what a real REST
/// call would do server-side.
Future<AppDataResult<ProductRow>> fetchProducts(AppDataRequest request) async {
  await Future.delayed(const Duration(milliseconds: 650));

  var items = List<ProductRow>.from(_allProducts);

  if (request.search != null && request.search!.trim().isNotEmpty) {
    final q = request.search!.trim().toLowerCase();
    items = items.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
  }

  final statusFilter = request.filters['status'];
  if (statusFilter != null && statusFilter.isNotEmpty) {
    items = items.where((p) => statusFilter.contains(p.status.value)).toList();
  }

  final sort = request.sort;
  if (sort != null) {
    int compare(ProductRow a, ProductRow b) {
      switch (sort.columnId) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'price':
          return a.price.compareTo(b.price);
        case 'cost':
          return a.cost.compareTo(b.cost);
        case 'stock':
          return a.stock.compareTo(b.stock);
        case 'sales':
          return a.sales.compareTo(b.sales);
        default:
          return 0;
      }
    }

    items.sort(compare);
    if (sort.direction == AppSortDirection.descending) {
      items = items.reversed.toList();
    }
  }

  final total = items.length;
  final start = (request.page - 1) * request.pageSize;
  final end = (start + request.pageSize).clamp(0, total);
  final pageItems = start >= total ? <ProductRow>[] : items.sublist(start, end);

  return AppDataResult(items: pageItems, totalCount: total);
}

/// Creates or updates a product in the in-memory catalog. Swap this (and
/// [deleteProduct]) for real API calls when wiring a backend — the dialogs
/// that call these only depend on this function's signature.
void upsertProduct(ProductRow product) {
  final index = _allProducts.indexWhere((p) => p.id == product.id);
  if (index >= 0) {
    _allProducts[index] = product;
  } else {
    _allProducts.insert(0, product);
  }
}

void deleteProduct(String id) {
  _allProducts.removeWhere((p) => p.id == id);
}

/// Generates a fresh id/code pair for a new product created from the UI.
({String id, String code}) nextProductIdentity() {
  final id = 'p_new_${DateTime.now().microsecondsSinceEpoch}';
  final code = '#${20 + (_allProducts.length % 40)}';
  return (id: id, code: code);
}
