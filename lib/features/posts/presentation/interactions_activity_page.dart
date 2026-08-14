import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/posts_repository.dart';
import 'post_detail_page.dart';

enum _InteractionFilter { all, comments, likes }

/// صفحة النشاطات والتفاعلات الانزلاقية المحسنة مع حماية من التوقف
class InteractionsActivityPage extends ConsumerStatefulWidget {
  const InteractionsActivityPage({super.key});

  /// الانتقال إلى الصفحة بأنيميشن انزلاق انسيابي وسريع
  static void navigate(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const InteractionsActivityPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: Curves.fastOutSlowIn),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<InteractionsActivityPage> createState() =>
      _InteractionsActivityPageState();
}

class _InteractionsActivityPageState
    extends ConsumerState<InteractionsActivityPage> {
  _InteractionFilter _selectedFilter = _InteractionFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posts = ref.watch(postsProvider).value ?? const [];

    // تجميع نشاطات التفاعل والتعليقات والإعجابات الحية من المنشورات
    final List<_InteractionItem> allInteractions = [];

    for (final post in posts) {
      // 1. إضافة التعليقات الفعلية الحية المنشورة على هذا المنشور
      for (final comment in post.comments) {
        allInteractions.add(
          _InteractionItem(
            userName: comment.userName,
            userAvatar: comment.userAvatar,
            type: _InteractionType.comment,
            commentText: comment.text,
            postCaption: post.caption,
            postImage: post.images.first,
            timeAgo: 'مؤخراً',
          ),
        );
      }

      // 2. إضافة الإعجابات الفعلية الحية
      if (post.isLiked) {
        allInteractions.add(
          _InteractionItem(
            userName: 'أنت (خادم الموكب)',
            userAvatar: 'assets/images/logo.png',
            type: _InteractionType.like,
            postCaption: post.caption,
            postImage: post.images.first,
            timeAgo: 'الآن',
          ),
        );
      }
    }

    final filteredInteractions = allInteractions.where((item) {
      switch (_selectedFilter) {
        case _InteractionFilter.all:
          return true;
        case _InteractionFilter.likes:
          return item.type == _InteractionType.like;
        case _InteractionFilter.comments:
          return item.type == _InteractionType.comment;
      }
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.greenDeepest : const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.greenDeepest : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'سجل التفاعلات والأنشطة',
          style: TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldBright : AppColors.goldDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Filter Segment (الكل - التعليقات - الإعجابات)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      label: 'الكل',
                      filter: _InteractionFilter.all,
                      icon: Icons.grid_view_rounded,
                    ),
                    _buildSegmentButton(
                      label: 'التعليقات',
                      filter: _InteractionFilter.comments,
                      icon: Icons.chat_bubble_rounded,
                    ),
                    _buildSegmentButton(
                      label: 'الإعجابات',
                      filter: _InteractionFilter.likes,
                      icon: Icons.favorite_rounded,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 2. Interactions List
            Expanded(
              child: filteredInteractions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 52,
                            color: AppColors.gold,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد تفاعلات حالياً',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark
                                  ? AppColors.textOnDarkMuted
                                  : AppColors.textOnLightMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                      itemCount: filteredInteractions.length,
                      itemBuilder: (context, index) {
                        final item = filteredInteractions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            blur: false,
                            radius: 18,
                            padding: const EdgeInsets.all(12),
                            onTap: () {
                              final targetPost = posts.firstWhere(
                                (p) => p.images.contains(item.postImage),
                                orElse: () => posts.first,
                              );

                              PostDetailPage.navigate(
                                context,
                                post: targetPost,
                                openCommentsImmediately: item.type == _InteractionType.comment,
                              );
                            },
                            child: Row(
                              children: [
                                // Avatar with type indicator badge
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: item.userAvatar.startsWith('assets/')
                                          ? Image.asset(
                                              item.userAvatar,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 44,
                                                height: 44,
                                                color: AppColors.gold.withValues(alpha: 0.2),
                                                child: const Icon(Icons.person, color: AppColors.gold),
                                              ),
                                            )
                                          : Image.network(
                                              item.userAvatar,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 44,
                                                height: 44,
                                                color: AppColors.gold.withValues(alpha: 0.2),
                                                child: const Icon(Icons.person, color: AppColors.gold),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: item.type == _InteractionType.like
                                              ? Colors.redAccent
                                              : AppColors.gold,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.greenDeepest
                                                : Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          item.type == _InteractionType.like
                                              ? Icons.favorite_rounded
                                              : Icons.chat_bubble_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Content Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.textOnDark
                                                : AppColors.textOnLight,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: item.userName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: item.type == _InteractionType.like
                                                  ? ' أبدى إعجابه بالتغطية'
                                                  : ' علّق: ',
                                            ),
                                            if (item.commentText != null)
                                              TextSpan(
                                                text: '"${item.commentText}"',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppColors.goldBright
                                                      : AppColors.goldDark,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.timeAgo,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 10.5,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.postImage.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.postImage,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 44,
                                        height: 44,
                                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                                        child: const Icon(Icons.image, size: 20, color: AppColors.gold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required _InteractionFilter filter,
    required IconData icon,
  }) {
    final selected = _selectedFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? AppColors.greenAbyss
                    : (isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? AppColors.greenAbyss
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

enum _InteractionType { like, comment }

class _InteractionItem {
  _InteractionItem({
    required this.userName,
    required this.userAvatar,
    required this.type,
    required this.postCaption,
    required this.postImage,
    required this.timeAgo,
    this.commentText,
  });

  final String userName;
  final String userAvatar;
  final _InteractionType type;
  final String postCaption;
  final String postImage;
  final String timeAgo;
  final String? commentText;
}
