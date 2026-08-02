# Argos Analytics

App Flutter (tablet-first) construida a partir del diseño de referencia
(Projects / Publications / Board), con navegación GoRouter + go_router_builder,
temas centralizados y una vista de login con validaciones y animación de carga.

## Cómo correrla

Este proyecto se generó solo con la carpeta `lib/` y `pubspec.yaml` (sin
`android/`, `ios/`, etc.). Para dejarlo 100% ejecutable en tu máquina:

```bash
cd argos_analytics

# 1. Genera las carpetas de plataforma (android, ios, etc.) sin tocar lib/
flutter create .

# 2. Instala dependencias
flutter pub get

# 3. Genera el router (go_router_builder). Ya incluí un app_router.g.dart
#    escrito a mano con el mismo formato que genera el paquete, así que
#    esto es solo necesario si agregas o cambias rutas.
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Corre la app (ideal en un emulador/dispositivo tipo tablet)
flutter run
```

## Estructura

```
lib/
  core/
    theme/          -> Colores, tipografía (Plus Jakarta Sans vía google_fonts),
                        espaciados/radios y breakpoints. TODO estilo global vive aquí.
    router/
      app_router.dart   -> Rutas tipadas (@TypedGoRoute / @TypedShellRoute)
      app_router.g.dart -> Código generado por go_router_builder
    widgets/
      coming_soon_view.dart -> Placeholder reutilizable ("Coming soon" + nombre de ruta)
  features/
    auth/
      domain/auth_validators.dart      -> Validaciones de email/contraseña
      presentation/login_screen.dart   -> Vista de login
      presentation/widgets/            -> Campo de texto reutilizable
    dashboard/
      data/
        board_mock_data.dart              -> Datos mock del tablero Kanban
        products_mock_data.dart           -> Modelo + fetcher async (in-memory) de Productos
      presentation/
        dashboard_shell.dart           -> Layout persistente (sidebar) reutilizado
                                           por TODAS las rutas /dashboard/*
        widgets/                       -> Sidebar, kanban column, task card, tag chip, status pill
        screens/
          projects_board_screen.dart      -> Publications > Board (Kanban)
          products_screen.dart            -> Nomencladores > Productos (AppDataTable)
  core/widgets/data_table/            -> Componente AppDataTable reutilizable
                                          (ver su propio README.md con la guía de uso)
```

## Rutas

- `/login` — Login.
- `/dashboard/board` — Publications > Board (Kanban).
- `/dashboard/productos` — Nomencladores > Productos (tabla de datos completa).
- `/dashboard/:section` — Catch-all: cualquier otro ítem del sidebar o del
  rail de íconos (home, chat, campaigns, topics, planning, design-internal,
  development, favorites, insights, library, history, notifications, settings,
  categorías/marcas de Nomencladores, y las otras pestañas de Publications:
  list/workflow/calendar) renderiza `ComingSoonView` mostrando el nombre y
  el path de la ruta.

El sidebar ahora es contextual: cada ícono del rail izquierdo es dueño de
su propio panel de opciones (título + lista). Solo el ícono activo
muestra su panel — "Nomencladores" (antes "Library") solo se ve cuando su
ícono está seleccionado, e igual para el resto.

## Roles y Permisos (RBAC)

Jerarquía de gestión: **SuperAdmin → Admin → Propietario → Trabajador**.
Cada rol (salvo Trabajador) gestiona las cuentas del rol inmediatamente
inferior: crea/edita/elimina esos usuarios y define, por cada
módulo/opción del menú, si pueden **Leer, Crear, Editar o Eliminar**.
SuperAdmin tiene acceso total e ilimitado, sin necesidad de permisos
explícitos.

- `lib/core/auth/app_role.dart` — enum `AppRole` + `managedRole` (a quién
  gestiona cada rol).
- `lib/core/auth/permission.dart` — `PermissionAction` (read/write/edit/
  delete) y `ModulePermission` (el "grant": módulo + opción + acciones).
- `lib/core/auth/module_registry.dart` — **fuente única de verdad**:
  catálogo de módulos y sus opciones (id, label, ícono, ruta), usado
  tanto por el sidebar como por la matriz de permisos. Agregar una
  opción nueva a un módulo existente es un solo cambio aquí.
