import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/posts_repository.dart';
import '../../data/stories_repository.dart';
import '../../domain/post_model.dart';
import '../create_post_flow_page.dart';
import 'comments_bottom_sheet.dart';
import 'location_map_dialog.dart';

class InstagramPostCard extends ConsumerStatefulWidget {
  const InstagramPostCard({
    super.key,
    required this.post,
  });

  final PostModel post;

  @override
  ConsumerState<InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends ConsumerState<InstagramPostCard>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  bool _isExpandedCaption = false;
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnim = CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onDoubleTapLike() {
    if (!widget.post.isLiked) {
      ref
          .read(postsProvider.notifier)
          .toggleLike(widget.post.id, widget.post.isLiked);
    }
    setState(() {
      _showHeartAnimation = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showHeartAnimation = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.zero,
      radius: 20,
      borderColor: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.gold.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official Publisher Header with Verified Badge & Interactive Location
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: _buildPublisherAvatar(post.publisherAvatar),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.publisherName,
                              style: TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: AppColors.gold, size: 15),
                          ],
                        ],
                      ),
                      if (post.location != null)
                        GestureDetector(
                          onTap: () => LocationMapDialog.show(context, post.location!),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 12),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  post.location!,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.normal,
                                    color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (post.audioTrackTitle != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note_rounded, color: AppColors.gold, size: 12),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                post.audioTrackTitle!,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10,
                                  color: isDark ? AppColors.goldBright : AppColors.goldDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 21,
                  ),
                  tooltip: 'خيارات المنشور',
                  offset: const Offset(0, 36),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : AppColors.gold.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  color: isDark ? const Color(0xFF1B221E) : Colors.white,
                  onSelected: (value) async {
                    if (value == 'story') {
                      if (post.images.isNotEmpty) {
                        await ref.read(storiesProvider.notifier).publishNewStory(
                          imageUrl: post.images.first,
                          publisherName: post.publisherName,
                          caption: post.caption,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'تمت مشاركة المنشور في الستوري بنجاح 🌟✨',
                                      style: TextStyle(
                                          fontFamily: AppTheme.fontFamily),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.greenDeep,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        }
                      }
                    } else if (value == 'edit') {
                      CreatePostFlowPage.navigate(context, existingPost: post);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(context);
                    } else if (value == 'copy') {
                      Clipboard.setData(ClipboardData(
                          text: '${post.caption}\n\nموكب أمنا الزهراء (ع)'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              const Text('تم نسخ تفاصيل المنشور للحافظة ✨'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      value: 'story',
                      height: 44,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.purple.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.auto_stories_rounded,
                                color: Colors.purpleAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'مشاركة استوري 🌟',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'edit',
                      height: 44,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.edit_note_rounded,
                                color: AppColors.gold, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تعديل المنشور ✏️',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'copy',
                      height: 44,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.link_rounded,
                                color: Colors.blueAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'نسخ الرابط 📋',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'delete',
                      height: 44,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'حذف المنشور 🗑️',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Carousel Media with Double Tap Heart Animation
          GestureDetector(
            onDoubleTap: _onDoubleTapLike,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 340,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: post.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, i) {
                      return _ZoomableResetImage(
                        imageUrl: post.images[i],
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                // Double tap Heart Animation
                if (_showHeartAnimation)
                  ScaleTransition(
                    scale: _heartScaleAnim,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent.withValues(alpha: 0.95),
                      size: 100,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                // Page Indicator Badge
                if (post.images.length > 1)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${post.images.length}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: post.isLiked ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                    size: 26,
                  ),
                  onPressed: () {
                    ref
                        .read(postsProvider.notifier)
                        .toggleLike(post.id, post.isLiked);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                  onPressed: () => CommentsBottomSheet.show(context, post),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 23,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تمت مشاركة المنشور بنجاح 🚀'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Carousel dots indicator
                if (post.images.length > 1)
                  Row(
                    children: [
                      for (int i = 0; i < post.images.length; i++) ...[
                        Container(
                          width: _currentImageIndex == i ? 7 : 5,
                          height: _currentImageIndex == i ? 7 : 5,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == i
                                ? AppColors.gold
                                : (isDark ? Colors.white30 : Colors.black26),
                          ),
                        ),
                      ],
                    ],
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: post.isSaved ? AppColors.gold : (isDark ? Colors.white : Colors.black87),
                    size: 25,
                  ),
                  onPressed: () {
                    ref
                        .read(postsProvider.notifier)
                        .toggleSave(post.id, post.isSaved);
                  },
                ),
              ],
            ),
          ),
          // Likes & Interaction Bar with overlapping avatars of users on the right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                // Overlapping Avatars for users who liked/commented
                SizedBox(
                  height: 24,
                  width: 48,
                  child: Stack(
                    children: [
                      const Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 14,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 28,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: isDark ? AppColors.greenAbyss : AppColors.gold,
                            child: const Icon(Icons.favorite, size: 9, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'أعجب به ${post.likesCount} شخصاً',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                  ),
                ),
              ],
            ),
          ),
          // Caption with expandable text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpandedCaption = !_isExpandedCaption;
                });
              },
              child: Text(
                post.caption,
                maxLines: _isExpandedCaption ? null : 2,
                overflow: _isExpandedCaption ? TextOverflow.clip : TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.5,
                  color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // View comments trigger button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: () => CommentsBottomSheet.show(context, post),
              child: Text(
                'عرض كافة التعليقات (${post.commentsCount})...',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Timestamp & Year Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Text(
                  'قبل ٣ ساعات',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    post.yearTag,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  void _showDeleteConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.greenDeepest : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'حذف المنشور',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف هذا المنشور؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await ref.read(postsProvider.notifier).deletePost(widget.post.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المنشور بنجاح 🗑️'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، حذف'),
          ),
        ],
      ),
    );
  }
}

