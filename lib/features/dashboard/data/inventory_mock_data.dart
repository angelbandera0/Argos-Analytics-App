import '../../../core/widgets/data_table/app_data_table.dart';
import 'products_mock_data.dart';
import 'stores_mock_data.dart';

/// Id used for the single central warehouse in the stock ledger — every
/// store's own warehouse is keyed by its `Store.id` instead.
const String kCentralWarehouseId = 'central';

/// A location that can hold stock: the central warehouse, or a store's
/// own warehouse (every store has exactly one — see `StoresScreen`).
class InventoryLocation {
  const InventoryLocation({required this.id, required this.label, required this.isCentral});
  final String id;
  final String label;
  final bool isCentral;
}

List<InventoryLocation> get inventoryLocations {
  _ensureSeeded();
  return [
    const InventoryLocation(id: kCentralWarehouseId, label: 'Almacén Central', isCentral: true),
    for (final s in allStoresUnpaged) InventoryLocation(id: s.id, label: s.name, isCentral: false),
  ];
}

// ---------------------------------------------------------------------
// Stock ledger — the single source of truth for "how much of product X
// is at location Y". Every screen (Existencias, Traslados, Órdenes de
// Compra, Ventas) reads/writes through the functions below instead of
// touching this map directly, so the accounting stays consistent no
// matter which flow moved the stock.
// ---------------------------------------------------------------------
final Map<String, Map<String, int>> _stock = {
  kCentralWarehouseId: {for (final p in allProducts) p.id: 40 + (p.id.hashCode % 120).abs()},
};

int stockAt(String locationId, String productId) {
  _ensureSeeded();
  return _stock[locationId]?[productId] ?? 0;
}

void _addStock(String locationId, String productId, int qty) {
  final location = _stock.putIfAbsent(locationId, () => {});
  location[productId] = (location[productId] ?? 0) + qty;
}

bool _removeStock(String locationId, String productId, int qty) {
  final current = stockAt(locationId, productId);
  if (current < qty) return false;
  _stock[locationId]![productId] = current - qty;
  return true;
}

// ---------------------------------------------------------------------
// Product <-> Store assignment — catalog-level: which products a store
// is allowed to carry at all, independent of how much stock it has.
// ---------------------------------------------------------------------
final Map<String, Set<String>> _assignments = {}; // storeId -> productIds

Set<String> assignedProductIds(String storeId) {
  _ensureSeeded();
  return Set.unmodifiable(_assignments[storeId] ?? const {});
}

bool isAssigned(String storeId, String productId) {
  _ensureSeeded();
  return _assignments[storeId]?.contains(productId) ?? false;
}

void setStoreAssignments(String storeId, Set<String> productIds) {
  _ensureSeeded();
  _assignments[storeId] = Set.of(productIds);
}

// ---------------------------------------------------------------------
// Purchase Orders — bring stock INTO the central warehouse and update
// each product's cost to the price actually paid.
// ---------------------------------------------------------------------
class PurchaseOrderLine {
  const PurchaseOrderLine({required this.productId, required this.quantity, required this.unitCost});
  final String productId;
  final int quantity;
  final double unitCost;

  double get total => quantity * unitCost;
}

class PurchaseOrder {
  const PurchaseOrder({required this.id, required this.code, required this.supplier, required this.date, required this.lines});
  final String id;
  final String code;
  final String supplier;
  final DateTime date;
  final List<PurchaseOrderLine> lines;

  double get total => lines.fold(0, (sum, l) => sum + l.total);
}

final List<PurchaseOrder> _purchaseOrders = [];

/// Adds every line's quantity to the central warehouse and updates the
/// product's cost to that line's unit cost (last-cost approach).
void receivePurchaseOrder(PurchaseOrder order) {
  _ensureSeeded();
  _purchaseOrders.insert(0, order);
  for (final line in order.lines) {
    _addStock(kCentralWarehouseId, line.productId, line.quantity);
    updateProductCost(line.productId, line.unitCost);
  }
}