- `lib/core/auth/app_user.dart` / `mock_users_repository.dart` — modelo
  de usuario y directorio en memoria, con las 4 cuentas demo (una por
  rol) más un par de usuarios adicionales por nivel para que las tablas
  tengan filas.
- `lib/core/auth/auth_session.dart` — `AuthSession` (singleton,
  `ChangeNotifier`): usuario actual, `login`/`logout`,
  `can(modulo, opcion, accion)` / `canModule(modulo)`. Conectado a
  `GoRouter` como `refreshListenable` + `redirect` (si no hay sesión,
  redirige a `/login`; si ya la hay, `/login` redirige al dashboard).

**Sidebar dinámico y filtrado por permisos**: `dashboard_sidebar.dart` ya
no tiene listas hardcodeadas — renderiza directamente `kAppModules`/
`kBottomRailModules`, y en cada build filtra qué módulos/opciones
mostrar según `AuthSession.instance.currentUser`. Un Trabajador, por
ejemplo, ve un menú mucho más corto que un Admin.

**Permisos a nivel de acción**: `products_screen.dart` muestra el
ejemplo — el botón "Add New Product" solo aparece con permiso `write`
sobre `nomencladores/productos`, "Editar" requiere `edit`, "Eliminar"
requiere `delete`.

**Cuentas demo** (botones de acceso rápido en el login, que solo
rellenan el formulario — hay que presionar "Iniciar sesión" igual):

| Rol         | Correo                  | Contraseña   |
|-------------|--------------------------|--------------|
| Super Admin | superadmin@argos.com     | Super123!    |
| Admin       | admin@argos.com          | Admin123!    |
| Propietario | propietario@argos.com    | Dueno123!    |
| Trabajador  | trabajador@argos.com     | Trabajo123!  |

## Nomencladores > Gestión de Usuarios, Roles y Tiendas

- `/dashboard/usuarios` (`usuarios_screen.dart`) — CRUD (vía
  `AppDataTable`, con filtro por Estado) de los usuarios que el rol
  actual gestiona (siempre el nivel inmediatamente inferior). Cada fila
  tiene acciones Ver Permisos / Editar / Eliminar.
- `/dashboard/roles` (`roles_screen.dart`) — selector de usuario
  (también `AppDataTable`, en modo de selección única) + matriz de
  permisos (`permission_matrix.dart`): checkboxes de Leer/Crear/Editar/
  Eliminar por cada módulo y opción, con botón "Guardar permisos".
  Responsivo: lado a lado en pantallas anchas, apilado en mobile/tablet
  vertical.
- `/dashboard/tiendas` (`stores_screen.dart`) — **Gestión de Tiendas**:
  header con 4 tarjetas de estadísticas (tiendas totales, activas,
  empleados, ventas/mes), búsqueda + filtros por Estado/Ciudad, y una
  **grilla responsiva de tarjetas** (`StoreCard`) en vez de una tabla —
  cada tarjeta muestra estado, dirección, encargado, teléfono, empleados
  y ventas, con acciones ver/editar/eliminar. Reutiliza el mismo motor
  de datos asíncronos que las tablas (`AppDataTableController`: carga,
  búsqueda, filtros, orden, paginación) pero renderiza el resultado como
  grilla en vez de filas — muestra que el motor de datos es independiente
  de cómo se presenta.
- Las tres pantallas están ocultas del sidebar para roles sin
  gestionados (p. ej. Trabajador, que no administra a nadie), y cada una
  respeta los permisos CRUD del usuario (botones de crear/editar/eliminar
  solo aparecen si el permiso correspondiente está concedido).

## Sidebar responsivo (mobile / tablet vertical y horizontal)

`dashboard_shell.dart` decide el modo con un único `LayoutBuilder`:

- **Ancho ≥ 1000px** (tablet horizontal / desktop): el sidebar se
  muestra inline por defecto, empujando el contenido — igual que antes.
  Puede colapsarse con el botón de menú (☰) en la barra superior para
  ganar espacio.
