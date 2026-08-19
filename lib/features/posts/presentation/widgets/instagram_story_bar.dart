import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/enums.dart';
import '../../data/stories_repository.dart';
import '../../domain/post_model.dart';

class InstagramStoryBar extends ConsumerWidget {
  const InstagramStoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue — أثناء فشل الشبكة يُعرض آخر محتوى محلي من المخزن
    final storiesAsync = ref.watch(storiesProvider);
    final allStories = storiesAsync.value ?? const [];
    final session = ref.watch(sessionProvider);
    final isPublisherOrAdmin =
        session.isAdmin || session.profile?.role == UserRole.publisher;

    // قصة المستخدم الموحدة 'قصتك'
    final myStoryIndex = allStories.indexWhere(
      (s) =>
          s.id == 'my_story' ||
          s.title == 'قصتك' ||
          s.title == 'قصتي' ||
          s.title == 'موكب أمنا الزهراء (ع)',
    );
    final myStory = myStoryIndex != -1 ? allStories[myStoryIndex] : null;

    // باقي قصص الأقسام / الأشخاص دون تكرار
    final otherStories = allStories.where((s) => s != myStory).toList();

    // إذا لم تكن هناك ستوريز والمستخدم ليس ناشراً أو مديراً
    if (allStories.isEmpty && !isPublisherOrAdmin) {
      return const SizedBox.shrink();
    }

    final hasMyStory = myStory != null;
    final showAddSlot = isPublisherOrAdmin || hasMyStory;
    final totalCount = (showAddSlot ? 1 : 0) + otherStories.length;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (showAddSlot) {
            if (i == 0) {
              return _AddStoryItem(existingStory: myStory);
            }
            final story = otherStories[i - 1];
            return _StoryCircleItem(story: story);
          } else {
            final story = otherStories[i];
            return _StoryCircleItem(story: story);
          }
        },
      ),
    );
  }
}

class _AddStoryItem extends ConsumerStatefulWidget {
  const _AddStoryItem({this.existingStory});
  final StoryModel? existingStory;

  @override
  ConsumerState<_AddStoryItem> createState() => _AddStoryItemState();
}

class _AddStoryItemState extends ConsumerState<_AddStoryItem> {
  bool _isUploading = false;

