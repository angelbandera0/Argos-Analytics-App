import '../../../core/widgets/data_table/app_data_table.dart';

enum StoreStatus { active, inactive, maintenance }

extension StoreStatusX on StoreStatus {
  String get label => switch (this) {
        StoreStatus.active => 'Activa',
        StoreStatus.inactive => 'Inactiva',
        StoreStatus.maintenance => 'En mantenimiento',
      };

  String get value => name;
}

class StoreRow {
  const StoreRow({
    required this.id,
    required this.code,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.managerName,
    required this.status,
    required this.employees,
    required this.monthlySales,
    required this.openedAt,
  });

  final String id;
  final String code;
  final String name;
  final String city;
  final String address;
  final String phone;
  final String managerName;
  final StoreStatus status;
  final int employees;
  final double monthlySales;
  final DateTime openedAt;
}

const _storeNames = [
  'Centro',
  'Norte Plaza',
  'Sur Mall',
  'Boulevard',
  'Terminal',
  'Universidad',
  'Marina',
  'Altavista',
  'Las Flores',
  'El Bosque',
  'Miraflores',
  'San Isidro',
];

const _cities = ['Ciudad de México', 'Guadalajara', 'Monterrey', 'Puebla', 'Querétaro', 'Mérida'];

const _managers = [
  'Renata Ibarra',
  'Diego Salgado',
  'Fernanda Ríos',
  'Óscar Delgado',
  'Ximena Torres',
  'Hugo Beltrán',
  'Paola Cabrera',
  'Iván Montes',
];

/// Deterministic in-memory catalog of stores, mirroring the pattern used
/// for products — swap [_fetchFromMemory]-style filtering for a real API
/// call when wiring a backend.
final List<StoreRow> _allStores = List.generate(22, (i) {
  final roll = i % 10;
  final status = roll < 7 ? StoreStatus.active : (roll < 9 ? StoreStatus.inactive : StoreStatus.maintenance);
  return StoreRow(
    id: 's_$i',
    code: 'T-${100 + i}',
    name: _storeNames[i % _storeNames.length],
    city: _cities[i % _cities.length],
    address: 'Av. ${_storeNames[(i + 3) % _storeNames.length]} #${120 + i * 7}',
    phone: '+52 55 ${1000 + i * 37} ${2000 + i * 11}',
    managerName: _managers[i % _managers.length],
    status: status,
    employees: 3 + (i * 5) % 40,
    monthlySales: 8000 + (i * 1237) % 65000,
    openedAt: DateTime(2019 + (i % 6), 1 + (i % 12), 1 + (i % 27)),
  );
});

Future<AppDataResult<StoreRow>> fetchStores(AppDataRequest request) async {
  await Future.delayed(const Duration(milliseconds: 650));

  var items = List<StoreRow>.from(_allStores);

  if (request.search != null && request.search!.trim().isNotEmpty) {
    final q = request.search!.trim().toLowerCase();
    items = items.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.city.toLowerCase().contains(q) ||
        s.managerName.toLowerCase().contains(q) ||
        s.code.toLowerCase().contains(q)).toList();
  }

  final statusFilter = request.filters['status'];
  if (statusFilter != null && statusFilter.isNotEmpty) {
    items = items.where((s) => statusFilter.contains(s.status.value)).toList();
  }

  final cityFilter = request.filters['city'];
  if (cityFilter != null && cityFilter.isNotEmpty) {
    items = items.where((s) => cityFilter.contains(s.city)).toList();
  }

  final sort = request.sort;
  if (sort != null) {
    int compare(StoreRow a, StoreRow b) {
      switch (sort.columnId) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'employees':
          return a.employees.compareTo(b.employees);
        case 'sales':
          return a.monthlySales.compareTo(b.monthlySales);
        case 'opened':
          return a.openedAt.compareTo(b.openedAt);
        default:
          return 0;
      }
    }

    items.sort(compare);
    if (sort.direction == AppSortDirection.descending) items = items.reversed.toList();
  }

  final total = items.length;
  final start = (request.page - 1) * request.pageSize;
  final end = (start + request.pageSize).clamp(0, total);
  final pageItems = start >= total ? <StoreRow>[] : items.sublist(start, end);

  return AppDataResult(items: pageItems, totalCount: total);
}

/// Quick aggregate stats for the dashboard-style header of the stores
/// screen. Computed over the full catalog (not the current page/filters)
/// so the numbers stay stable while the person searches/paginates.
({int total, int active, int employees, double sales}) storeStats() {
  return (
    total: _allStores.length,
    active: _allStores.where((s) => s.status == StoreStatus.active).length,
    employees: _allStores.fold(0, (sum, s) => sum + s.employees),
    sales: _allStores.fold(0.0, (sum, s) => sum + s.monthlySales),
  );
}

List<String> get storeCities => _cities;

/// Every store, unfiltered/unpaginated — used to build store pickers in
/// the inventory/sales/assignment screens.
List<StoreRow> get allStoresUnpaged => List.unmodifiable(_allStores);

StoreRow? findStoreById(String id) {
  for (final s in _allStores) {
    if (s.id == id) return s;
  }
  return null;
}

void upsertStore(StoreRow store) {
  final index = _allStores.indexWhere((s) => s.id == store.id);
  if (index >= 0) {
    _allStores[index] = store;
  } else {
    _allStores.insert(0, store);
  }
}

void deleteStore(String id) {
  _allStores.removeWhere((s) => s.id == id);
}

({String id, String code}) nextStoreIdentity() {
  final id = 's_new_${DateTime.now().microsecondsSinceEpoch}';
  final code = 'T-${100 + _allStores.length}';
  return (id: id, code: code);
}