class _ZoomableResetImage extends StatefulWidget {
  const _ZoomableResetImage({
    required this.imageUrl,
    required this.isDark,
  });

  final String imageUrl;
  final bool isDark;

  @override
  State<_ZoomableResetImage> createState() => _ZoomableResetImageState();
}

class _ZoomableResetImageState extends State<_ZoomableResetImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final url = widget.imageUrl;

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = url.substring(commaIdx + 1);
          final bytes = base64Decode(base64Str);
          imageWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            cacheWidth: 800,
            cacheHeight: 800,
          );
        } else {
          imageWidget = _errorPlaceholder();
        }
      } catch (_) {
        imageWidget = _errorPlaceholder();
      }
    } else if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('assets/')) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 800,
            cacheHeight: 800,
          );
        } else {
          imageWidget = _errorPlaceholder();
        }
      } catch (_) {
        imageWidget = _errorPlaceholder();
      }
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(url, fit: BoxFit.cover);
    } else {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: 800,
        cacheHeight: 800,
        errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      onInteractionEnd: _onInteractionEnd,
      panEnabled: true,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      clipBehavior: Clip.none,
      minScale: 1.0,
      maxScale: 5.0,
      child: imageWidget,
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: widget.isDark ? const Color(0xFF222823) : Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 48,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

Widget _buildPublisherAvatar(String url) {
  if (url.isEmpty || url.startsWith('assets/')) {
    return const CircleAvatar(
      backgroundColor: AppColors.greenAbyss,
      child: Icon(Icons.mosque_rounded, color: AppColors.gold, size: 19),
    );
  }

  // 1. ملف محلي
  if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:image')) {
    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: 36, height: 36);
      }
    } catch (_) {}
  }

  // 2. Data URL Base64
  if (url.startsWith('data:image')) {
    try {
      final commaIdx = url.indexOf(',');
      if (commaIdx != -1) {
        final base64Str = url.substring(commaIdx + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, width: 36, height: 36);
      }
    } catch (_) {}
  }

  // 3. Network
  return Image.network(
    url,
    fit: BoxFit.cover,
    width: 36,
    height: 36,
    errorBuilder: (_, _, _) => const CircleAvatar(
      backgroundColor: AppColors.greenAbyss,
      child: Icon(Icons.mosque_rounded, color: AppColors.gold, size: 19),
    ),
  );
}
