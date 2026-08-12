import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/mock_posts_data.dart';
import '../../domain/post_model.dart';
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
      ref.read(postsProvider.notifier).toggleLike(widget.post.id);
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
                  child: const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.greenAbyss,
                    child: Icon(Icons.mosque_rounded, color: AppColors.gold, size: 19),
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
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ رابط المنشور إلى الحافظة ✨'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
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
                    ref.read(postsProvider.notifier).toggleLike(post.id);
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
                    ref.read(postsProvider.notifier).toggleSave(post.id);
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
                          radius: 11,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                        ),
                      ),
                      const Positioned(
                        right: 14,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
                        ),
                      ),
                      Positioned(
                        right: 28,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.gold,
                          child: Icon(
                            post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 11,
                            color: AppColors.greenAbyss,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أُعجب وعلّق عليه حسنين و ${post.likesCount} آخرين',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Caption Text without repeated title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
      duration: const Duration(milliseconds: 250),
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
    return InteractiveViewer(
      transformationController: _transformationController,
      onInteractionEnd: _onInteractionEnd,
      clipBehavior: Clip.none,
      minScale: 1.0,
      maxScale: 4.0,
      child: Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: widget.isDark ? const Color(0xFF222823) : Colors.grey.shade200,
          child: const Icon(
            Icons.image_not_supported_rounded,
            size: 48,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}
