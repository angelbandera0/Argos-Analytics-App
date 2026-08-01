import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/board_mock_data.dart';
import '../widgets/kanban_column.dart';

/// `/dashboard/board` — the only section implemented in full, matching the
/// reference design (Publications > Board).
class ProjectsBoardScreen extends StatelessWidget {
  const ProjectsBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: const _BoardTopBar(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final col in mockBoardColumns) SizedBox(height: 640, child: KanbanColumn(column: col))],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardTopBar extends StatelessWidget {
  const _BoardTopBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _ViewTab(icon: Icons.list_rounded, label: 'List', section: 'publications-list'),
            SizedBox(width: AppSpacing.sm),
            _ViewTab(icon: Icons.dashboard_rounded, label: 'Board', section: 'board', active: true),
            SizedBox(width: AppSpacing.sm),
            _ViewTab(icon: Icons.view_kanban_rounded, label: 'Workflow', section: 'publications-workflow'),
            SizedBox(width: AppSpacing.sm),
            _ViewTab(icon: Icons.calendar_month_rounded, label: 'Calendar', section: 'publications-calendar'),
            Spacer(),
            _InviteButton(),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Tasks...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(icon: Icons.filter_list_rounded, label: 'Filters', onTap: () {}),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(icon: Icons.person_outline_rounded, label: 'Me', onTap: () {}),
            const SizedBox(width: AppSpacing.sm),
            _PillButton(icon: Icons.visibility_outlined, label: 'Show', onTap: () {}),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add task'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({required this.icon, required this.label, required this.section, this.active = false});
  final IconData icon;
  final String label;
  final String section;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go('/dashboard/$section'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 16, color: active ? AppColors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: active ? AppColors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
      label: const Text('Invite'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    );
  }
}
