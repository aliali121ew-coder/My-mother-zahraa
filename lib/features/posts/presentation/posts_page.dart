import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../shared/models/permissions.dart';
import '../data/posts_repository.dart';
import '../domain/post_model.dart';
import '../../settings/presentation/edit_profile_page.dart';
import 'create_post_flow_page.dart';
import 'interactions_activity_page.dart';
import 'widgets/instagram_post_card.dart';
import 'widgets/instagram_story_bar.dart';
import 'yearly_archive_page.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final postsAsync = ref.watch(postsProvider);

    // تحميل أولي من الخادم مع إبقاء آخر خلاصة محلية أثناء عدم الاتصال
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        // الارتداد للمخزن المحلي المحفوظ عند فشل الشبكة كليًا
        final local = ref.read(postsProvider).valueOrNull ?? const [];
        if (local.isNotEmpty) {
          return _PostsFeedBody(
            posts: local,
            onPullRefresh: () => ref.read(postsProvider.notifier).refresh(),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 44, color: AppColors.gold),
              const SizedBox(height: 10),
              Text(
                'تعذر تحميل الخلاصة — جرّب السحب للتحديث لاحقًا',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                ),
              ),
            ],
          ),
        );
      },
      data: (posts) => _PostsFeedBody(
        posts: posts,
        onPullRefresh: () => ref.read(postsProvider.notifier).refresh(),
      ),
    );
  }
}

class _PostsFeedBody extends ConsumerWidget {
  const _PostsFeedBody({
    required this.posts,
    required this.onPullRefresh,
  });

  final List<PostModel> posts;
  final Future<void> Function() onPullRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(sessionProvider);
    final canPublish = session.role.canPublish;

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
          if (canPublish) ...[
            IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: AppColors.gold,
                size: 25,
              ),
              tooltip: 'إعدادات الملف الشخصي',
              onPressed: () => EditProfilePage.navigate(context),
            ),
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
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onPullRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          cacheExtent: 1500,
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

            const SliverToBoxAdapter(child: SizedBox(height: 6)),

            // 2. Posts Feed List
            posts.isEmpty
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
                            'لا توجد منشورات حالياً',
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
                          final post = posts[index];
                          return RepaintBoundary(
                            child: InstagramPostCard(
                              key: ValueKey(post.id),
                              post: post,
                            ),
                          );
                        },
                        childCount: posts.length,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