- **Ancho < 1000px** (mobile, tablet vertical): el sidebar arranca
  **oculto** para no robar espacio a la pantalla, y se abre como un
  drawer (scrim + panel deslizante) con el mismo botón de menú. Se
  cierra tocando el scrim o navegando a cualquier opción.

## Cadena de Suministro: Categorías, Asignación, Inventario y Ventas

Modelo de negocio implementado (ver también la explicación de arquitectura
que acompañó esta entrega):

```
Orden de Compra → Almacén Central (sube costo del producto)
       → Traslado → Almacén de la Tienda (uno por tienda)
              → Venta (descuenta del almacén de esa tienda)
```

El stock nunca se edita a mano — siempre es resultado de estos tres
movimientos, así los números nunca quedan inconsistentes. Todo vive en
`lib/features/dashboard/data/inventory_mock_data.dart` (el "ledger"):

- `stockAt(locationId, productId)` — existencia en una ubicación
  (`kCentralWarehouseId` o el `id` de una tienda).
- `assignedProductIds(storeId)` / `setStoreAssignments(...)` — catálogo
  de qué productos puede vender cada tienda (independiente de cantidad).
- `receivePurchaseOrder(...)` — entra mercancía al Almacén Central y
  **actualiza el costo del producto** (último costo de compra).
- `createTransfer(...)` — mueve stock del Almacén Central al almacén de
  una tienda; todo-o-nada si no alcanza el stock central.
- `registerSale(...)` — descuenta del almacén de la tienda; todo-o-nada
  si no alcanza esa existencia.

### Nomencladores
- **Categorías** (`/dashboard/nomencladores-categorias`, ahora real) —
  cada categoría tiene un `tipo`: Abarrotes (Enlatados, Aseo, Otros) o
  Perecedero (Frutas, Verduras, Hortalizas). Cada Producto ahora tiene
  `categoryId` — ver columna "Categoría" en Productos.
- **Asignación de Productos a Tienda** (`/dashboard/asignacion-productos`)
  — elige una tienda, marca qué productos puede vender, guarda. Esto es
  lo que después limita los selectores de producto en Traslados y Ventas
  para esa tienda — no puedes trasladar/vender algo que la tienda nunca
  fue configurada para tener.

### Inventario (módulo nuevo)
- **Existencias** (`/dashboard/existencias`) — selector de ubicación
  (Almacén Central o cualquier tienda) + tabla de solo lectura con la
  cantidad de cada producto ahí.
- **Traslados** (`/dashboard/traslados`) — mueve stock del Almacén
  Central a una tienda. El selector de productos se limita a lo asignado
  a esa tienda.
- **Órdenes de Compra** (`/dashboard/ordenes-compra`) — registra entrada
  de mercancía al Almacén Central; cada línea trae su costo unitario, que
  se refleja automáticamente en el Producto.

### Ventas (módulo nuevo)
- **Registrar Venta** (`/dashboard/ventas-registrar`) — flujo tipo punto
  de venta: elige tienda, agrega productos (limitado a lo asignado *y*
  con existencia > 0 en esa tienda), ve el total en vivo, confirma.
- **Historial de Ventas** (`/dashboard/ventas-historial`) — tabla con
  filtro por tienda + tarjetas de ventas totales/ingresos.

### Editor de líneas reutilizable
`order_lines_editor.dart` — el widget de "producto + cantidad (+ costo o
precio unitario)" repetible, compartido por Órdenes de Compra, Traslados
y Ventas. Cada fila permite elegir producto, cantidad y (si aplica) el
valor unitario; "Agregar línea" / ✕ para quitar una línea.

### Permisos otorgados por defecto
- **Admin**: control total sobre Categorías, Asignación, Inventario y
  Ventas (compras centralizadas incluidas).
- **Propietario**: Asignación y Ventas completas para su tienda; recibe
  Traslados pero **no** puede crear Órdenes de Compra (la compra a
  proveedores queda centralizada en Admin/SuperAdmin) — así el ejemplo
  demuestra una decisión de negocio real, no solo un checkbox técnico.
- **Trabajador**: solo Registrar Venta + ver Historial + ver Existencias
  de solo lectura — el día a día de un empleado de tienda.

