import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/post_model.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/instagram_post_card.dart';

/// صفحة عرض المنشور الفردي المستهدف بالتفصيل
class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({
    super.key,
    required this.post,
    this.openCommentsImmediately = false,
  });

  final PostModel post;
  final bool openCommentsImmediately;

  static void navigate(
    BuildContext context, {
    required PostModel post,
    bool openCommentsImmediately = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailPage(
          post: post,
          openCommentsImmediately: openCommentsImmediately,
        ),
      ),
    );
  }

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.openCommentsImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          CommentsBottomSheet.show(context, widget.post);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.greenDeepest : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'التغطية المستهدفة',
          style: TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldBright : AppColors.goldDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: InstagramPostCard(
          post: widget.post,
        ),
      ),
    );
  }
}
