import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Simple value object for a kanban tag chip (e.g. "Design", "Web").
class TaskTag {
  const TaskTag(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

class TaskCardData {
  const TaskCardData({
    required this.title,
    required this.description,
    required this.tags,
    required this.progress,
    required this.avatarCount,
    this.extraCount = 0,
    this.comments = 0,
    this.links = 0,
    this.attachments = 0,
  });

  final String title;
  final String description;
  final List<TaskTag> tags;
  final double progress; // 0..1
  final int avatarCount;
  final int extraCount;
  final int comments;
  final int links;
  final int attachments;
}

class BoardColumnData {
  const BoardColumnData({required this.title, required this.color, required this.tasks});
  final String title;
  final Color color;
  final List<TaskCardData> tasks;
}

const _design = TaskTag('Design', AppColors.tagDesign, AppColors.tagDesignText);
const _web = TaskTag('Web', AppColors.tagWeb, AppColors.tagWebText);
const _mobile = TaskTag('Mobile', AppColors.tagMobile, AppColors.tagMobileText);
const _dev = TaskTag('Dev', AppColors.tagDev, AppColors.tagDevText);
const _marketing = TaskTag('Marketing', AppColors.tagMarketing, AppColors.tagMarketingText);

/// Static mock data mirroring the reference design, used to render the
/// Publications board without a backend.
final List<BoardColumnData> mockBoardColumns = [
  BoardColumnData(
    title: 'To Do',
    color: AppColors.statusTodo,
    tasks: [
      TaskCardData(
        title: 'Create Onboarding Illustrations',
        description: 'Design a cohesive set of onboarding illustrations that introduce key product features.',
        tags: const [_design],
        progress: 0,
        avatarCount: 2,
        links: 1,
        attachments: 1,
      ),
      TaskCardData(
        title: 'Implement Push Notifications',
        description: 'Develop a flexible push notification system for mobile devices.',
        tags: const [_mobile, _dev],
        progress: 0,
        avatarCount: 3,
        comments: 3,
        links: 2,
      ),
      TaskCardData(
        title: 'Marketing Campaign Hub',
        description: 'Plan campaign assets, audience segments and scheduling.',
        tags: const [_marketing],
        progress: 0,
        avatarCount: 1,
      ),
    ],
  ),
  BoardColumnData(
    title: 'In Progress',
    color: AppColors.statusInProgress,
    tasks: [
      TaskCardData(
        title: 'Dashboard Navigation',
        description: 'Simplify the navigation structure',
        tags: const [_design, _web],
        progress: 0.12,
        avatarCount: 2,
        comments: 5,
        links: 3,
      ),
      TaskCardData(
        title: 'Content Review',
        description: 'Review landing page copy for consistency, readability, and conversion optimization.',
        tags: const [_web, _marketing],
        progress: 0.60,
        avatarCount: 1,
        links: 1,
        attachments: 1,
      ),
      TaskCardData(
        title: 'Media Optimization',
        description: 'Improve image loading performance with lazy loading, compression, and caching.',
        tags: const [_dev],
        progress: 0,
        avatarCount: 0,
      ),
    ],
  ),
  BoardColumnData(
    title: 'Review',
    color: AppColors.statusReview,
    tasks: [
      TaskCardData(
        title: 'Authentication Flow',
        description: 'Validate login, registration, password recovery, and social sign-in across supported devices.',
        tags: const [_web, _mobile, _dev],
        progress: 0.95,
        avatarCount: 3,
        extraCount: 2,
        comments: 5,
        links: 3,
        attachments: 2,
      ),
      TaskCardData(
        title: 'Subscription Billing',
        description: 'Integrate recurring payments, invoice generation, and secure subscription management.',
        tags: const [_web, _dev],
        progress: 0.54,
        avatarCount: 2,
        comments: 2,
        links: 1,
        attachments: 1,
      ),
      TaskCardData(
        title: 'Multi-Language Blog Platform',
        description: 'Add localization support for blog content across regions.',
        tags: const [_design, _mobile],
        progress: 0.30,
        avatarCount: 1,
      ),
    ],
  ),
  BoardColumnData(
    title: 'Completed',
    color: AppColors.statusDone,
    tasks: [
      TaskCardData(
        title: 'Design System Audit',
        description: 'Reviewed spacing, color tokens and component consistency.',
        tags: const [_design],
        progress: 1,
        avatarCount: 2,
        comments: 1,
        links: 1,
      ),
    ],
  ),
];
