import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/board_mock_data.dart';

class TaskTagChip extends StatelessWidget {
  const TaskTagChip({super.key, required this.tag});
  final TaskTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: tag.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        tag.label,
        style: AppTextStyles.caption.copyWith(color: tag.foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
