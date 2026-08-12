import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../data/mock_posts_data.dart';
import 'create_post_flow_page.dart';
import 'interactions_activity_page.dart';
import 'widgets/instagram_post_card.dart';
import 'widgets/instagram_story_bar.dart';
import 'yearly_archive_page.dart';

enum _PostCategory { all, weeklyMajalis, muharram, projects, archive }

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  _PostCategory _selectedCategory = _PostCategory.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posts = ref.watch(postsProvider);

    // تصفية المنشورات
    final filteredPosts = posts.where((p) {
      switch (_selectedCategory) {
        case _PostCategory.all:
          return true;
        case _PostCategory.weeklyMajalis:
          return p.caption.contains('مجلس') || p.caption.contains('ذكرى') || p.caption.contains('عزاء');
        case _PostCategory.muharram:
          return p.caption.contains('الأربعينية') || p.caption.contains('محرم') || p.yearTag == '2025';
        case _PostCategory.projects:
          return p.caption.contains('بناية') || p.caption.contains('مشروع') || p.caption.contains('بناء');
        case _PostCategory.archive:
          return p.yearTag != '2026';
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AutoHidingAppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.favorite_border_rounded,
            color: AppColors.gold,
            size: 24,
          ),
          tooltip: 'سجل التفاعلات والإعجابات',
          onPressed: () => InteractionsActivityPage.navigate(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.gold,
              size: 24,
            ),
            tooltip: 'إضافة تغطية جديدة',
            onPressed: () => CreatePostFlowPage.navigate(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.collections_bookmark_rounded,
              color: AppColors.gold,
              size: 24,
            ),
            tooltip: 'معرض السنوات والأرشيف',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const YearlyArchivePage(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Instagram Story Bar Header
          const SliverToBoxAdapter(
            child: InstagramStoryBar(),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
            ),
          ),



          // 3. Category Filters Bar (شرائح تصفية المنشورات)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildCategoryChip(
                    label: 'الكل',
                    category: _PostCategory.all,
                    icon: Icons.dynamic_feed_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'مجالس أسبوعية',
                    category: _PostCategory.weeklyMajalis,
                    icon: Icons.mosque_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'محرم والأربعينية',
                    category: _PostCategory.muharram,
                    icon: Icons.flag_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'مشاريع وإعمار',
                    category: _PostCategory.projects,
                    icon: Icons.construction_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'أرشيف السنوات',
                    category: _PostCategory.archive,
                    icon: Icons.history_rounded,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // 4. Posts Feed List
          filteredPosts.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_album_outlined,
                          size: 56,
                          color: AppColors.gold,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'لا توجد منشورات في هذه الفئة حالياً',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = filteredPosts[index];
                        return InstagramPostCard(
                          key: ValueKey(post.id),
                          post: post,
                        );
                      },
                      childCount: filteredPosts.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required _PostCategory category,
    required IconData icon,
  }) {
    final selected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.22)
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.gold
              : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
          width: selected ? 1.2 : 0.8,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                    : (isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                      : (isDark ? AppColors.textOnDark : AppColors.textOnLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