Future<AppDataResult<PurchaseOrder>> fetchPurchaseOrders(AppDataRequest request) async {
  _ensureSeeded();
  await Future.delayed(const Duration(milliseconds: 500));
  var items = List<PurchaseOrder>.from(_purchaseOrders);

  if (request.search != null && request.search!.trim().isNotEmpty) {
    final q = request.search!.trim().toLowerCase();
    items = items.where((o) => o.supplier.toLowerCase().contains(q) || o.code.toLowerCase().contains(q)).toList();
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  final total = items.length;
  final start = (request.page - 1) * request.pageSize;
  final end = (start + request.pageSize).clamp(0, total);
  final pageItems = start >= total ? <PurchaseOrder>[] : items.sublist(start, end);
  return AppDataResult(items: pageItems, totalCount: total);
}

String nextPurchaseOrderId() => 'po_${DateTime.now().microsecondsSinceEpoch}';
String nextPurchaseOrderCode() => 'OC-${1000 + _purchaseOrders.length}';

// ---------------------------------------------------------------------
// Transfers — move stock from the central warehouse into a store's own
// warehouse. Fails per-line if the central warehouse doesn't have
// enough of that product.
// ---------------------------------------------------------------------
class TransferLine {
  const TransferLine({required this.productId, required this.quantity});
  final String productId;
  final int quantity;
}

class InventoryTransfer {
  const InventoryTransfer({required this.id, required this.code, required this.storeId, required this.date, required this.lines});
  final String id;
  final String code;
  final String storeId;
  final DateTime date;
  final List<TransferLine> lines;
}

final List<InventoryTransfer> _transfers = [];

/// Returns the list of product ids that didn't have enough stock in the
/// central warehouse — empty means the transfer fully succeeded. On
/// partial failure, nothing is moved (all-or-nothing) so the ledger
/// never ends up half-applied.
List<String> createTransfer(InventoryTransfer transfer) {
  _ensureSeeded();
  final shortfalls = <String>[
    for (final line in transfer.lines)
      if (stockAt(kCentralWarehouseId, line.productId) < line.quantity) line.productId,
  ];
  if (shortfalls.isNotEmpty) return shortfalls;

  for (final line in transfer.lines) {
    _removeStock(kCentralWarehouseId, line.productId, line.quantity);
    _addStock(transfer.storeId, line.productId, line.quantity);
  }
  _transfers.insert(0, transfer);
  return const [];
}

Future<AppDataResult<InventoryTransfer>> fetchTransfers(AppDataRequest request) async {
  _ensureSeeded();
  await Future.delayed(const Duration(milliseconds: 500));
  var items = List<InventoryTransfer>.from(_transfers);

  final storeFilter = request.filters['store'];
  if (storeFilter != null && storeFilter.isNotEmpty) {
    items = items.where((t) => storeFilter.contains(t.storeId)).toList();
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  final total = items.length;
  final start = (request.page - 1) * request.pageSize;
  final end = (start + request.pageSize).clamp(0, total);
  final pageItems = start >= total ? <InventoryTransfer>[] : items.sublist(start, end);
  return AppDataResult(items: pageItems, totalCount: total);
}

String nextTransferId() => 'tr_${DateTime.now().microsecondsSinceEpoch}';
String nextTransferCode() => 'TR-${1000 + _transfers.length}';

// ---------------------------------------------------------------------
// Sales — registered at a store, deducted from that store's own
// warehouse. Same all-or-nothing shortfall check as transfers.
// ---------------------------------------------------------------------
class SaleLine {
  const SaleLine({required this.productId, required this.quantity, required this.unitPrice});
  final String productId;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class Sale {
  const Sale({required this.id, required this.code, required this.storeId, required this.date, required this.lines});
  final String id;
  final String code;
  final String storeId;
  final DateTime date;
  final List<SaleLine> lines;

  double get total => lines.fold(0, (sum, l) => sum + l.total);
}

final List<Sale> _sales = [];

List<String> registerSale(Sale sale) {
  _ensureSeeded();
  final shortfalls = <String>[
    for (final line in sale.lines)
      if (stockAt(sale.storeId, line.productId) < line.quantity) line.productId,
  ];
  if (shortfalls.isNotEmpty) return shortfalls;

  for (final line in sale.lines) {
    _removeStock(sale.storeId, line.productId, line.quantity);
  }
  _sales.insert(0, sale);
  return const [];
}

Future<AppDataResult<Sale>> fetchSales(AppDataRequest request) async {
  _ensureSeeded();
  await Future.delayed(const Duration(milliseconds: 500));
  var items = List<Sale>.from(_sales);

  final storeFilter = request.filters['store'];
  if (storeFilter != null && storeFilter.isNotEmpty) {
    items = items.where((s) => storeFilter.contains(s.storeId)).toList();
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  final total = items.length;
  final start = (request.page - 1) * request.pageSize;
  final end = (start + request.pageSize).clamp(0, total);
  final pageItems = start >= total ? <Sale>[] : items.sublist(start, end);
  return AppDataResult(items: pageItems, totalCount: total);
}

({int count, double revenue}) salesStats() {
  _ensureSeeded();
  return (
    count: _sales.length,
    revenue: _sales.fold(0.0, (sum, s) => sum + s.total),
  );
}

String nextSaleId() => 'sale_${DateTime.now().microsecondsSinceEpoch}';
String nextSaleCode() => 'V-${10000 + _sales.length}';

// ---------------------------------------------------------------------
// Demo seed data — assigns a rotating slice of the catalog to each
// store, stocks each store's warehouse for those products, and records
// a couple of sample historical movements so Traslados/Órdenes/Ventas
// don't look empty on first run.
//
// NOTE: a top-level `final` in Dart is initialized lazily on first
// *read*, so seeding can't just live in a top-level initializer nobody
// reads — `_ensureSeeded()` is called at the start of every public
// function in this file instead, guarded by `_seededFlag` so it only
// ever runs once no matter which screen is opened first.
// ---------------------------------------------------------------------
bool _seededFlag = false;

void _ensureSeeded() {
  if (_seededFlag) return;
  _seededFlag = true; // set before seeding so the calls it makes below don't recurse

  final products = allProducts;
  final stores = allStoresUnpaged;
  if (products.isEmpty || stores.isEmpty) return;

  const perStore = 18;
  for (var i = 0; i < stores.length; i++) {
    final store = stores[i];
    final start = (i * 7) % products.length;
    final assigned = <String>{};
    for (var j = 0; j < perStore; j++) {
      final product = products[(start + j) % products.length];
      assigned.add(product.id);
      _addStock(store.id, product.id, 8 + ((i + j) * 5) % 45);
    }
    _assignments[store.id] = assigned;
  }

  // A handful of historical records so the lists aren't empty.
  final firstStore = stores.first;
  final sampleProducts = products.take(3).toList();

  receivePurchaseOrder(PurchaseOrder(
    id: nextPurchaseOrderId(),
    code: nextPurchaseOrderCode(),
    supplier: 'Distribuidora del Valle',
    date: DateTime.now().subtract(const Duration(days: 5)),
    lines: [for (final p in sampleProducts) PurchaseOrderLine(productId: p.id, quantity: 60, unitCost: p.cost)],
  ));

  createTransfer(InventoryTransfer(
    id: nextTransferId(),
    code: nextTransferCode(),
    storeId: firstStore.id,
    date: DateTime.now().subtract(const Duration(days: 3)),
    lines: [for (final p in sampleProducts) TransferLine(productId: p.id, quantity: 10)],
  ));

  registerSale(Sale(
    id: nextSaleId(),
    code: nextSaleCode(),
    storeId: firstStore.id,
    date: DateTime.now().subtract(const Duration(days: 1)),
    lines: [for (final p in sampleProducts.take(2)) SaleLine(productId: p.id, quantity: 2, unitPrice: p.price)],
  ));
}