Como con todo lo demás, esto se ajusta libremente desde **Roles y
Permisos** por usuario.

### Ideas para seguir puliendo (no implementadas todavía)
- Fecha de caducidad / lote para productos Perecederos (el campo `kind`
  de Categoría ya deja la puerta abierta para esto).
  - Órdenes de Compra a nivel de un solo proveedor por orden — si un
  proveedor factura por tienda en vez de a un almacén central, habría
  que ajustar el flujo.
- Traslados entre dos tiendas (hoy solo Central → Tienda).
- Reportes de rentabilidad (precio − costo) por producto/tienda/periodo.

## AppDataTable

Componente de tabla reutilizable y configurable (columnas, sort, filtros,
selección múltiple opcional, paginación, carga asíncrona con skeleton,
responsiva con scroll horizontal cuando no cabe). Usado en casi toda
pantalla con listados: `products_screen.dart`, `usuarios_screen.dart`,
`roles_screen.dart`, `categories_screen.dart`, `stock_screen.dart`,
`transfers_screen.dart`, `purchase_orders_screen.dart`,
`sales_history_screen.dart` y como *picker* de selección única en
`roles_screen.dart`/`assignment_screen.dart`. Documentación completa en
`lib/core/widgets/data_table/README.md`.

## Diálogos (crear / editar / eliminar / ver detalle) y Toasts

- `lib/core/widgets/app_dialog.dart` — `showAppDialog(...)`: wrapper
  reutilizable con el estilo de la app (título, botón de cerrar, acciones
  alineadas a la derecha). El `contentBuilder`/`actionsBuilder` reciben el
  `BuildContext` **del propio diálogo**, para poder hacer
  `Navigator.of(dialogContext).pop()` correctamente.
- `lib/core/widgets/async_action_button.dart` — `AsyncActionButton`:
  botón que se transforma en spinner mientras su `onPressed` (una
  `Future`) está pendiente. Mismo patrón que el botón de login,
  generalizado para reusarse en cualquier diálogo.
- `lib/features/dashboard/presentation/widgets/product_dialogs.dart` —
  `showProductFormDialog` (crear/editar con validaciones),
  `showProductDeleteDialog` (confirmación) y `showProductDetailDialog`
  (solo lectura, con atajo a "Editar"). Cada uno simula la petición con
  `Future.delayed`, muta el catálogo en memoria
  (`upsertProduct`/`deleteProduct` en `products_mock_data.dart`),
  refresca la tabla (`controller.refresh()`) y muestra un toast — mismo
  patrón para conectar a un backend real: solo cambia lo que hay dentro
  de `Future.delayed(...)` por tu llamada a la API.
- `lib/core/services/toast_service.dart` — `ToastService`: servicio
  global de notificaciones (success / error / warning / info), **sin
  depender de un `BuildContext`** (se renderiza en el `Overlay` raíz vía
  `ToastService.navigatorKey`, ya conectado a `GoRouter` en
  `app_router.dart`). Esto es a propósito: una acción típica cierra un
  diálogo y *después* muestra el toast, cuando el `BuildContext` del
  diálogo ya no existe.
  ```dart
  ToastService.success('Producto creado correctamente');
  ToastService.error('No se pudo eliminar el producto');
  ToastService.warning('Hay cambios sin guardar');
  ToastService.info('Sincronizando datos...');
  ```

## Login

- Validaciones: correo con formato válido, contraseña mínimo 8 caracteres
  con letras y números (ver `auth_validators.dart`).
- Al presionar "Iniciar sesión": si el formulario es válido, el botón se
  transforma en un spinner (`AnimatedSwitcher`), simula una petición con
  `Future.delayed` y navega a `/dashboard/board`.

## Tablet-first, adaptable a mobile

El layout del shell y del tablero usan tamaños fijos (sidebar 340px, columnas
de 300px) pensados para tablet, pero:
- Los breakpoints (`AppBreakpoints`) ya están definidos en `core/theme/app_dimens.dart`.
- El layout del shell es un widget independiente (`DashboardShell`) que se
  puede envolver en un `LayoutBuilder`/`ResponsiveLayout` más adelante sin
  tocar las rutas ni las pantallas.
