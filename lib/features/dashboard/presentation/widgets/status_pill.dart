import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_dot_pill.dart';
import '../../data/products_mock_data.dart';

/// Product-specific status badge, built on the generic [StatusDotPill].
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
  Widget build(BuildContext context) => StatusDotPill(label: status.label, color: _color);
}
