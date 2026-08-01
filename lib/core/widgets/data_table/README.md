# AppDataTable

Tabla de datos reutilizable y totalmente configurable, ubicada en
`lib/core/widgets/data_table/`. Pensada para cualquier listado de la app
(Productos, Afiliados, Usuarios, etc.) sin duplicar lógica de paginación,
orden, filtros o carga asíncrona.

## Piezas

```
core/widgets/data_table/
  app_data_table.dart            -> Widget principal
  app_data_table_controller.dart -> Estado: página, orden, filtros, selección, carga
  models/
    app_data_column.dart         -> Definición de columnas
    app_data_filter.dart         -> Definición de filtros (dropdown)
    app_data_request.dart        -> AppDataSort, AppDataRequest, AppDataResult, AppDataFetcher
  widgets/                       -> Internos: toolbar, header, filas, paginación
```

Todo se importa desde un único archivo:

```dart
import 'package:argos_analytics/core/widgets/data_table/app_data_table.dart';
```

## 1. Define tu modelo de fila

Cualquier clase sirve, no hay una interfaz obligatoria:

```dart
class ProductRow {
  const ProductRow({required this.id, required this.name, required this.status, required this.price});
  final String id;
  final String name;
  final String status;
  final double price;
}
```

## 2. Implementa el fetcher (carga asíncrona)

Es la única pieza que conecta la tabla con tu fuente de datos real
(API REST, lista local, GraphQL...). Recibe un `AppDataRequest` con
página, tamaño de página, orden, filtros activos y texto de búsqueda, y
debe devolver un `AppDataResult<T>` con los items de esa página y el
total de registros (para la paginación).

```dart
Future<AppDataResult<ProductRow>> fetchProducts(AppDataRequest request) async {
  final response = await api.get('/products', query: {
    'page': request.page,
    'pageSize': request.pageSize,
    'sortBy': request.sort?.columnId,
    'sortDir': request.sort?.direction.name,
    'search': request.search,
    'status': request.filters['status']?.join(','),
  });

  return AppDataResult(
    items: response.data.map(ProductRow.fromJson).toList(),
    totalCount: response.totalCount,
  );
}
```

Para datos locales, puedes filtrar/ordenar/paginar en memoria dentro del
mismo fetcher (ver `products_screen.dart` para un ejemplo completo con
`Future.delayed` simulando latencia de red).

## 3. Crea el controller

```dart
final controller = AppDataTableController<ProductRow>(
  fetcher: fetchProducts,
  rowId: (row) => row.id,           // usado para trackear selección
  pageSize: 14,
  selectionMode: AppDataTableSelectionMode.multiple, // none | single | multiple
  initialSort: const AppDataSort('name', AppSortDirection.ascending),
);
```

> El controller es un `ChangeNotifier`. Si vive dentro de un `State`,
> recuerda llamar `controller.dispose()` en `dispose()`.

## 4. Declara las columnas

```dart
final columns = <AppDataColumn<ProductRow>>[
  AppDataColumn(
    id: 'name',
    label: 'Producto',
    sortable: true,
    flex: 3,
    cellBuilder: (context, row) => Text(row.name),
  ),
  AppDataColumn(
    id: 'status',
    label: 'Estado',
    flex: 2,
    cellBuilder: (context, row) => StatusPill(status: row.status),
  ),
  AppDataColumn(
    id: 'price',
    label: 'Precio',
    sortable: true,
    width: 120, // columna de ancho fijo en vez de flex
    alignment: Alignment.centerRight,
    cellBuilder: (context, row) => Text('\$${row.price.toStringAsFixed(2)}'),
  ),
];
```

- `sortable: true` habilita el click en el header (alterna
  ascendente → descendente → sin orden). El `id` es lo que llega en
  `AppDataRequest.sort.columnId`, así que debe coincidir con lo que tu
  fetcher espera.
- Usa `width` para columnas de ancho fijo (ideal para acciones/badges) o
  `flex` para que se repartan el espacio restante.
- `cellBuilder` puede devolver cualquier widget: texto, chips, badges,
  íconos, etc.

## 5. Declara los filtros (opcional)

```dart
final filters = <AppDataFilter>[
  AppDataFilter(
    id: 'status',
    label: 'Estado',
    multiple: true,
    options: const [
      AppFilterOption('active', 'Activo'),
      AppFilterOption('pending', 'Pendiente'),
      AppFilterOption('canceled', 'Cancelado'),
    ],
  ),
];
```

