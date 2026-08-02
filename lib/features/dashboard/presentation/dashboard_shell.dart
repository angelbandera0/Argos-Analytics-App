import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_top_bar.dart';

/// Width from which the sidebar is visible by default (tablet landscape
/// and up). Below it — mobile and tablet **portrait** — it starts hidden
/// so it doesn't eat into the content, and opens as an overlay drawer.
const double kSidebarAutoShowWidth = 1000;

/// Persistent layout used by every `/dashboard/*` route (wired through
/// the `TypedShellRoute` in `app_router.dart`). Fully responsive:
/// - Wide layouts (>= [kSidebarAutoShowWidth]): sidebar sits inline,
///   pushing content — same behavior as before, still collapsible via
///   the top bar's menu button for extra room.
/// - Narrow layouts (mobile, tablet portrait): sidebar starts hidden and
///   opens as a scrim + slide-in drawer over the content, closing again
///   on scrim tap or after navigating anywhere.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  /// User's manual override, relative to each layout's default:
  /// - on wide layouts (default OPEN), `true` means "I collapsed it".
  /// - on narrow layouts (default CLOSED), `true` means "I opened it".
  bool _userToggled = false;

  void _toggle() => setState(() => _userToggled = !_userToggled);
  void _close() => setState(() => _userToggled = false);

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kSidebarAutoShowWidth;
            final sidebarOpen = isWide ? !_userToggled : _userToggled;

            final content = Column(
              children: [
                DashboardTopBar(onMenuTap: _toggle),
                Expanded(child: widget.child),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRect(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: sidebarOpen ? 340 : 0,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: 340,
                        maxWidth: 340,
                        child: DashboardSidebar(currentPath: currentPath),
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              );
            }

            // Narrow layout: sidebar renders as a scrim + slide-in drawer
            // above the content instead of taking permanent space. Both
            // stay mounted (so the slide/fade actually animates instead
            // of popping in already-open) and just ignore touches while
            // hidden.
            return Stack(
              children: [
                content,
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !sidebarOpen,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: sidebarOpen ? 1 : 0,
                      child: GestureDetector(
                        onTap: _close,
                        child: Container(color: Colors.black.withValues(alpha: 0.35)),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !sidebarOpen,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      offset: sidebarOpen ? Offset.zero : const Offset(-1, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          elevation: 8,
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: DashboardSidebar(currentPath: currentPath, onNavigate: _close),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
