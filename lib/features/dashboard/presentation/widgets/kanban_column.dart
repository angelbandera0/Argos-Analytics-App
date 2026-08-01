import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/board_mock_data.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({super.key, required this.column});
  final BoardColumnData column;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: column.color, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.sm),
                Text(column.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('${column.tasks.length}', style: AppTextStyles.caption),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(children: [for (final t in column.tasks) TaskCard(data: t)]),
            ),
          ),
        ],
      ),
    );
  }
}