Cada filtro se renderiza como un dropdown en la barra superior. El botón
"Limpiar filtros" aparece automáticamente en cuanto hay algún filtro o
texto de búsqueda activo, y llama a `controller.clearFilters()`.

## 6. Úsalo

```dart
AppDataTable<ProductRow>(
  controller: controller,
  columns: columns,
  filters: filters,
  searchable: true,
  searchHint: 'Buscar productos...',
  showSelectionColumn: true,     // muestra la columna de checkboxes
  rowActionsBuilder: (context, row) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => editProduct(row)),
      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => deleteProduct(row)),
    ],
  ),
  onRowTap: (row) => openProductDetail(row),
)
```

## Selección múltiple vs. columna de checkboxes

Son dos flags independientes a propósito:

- `controller.selectionMode` (`none` / `single` / `multiple`): habilita
  la **lógica** de selección (qué filas están seleccionadas, select-all).
- `showSelectionColumn` (en `AppDataTable`): controla si se **muestra**
  la columna de checkboxes.

Esto permite, por ejemplo, tener selección activa pero seleccionar solo
con `onRowTap`, sin mostrar checkboxes.

Para leer o reaccionar a la selección desde la pantalla (p. ej. un botón
"Eliminar seleccionados" fuera de la tabla):

```dart
controller.addListener(() {
  final ids = controller.selectedIds; // Set<String>
});
```

## Paginación

Controlada 100% por `AppDataTableController`:

```dart
controller.goToPage(3);
controller.nextPage();
controller.previousPage();
controller.setPageSize(20);
```

El pie de la tabla muestra "Showing X of Y results" y una paginación
numérica con elipsis (`1 2 3 … 8 9 10`), calculada automáticamente a
partir de `totalCount` (que reporta tu fetcher).

## Carga asíncrona y animación de carga

- Primer render / cambio de filtros / orden / página: mientras no haya
  datos en pantalla, se muestra un **skeleton** (shimmer) con la
  cantidad de filas configurada en `skeletonRowCount`.
- Si ya hay datos y se está recargando (p. ej. cambiaste de página), la
  tabla mantiene las filas anteriores visibles con una superposición
  semitransparente en vez de parpadear a un estado vacío.
- Si el fetcher lanza una excepción, se muestra un estado de error con
  botón "Reintentar" (`controller.refresh()`), sin romper el widget tree.

## Búsqueda

`searchable: true` agrega el campo de búsqueda. Está *debounced*
(350ms por defecto, configurable con `searchDebounce` en el
controller) para no disparar una petición por cada tecla.

## Responsividad (mobile / tablet, horizontal y vertical)

La tabla nunca reduce una columna por debajo de lo que su contenido
necesita — en vez de eso, se activa scroll horizontal:

- Cada columna flexible (`width == null`) tiene un ancho mínimo
  garantizado: `minWidth` si lo defines, o `flex * 120` si no. Si la suma
  de todos los mínimos no cabe en el viewport, la tabla completa (header +
  filas) se vuelve **horizontalmente scrolleable** en vez de comprimir el
  contenido (esto es lo que evita el `RenderFlex overflowed` en tablet
  vertical / mobile).
- Si sí caben, el espacio sobrante se reparte entre las columnas
  flexibles según su `flex`, para que la tabla luzca bien en pantallas
  anchas.
- Usa `minWidth` en columnas con badges/pills/números para asegurar que
  siempre quepan sin recortarse:
  ```dart
  AppDataColumn(
    id: 'status',
    label: 'Estado',
    minWidth: 140,
    cellBuilder: (context, row) => StatusPill(status: row.status),
  )
  ```

Verticalmente:

- Si no pasas `height`, la tabla asume que su padre le da una altura
  acotada (típicamente envolviéndola en `Expanded`) y las filas llenan
  ese espacio con `Expanded` internamente — así nunca desborda
  verticalmente aunque el header/tabs de la pantalla ocupen más espacio
  en tablet vertical.
- Si prefieres una altura fija (por ejemplo, tabla dentro de una página
  con scroll general), pasa `height: 480`.
- La paginación numérica también es scrolleable horizontalmente en
  pantallas muy angostas, así que nunca desborda aunque haya muchas
  páginas.

## Reutilización en otra pantalla

Solo repite los pasos 1-6 con tu propio modelo, fetcher, columnas y
filtros — el widget y el controller son genéricos (`<T>`) y no saben
nada del dominio (productos, afiliados, usuarios...). Ver
`lib/features/dashboard/presentation/screens/products_screen.dart` como
ejemplo de referencia completo.
