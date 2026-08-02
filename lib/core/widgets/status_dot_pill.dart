import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Small colored dot + label pill — the generic building block behind
/// every status badge in the app (products, stores, users...).
class StatusDotPill extends StatelessWidget {
  const StatusDotPill({super.key, required this.label, required this.color, this.dense = false});

  final String label;
  final Color color;

  /// Slightly smaller padding, for tight spaces like table cells.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: dense ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
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
