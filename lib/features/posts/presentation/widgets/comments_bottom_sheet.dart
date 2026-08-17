import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/posts_repository.dart';
import '../../domain/post_model.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  const CommentsBottomSheet({
    super.key,
    required this.post,
  });

  final PostModel post;

  static void show(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(post: post),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // تحميل التعليقات مرة واحدة فقط عند فتح الشيت
    Future.microtask(() {
      if (mounted) {
        ref.read(postsProvider.notifier).loadComments(widget.post.id);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(sessionProvider);
    final userName = session.profile?.fullName.isNotEmpty == true
        ? session.profile!.fullName
        : 'زائر حسيني';

    _commentController.clear();
    FocusScope.of(context).unfocus();

    await ref
        .read(postsProvider.notifier)
        .addComment(widget.post.id, text, userName);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // AsyncValue — أثناء فشل الشبكة يُستخدم المنشور ذاته كمرجع محلي
    final postsAsync = ref.watch(postsProvider);
    final currentPost = postsAsync.value?.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        ) ??
        widget.post;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white30 : Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'التعليقات (${currentPost.comments.length})',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Comments list
          Expanded(
            child: currentPost.comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد تعليقات بعد\nكُن أول المعلقين!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: currentPost.comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final c = currentPost.comments[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                            backgroundImage: c.userAvatar.startsWith('http')
                                ? NetworkImage(c.userAvatar)
                                : (c.userAvatar.startsWith('assets/')
                                    ? AssetImage(c.userAvatar) as ImageProvider
                                    : null),
                            child: !c.userAvatar.startsWith('http') &&
                                    !c.userAvatar.startsWith('assets/')
                                ? const Icon(Icons.person_rounded,
                                    color: AppColors.gold, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.userName,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  c.text,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13.5,
                                    color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              c.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              size: 16,
                              color: c.isLiked ? Colors.redAccent : (isDark ? Colors.white30 : Colors.black38),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // Input row
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: ref.watch(sessionProvider).profile?.avatarUrl != null &&
                              ref.watch(sessionProvider).profile!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              ref.watch(sessionProvider).profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.gold,
                                child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                              ),
                            )
                          : const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.gold,
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'إضافة تعليق بمحبة...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.gold),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
