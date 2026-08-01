import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Consistent modal chrome (rounded card, title + close button, content,
/// right-aligned actions) so every dialog in the app looks the same
/// instead of each screen rolling its own `showDialog` boilerplate.
///
/// [contentBuilder] and [actionsBuilder] receive the dialog's own
/// [BuildContext] (not the caller's), which is what you need to call
/// `Navigator.of(dialogContext).pop()` correctly from inside an action.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder contentBuilder,
  List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
  double width = 480,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: AppTextStyles.h3)),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(child: SingleChildScrollView(child: contentBuilder(dialogContext))),
                if (actionsBuilder != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: actionsBuilder(dialogContext)),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
