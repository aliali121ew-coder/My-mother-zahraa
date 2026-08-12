import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/mock_posts_data.dart';
import '../../domain/post_model.dart';

class InstagramStoryBar extends ConsumerWidget {
  const InstagramStoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);

    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _AddStoryItem();
          }
          final story = stories[i - 1];
          return _StoryCircleItem(story: story);
        },
      ),
    );
  }
}

class _AddStoryItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: isDark ? const Color(0xFF222823) : Colors.grey.shade200,
                  child: const Icon(Icons.campaign_rounded, color: AppColors.gold, size: 28),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'جديد',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
          ),
        ),
      ],
    );
  }
}

class _StoryCircleItem extends ConsumerWidget {
  const _StoryCircleItem({required this.story});

  final StoryModel story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ref.read(storiesProvider.notifier).markAsViewed(story.id);
        _StoryViewerModal.show(context, story);
      },
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isViewed
                  ? null
                  : const LinearGradient(
                      colors: [
                        Color(0xFFFBAA47),
                        Color(0xFFD62976),
                        Color(0xFF962FBF),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
              border: story.isViewed
                  ? Border.all(
                      color: isDark ? Colors.white30 : Colors.black26,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131714) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  story.coverUrl,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    child: const Icon(Icons.photo_rounded, color: AppColors.gold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 68,
            child: Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: story.isViewed ? FontWeight.normal : FontWeight.w600,
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryViewerModal extends StatefulWidget {
  const _StoryViewerModal({required this.story});

  final StoryModel story;

  static void show(BuildContext context, StoryModel story) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StoryViewer',
      pageBuilder: (ctx, anim1, anim2) => _StoryViewerModal(story: story),
    );
  }

  @override
  State<_StoryViewerModal> createState() => _StoryViewerModalState();
}

class _StoryViewerModalState extends State<_StoryViewerModal> {
  int _currentIndex = 0;
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startStoryTimer();
  }

  void _startStoryTimer() {
    _timer?.cancel();
    _progress = 0.0;
    const duration = Duration(milliseconds: 50);
    final totalSteps = (widget.story.items[_currentIndex].durationSeconds * 1000) / 50;

    _timer = Timer.periodic(duration, (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 1 / totalSteps;
        if (_progress >= 1.0) {
          _timer?.cancel();
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.story.items.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startStoryTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startStoryTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.story.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStory();
            } else {
              _nextStory();
            }
          },
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                  ),
                ),
              ),
              // Story overlay header
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    // Segmented Progress bar
                    Row(
                      children: [
                        for (int i = 0; i < widget.story.items.length; i++) ...[
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: LinearProgressIndicator(
                                value: i < _currentIndex
                                    ? 1.0
                                    : (i == _currentIndex ? _progress : 0.0),
                                backgroundColor: Colors.white30,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.gold,
                          child: Icon(Icons.star_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.story.title,
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Caption at bottom
              if (item.caption != null)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Text(
                      item.caption!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
