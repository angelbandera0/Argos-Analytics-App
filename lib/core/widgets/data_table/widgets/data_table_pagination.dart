import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_text_styles.dart';
import '../app_data_table_controller.dart';

/// "Showing X of Y results" + numbered pagination with ellipsis, matching
/// the reference design (e.g. `1 2 3 … 8 9 10`).
class DataTablePagination<T> extends StatelessWidget {
  const DataTablePagination({super.key, required this.controller});

  final AppDataTableController<T> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.page;
        final pageCount = controller.pageCount;
        final shown = controller.items.length;

        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Text(
              'Showing $shown of ${controller.totalCount} results',
              style: AppTextStyles.bodySmall,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavButton(icon: Icons.chevron_left_rounded, enabled: page > 1, onTap: controller.previousPage),
                  const SizedBox(width: AppSpacing.xs),
                  for (final entry in _buildPageSequence(page, pageCount))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: entry == null
                          ? const _Ellipsis()
                          : _PageButton(page: entry, active: entry == page, onTap: () => controller.goToPage(entry)),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  _NavButton(icon: Icons.chevron_right_rounded, enabled: page < pageCount, onTap: controller.nextPage),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds a compact page list like `1 2 3 … 8 9 10`, using `null` as the
  /// ellipsis marker.
  List<int?> _buildPageSequence(int current, int total) {
    if (total <= 7) return List.generate(total, (i) => i + 1);

    final pages = <int?>{1, 2, 3, total - 2, total - 1, total, current - 1, current, current + 1}
        .where((p) => p != null && p! >= 1 && p <= total)
        .toList()
      ..sort();

    final result = <int?>[];
    for (var i = 0; i < pages.length; i++) {
      if (i > 0 && pages[i]! - pages[i - 1]! > 1) result.add(null);
      result.add(pages[i]);
    }
    return result;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.page, required this.active, required this.onTap});
  final int page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          '$page',
          style: AppTextStyles.bodySmall.copyWith(
            color: active ? AppColors.white : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.textSecondary : AppColors.textMuted),
      ),
    );
  }
}

class _Ellipsis extends StatelessWidget {
  const _Ellipsis();
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 24, child: Center(child: Text('…', style: AppTextStyles.bodySmall)));
  }
}
