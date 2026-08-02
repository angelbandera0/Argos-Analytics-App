import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Placeholder rendered for every dashboard section that hasn't been
/// implemented yet. Shows the friendly label and the actual route path,
/// so it's obvious which navigation entry triggered it.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.routeName, required this.path});

  final String routeName;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Coming soon', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            routeName,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(path, style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}
