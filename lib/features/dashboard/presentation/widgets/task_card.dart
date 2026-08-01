import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/board_mock_data.dart';
import 'task_tag_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.data});
  final TaskCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: [for (final t in data.tags) TaskTagChip(tag: t)]),
              ),
              const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(data.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            data.description,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Progress', style: AppTextStyles.caption),
              const Spacer(),
              Text('${(data.progress * 100).round()}%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceSunken,
              valueColor: const AlwaysStoppedAnimation(AppColors.ink),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _AvatarStack(count: data.avatarCount, extra: data.extraCount),
              const Spacer(),
              if (data.comments > 0) _MetaIcon(icon: Icons.mode_comment_outlined, count: data.comments),
              if (data.links > 0) _MetaIcon(icon: Icons.link_rounded, count: data.links),
              if (data.attachments > 0) _MetaIcon(icon: Icons.description_outlined, count: data.attachments),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.count, required this.extra});
  final int count;
  final int extra;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return SizedBox(
      height: 24,
      width: (count + (extra > 0 ? 1 : 0)) * 16.0 + 8,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * 16.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.avatarPalette[i % AppColors.avatarPalette.length],
                child: const Icon(Icons.person, size: 12, color: Colors.white),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: count * 16.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.ink,
                child: Text('+$extra', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon, required this.count});
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 2),
          Text('$count', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
