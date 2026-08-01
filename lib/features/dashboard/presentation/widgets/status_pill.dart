import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/products_mock_data.dart';

/// Small colored dot + label pill used for row statuses across tables.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final ProductStatus status;

  Color get _color => switch (status) {
        ProductStatus.active => AppColors.success,
        ProductStatus.pending => AppColors.statusReview,
        ProductStatus.canceled => AppColors.textMuted,
        ProductStatus.rejected => AppColors.error,
        ProductStatus.inactive => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
