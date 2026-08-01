import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum ToastType { success, error, warning, info }

/// Global, context-free toast/notification service.
///
/// Why context-free: actions that trigger a toast (e.g. "delete product")
/// often close a dialog right before showing it — by the time the toast
/// would appear, the dialog's `BuildContext` is gone. `ToastService` shows
/// toasts through the app's root `Overlay` (attached via [navigatorKey],
/// which must be passed to `GoRouter`/`MaterialApp`), so it works from
/// anywhere: dialogs, async callbacks, deep widgets, without threading a
/// `BuildContext` through your business logic.
///
/// ## Setup (already done in `main.dart` / `app_router.dart`)
/// ```dart
/// final GoRouter appRouter = GoRouter(
///   navigatorKey: ToastService.navigatorKey,
///   ...
/// );
/// ```
///
/// ## Usage
/// ```dart
/// ToastService.success('Producto creado correctamente');
/// ToastService.error('No se pudo eliminar el producto');
/// ToastService.warning('Hay cambios sin guardar');
/// ToastService.info('Sincronizando datos...');
/// ```
abstract class ToastService {
  ToastService._();

  /// Attach this to `MaterialApp.router`'s router (`GoRouter(navigatorKey: ...)`)
  /// so the service can reach the app's Overlay from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final ValueNotifier<List<_ToastEntry>> _toasts = ValueNotifier(const []);
  static OverlayEntry? _overlayEntry;
  static int _idCounter = 0;

  static void success(String message, {String? title, Duration duration = const Duration(seconds: 3)}) =>
      _push(ToastType.success, message, title: title ?? 'Listo', duration: duration);

  static void error(String message, {String? title, Duration duration = const Duration(seconds: 4)}) =>
      _push(ToastType.error, message, title: title ?? 'Algo salió mal', duration: duration);

  static void warning(String message, {String? title, Duration duration = const Duration(seconds: 4)}) =>
      _push(ToastType.warning, message, title: title ?? 'Atención', duration: duration);

  static void info(String message, {String? title, Duration duration = const Duration(seconds: 3)}) =>
      _push(ToastType.info, message, title: title ?? 'Info', duration: duration);

  static void dismiss(int id) => _remove(id);

  static void _push(ToastType type, String message, {String? title, required Duration duration}) {
    _ensureOverlay();
    final id = _idCounter++;
    _toasts.value = [..._toasts.value, _ToastEntry(id: id, type: type, title: title, message: message)];
    Future.delayed(duration, () => _remove(id));
  }

  static void _remove(int id) {
    _toasts.value = _toasts.value.where((t) => t.id != id).toList();
  }

  static void _ensureOverlay() {
    if (_overlayEntry != null) return;
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;
    _overlayEntry = OverlayEntry(builder: (context) => _ToastStack(listenable: _toasts));
    overlayState.insert(_overlayEntry!);
  }
}

class _ToastEntry {
  const _ToastEntry({required this.id, required this.type, required this.title, required this.message});
  final int id;
  final ToastType type;
  final String? title;
  final String message;
}

class _ToastStack extends StatelessWidget {
  const _ToastStack({required this.listenable});
  final ValueNotifier<List<_ToastEntry>> listenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<_ToastEntry>>(
      valueListenable: listenable,
      builder: (context, toasts, _) {
        return Positioned(
          top: 20,
          right: 20,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final t in toasts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SizedBox(
                      width: 340,
                      child: _ToastCard(key: ValueKey(t.id), entry: t, onDismiss: () => ToastService._remove(t.id)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.entry, required this.onDismiss});
  final _ToastEntry entry;
  final VoidCallback onDismiss;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({IconData icon, Color color}) get _visual => switch (widget.entry.type) {
        ToastType.success => (icon: Icons.check_circle_rounded, color: AppColors.success),
        ToastType.error => (icon: Icons.error_rounded, color: AppColors.error),
        ToastType.warning => (icon: Icons.warning_rounded, color: AppColors.statusReview),
        ToastType.info => (icon: Icons.info_rounded, color: AppColors.statusInProgress),
      };

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _controller,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(visual.icon, size: 20, color: visual.color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.entry.title != null)
                        Text(widget.entry.title!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                      Text(widget.entry.message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: widget.onDismiss,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