  Future<void> _pickAndUploadStory() async {
    final session = ref.read(sessionProvider);
    final isPublisherOrAdmin =
        session.isAdmin || session.profile?.role == UserRole.publisher;

    if (!isPublisherOrAdmin) {
      _showStoryAdminPublisherOnlyDialog(context);
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      // نستخدم مسار الملف المحلي المباشر كـ file:// أو كمسار محلي
      final localFilePath = pickedFile.path;

      // وأيضاً نجهّز Data URL لضمان المزامنة
      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mimeType;base64,$base64String';

      final publisherName = session.profile?.fullName.isNotEmpty == true
          ? session.profile!.fullName
          : 'قصتك';

      // النشر في مزود القصص بإلحاق الصورة بالقصة الحالية
      await ref.read(storiesProvider.notifier).publishNewStory(
            imageUrl: localFilePath.isNotEmpty ? localFilePath : dataUri,
            publisherName: publisherName,
            caption: 'تغطية جديدة',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.greenDeep,
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.goldBright, size: 20),
                SizedBox(width: 8),
                Text(
                  'تمت إضافة القصة بنجاح!',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر نشر القصة: $e'),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showStoryAdminPublisherOnlyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A15) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.6 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تنبيه الصلاحيات',
                style: TextStyle(
                  fontFamily: AppTheme.displayFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نشر القصص اليومية والتغطيات (الستوري) مخصص لمدير النظام والناشر المعتمد فقط.\nإذا كنت ترغب في نشر تغطية للموكب، يرجى التواصل مع إدارة الموكب لتعيينك كناشر.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334438),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.greenAbyss,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'فهمت ذلك',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(sessionProvider);
    final isPublisherOrAdmin =
        session.isAdmin || session.profile?.role == UserRole.publisher;
    final userAvatar = session.profile?.avatarUrl;
    final hasStories = widget.existingStory != null &&
        widget.existingStory!.items.isNotEmpty;
    final isViewed = widget.existingStory?.isViewed ?? true;

    return GestureDetector(
      onTap: () {
        if (_isUploading) return;
        if (hasStories) {
          ref
              .read(storiesProvider.notifier)
              .markAsViewed(widget.existingStory!.id);
          _StoryViewerModal.show(context, widget.existingStory!);
        } else if (isPublisherOrAdmin) {
          _pickAndUploadStory();
        } else {
          _showStoryAdminPublisherOnlyDialog(context);
        }
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStories && !isViewed
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFBAA47),
                            Color(0xFFD62976),
                            Color(0xFF962FBF),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        )
                      : null,
                  border: hasStories && !isViewed
                      ? null
                      : Border.all(
                          color: _isUploading
                              ? AppColors.gold
                              : (isDark ? Colors.white24 : Colors.black12),
                          width: 1.8,
                        ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF161B18) : Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: _isUploading
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.gold,
                              ),
                            ),
                          )
                        : (hasStories
                            ? _StoryCircleItem._buildImage(
                                widget.existingStory!.coverUrl,
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                              )
                            : (userAvatar != null && userAvatar.isNotEmpty
                                ? _StoryCircleItem._buildImage(
                                    userAvatar,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  )
                                : _defaultAvatar(isDark))),
                  ),
                ),
              ),
              if (isPublisherOrAdmin)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadStory,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'قصتك',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textOnDarkMuted
                  : AppColors.textOnLightMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(bool isDark) {
    return CircleAvatar(
      backgroundColor: isDark ? const Color(0xFF222823) : Colors.grey.shade200,
      child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 30),
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
                child: _buildImage(
                  story.coverUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
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

  static Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppColors.gold.withValues(alpha: 0.2),
        child: const Icon(Icons.photo_rounded, color: AppColors.gold),
      );
    }

    // 1. ملف محلي من المعرض
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:image')) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.high,
          );
        }
      } catch (_) {}
    }

    // 2. صورة Data URL (Base64)
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = url.substring(commaIdx + 1);
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.high,
          );
        }
      } catch (_) {}
    }

    // 3. رابط إنترنت Network
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppColors.gold.withValues(alpha: 0.2),
        child: const Icon(Icons.photo_rounded, color: AppColors.gold),
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
              // Image (File, Base64 or Network)
              Positioned.fill(
                child: _buildStoryViewerImage(item.imageUrl),
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
                        ClipOval(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: _buildStoryViewerImage(widget.story.coverUrl),
                          ),
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
                        Consumer(
                          builder: (context, ref, _) => IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 22),
                            tooltip: 'حذف هذه القصة',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E2620),
                                  title: const Text('حذف القصة', style: TextStyle(color: Colors.white, fontFamily: AppTheme.displayFamily)),
                                  content: const Text('هل أنت متأكد من حذف هذه الصورة من القصة؟', style: TextStyle(color: Colors.white70, fontFamily: AppTheme.fontFamily)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white60))),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.overdue))),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await ref.read(storiesProvider.notifier).deleteStoryItem(widget.story.id, item.id);
                                if (!context.mounted) return;
                                if (widget.story.items.length <= 1) {
                                  Navigator.pop(context);
                                } else {
                                  _nextStory();
                                }
                              }
                            },
                          ),
                        ),
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

  Widget _buildStoryViewerImage(String url) {
    if (url.isEmpty) {
      return const Center(
        child: Icon(Icons.photo_rounded, color: Colors.white54, size: 64),
      );
    }

    // 1. ملف محلي من المعرض
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:image')) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
        }
      } catch (_) {}
    }

    // 2. صورة Data URL (Base64)
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = url.substring(commaIdx + 1);
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
        }
      } catch (_) {}
    }

    // 3. رابط إنترنت Network
    return Image.network(
      url,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
      ),
    );
  }
}
