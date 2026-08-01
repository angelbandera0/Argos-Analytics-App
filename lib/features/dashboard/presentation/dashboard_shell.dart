import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/dashboard_sidebar.dart';

/// Persistent layout used by every `/dashboard/*` route (wired through the
/// `TypedShellRoute` in `app_router.dart`). Only the sidebar is fixed here;
/// each screen decides its own content/top-bar so this layout stays 100%
/// reusable across current and future sections.
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSidebar(currentPath: currentPath),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
