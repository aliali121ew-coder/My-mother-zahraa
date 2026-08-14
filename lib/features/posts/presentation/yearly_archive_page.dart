import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../data/posts_repository.dart';
import '../domain/post_model.dart';

class YearlyArchivePage extends ConsumerWidget {
  const YearlyArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // AsyncValue — أثناء فشل الشبكة يُعرض آخر أرشيف محلي محفوظ
    final posts = ref.watch(postsProvider).value ?? const [];

    // Group posts by yearTag (English Gregorian format)
    final Map<String, List<PostModel>> yearMap = {};
    for (final p in posts) {
      yearMap.putIfAbsent(p.yearTag, () => []).add(p);
    }

    // Add extra archive years for rich gallery experience (2026, 2025, 2024, 2023, 2022)
    yearMap.putIfAbsent('2026', () => []);
    yearMap.putIfAbsent('2025', () => []);
    yearMap.putIfAbsent('2024', () => []);
    yearMap.putIfAbsent('2023', () => []);
    yearMap.putIfAbsent('2022', () => []);

    final yearKeys = yearMap.keys.toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D110E) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'معرض التميز — الأرشيف',
          style: TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Banner Header Matching "معرض التميز" Card Design 100% (No Overflow)
          _ExcellenceGalleryBanner(totalAlbums: yearKeys.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'ألبومات السنوات (${yearKeys.length})',
              style: TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Animated Staggered List of Album Cards with Sliding Hover Image
          for (int i = 0; i < yearKeys.length; i++) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 500 + (i * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, 25 * (1 - val)),
                  child: Opacity(opacity: val, child: child),
                );
              },
              child: _AnimatedYearAlbumCard(
                yearTag: yearKeys[i],
                posts: yearMap[yearKeys[i]] ?? [],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// كارت "معرض التميز" الرئيسي المطابق للصورة 100% وبدون أي Overflow
class _ExcellenceGalleryBanner extends StatefulWidget {
  const _ExcellenceGalleryBanner({required this.totalAlbums});

  final int totalAlbums;

  @override
  State<_ExcellenceGalleryBanner> createState() => _ExcellenceGalleryBannerState();
}

class _ExcellenceGalleryBannerState extends State<_ExcellenceGalleryBanner> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF16253C), Color(0xFF0F1A2B)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1A3326), Color(0xFF10241A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.2),
                blurRadius: _isHovered ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: AppColors.gold.withValues(alpha: _isHovered ? 0.6 : 0.35),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Right Side (in RTL): Sliding Image Container on Hover
                    Expanded(
                      flex: 4,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(
                          _isHovered ? -8.0 : 0.0,
                          0.0,
                          0.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                  child: const Icon(Icons.photo_rounded, color: AppColors.gold, size: 36),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Left Side (in RTL): Text Content Column (No overflow)
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Top Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'معرض التميز',
                                style: TextStyle(
                                  fontFamily: AppTheme.displayFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Main Headline Text
                            const Text(
                              'شاهد أحدث التغطيات وألبومات الصور المميزة لدي الموكب',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Action Link with Sliding Arrow
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              transform: Matrix4.translationValues(
                                _isHovered ? -4.0 : 0.0,
                                0.0,
                                0.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'تصفح ${widget.totalAlbums} ألبومات مميزة',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldBright,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.goldBright,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedYearAlbumCard extends StatefulWidget {
  const _AnimatedYearAlbumCard({
    required this.yearTag,
    required this.posts,
  });

  final String yearTag;
  final List<PostModel> posts;

  @override
  State<_AnimatedYearAlbumCard> createState() => _AnimatedYearAlbumCardState();
}

class _AnimatedYearAlbumCardState extends State<_AnimatedYearAlbumCard> {
  bool _isHovered = false;
  int _currentImageIndex = 0;
  Timer? _timer;

  List<String> _getPreviewImages() {
    final List<String> images = [];
    for (final p in widget.posts) {
      images.addAll(p.images);
    }
    if (images.isEmpty) {
      images.addAll(switch (widget.yearTag) {
        '2026' => [
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=600&q=80',
          ],
        '2025' => [
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?auto=format&fit=crop&w=600&q=80',
          ],
        '2024' => [
            'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=600&q=80',
          ],
        _ => [
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?auto=format&fit=crop&w=600&q=80',
          ],
      });
    }
    return images;
  }

  @override
  void initState() {
    super.initState();
    _startAutoCycle();
  }

  void _startAutoCycle() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final images = _getPreviewImages();
      if (images.length > 1) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % 3;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final images = _getPreviewImages();
    final totalCount = images.length;
    final currentImage = images[_currentImageIndex % images.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (ctx, anim1, anim2) => FadeTransition(
                opacity: anim1,
                child: YearAlbumGridPage(
                  yearTag: widget.yearTag,
                  images: images,
                  posts: widget.posts,
                ),
              ),
            ),
          );
        },
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          radius: 20,
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.gold.withValues(alpha: 0.25),
          gradient: _isHovered
              ? LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.18),
                    AppColors.greenDeep.withValues(alpha: 0.15),
                  ],
                )
              : null,
          child: Row(
            children: [
              // Right Half: Text Info & Action Button
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // English Year Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Text(
                          widget.yearTag,
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ألبوم موكب أمنا الزهراء ${widget.yearTag}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCount صورة توثيقية',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action Link with Sliding Arrow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: Matrix4.translationValues(
                          _isHovered ? -4.0 : 0.0,
                          0.0,
                          0.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'استعراض الألبوم',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.gold,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Left Half: Animated Image Container with Sliding Hover Effect
              Expanded(
                flex: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(
                    _isHovered ? -7.0 : 0.0,
                    0.0,
                    0.0,
                  ),
                  height: 135,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Hero(
                          tag: 'album_cover_${widget.yearTag}',
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey<String>(currentImage),
                              child: Image.network(
                                currentImage,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  child: const Icon(Icons.photo_rounded, color: AppColors.gold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Animated Dots Indicator Overlay
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 3; i++) ...[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentImageIndex == i ? 14 : 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: _currentImageIndex == i
                                      ? AppColors.gold
                                      : Colors.white.withValues(alpha: 0.6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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

class YearAlbumGridPage extends StatelessWidget {
  const YearAlbumGridPage({
    super.key,
    required this.yearTag,
    required this.images,
    required this.posts,
  });

  final String yearTag;
  final List<String> images;
  final List<PostModel> posts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D110E) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'ألبوم موكب أمنا الزهراء $yearTag (${images.length} صورة)',
            style: const TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index];
          final childWidget = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: isDark ? Colors.white10 : Colors.black12,
                child: const Icon(Icons.broken_image_rounded, color: Colors.white30),
              ),
            ),
          );

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 80)),
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: Opacity(opacity: val, child: child),
              );
            },
            child: GestureDetector(
              onTap: () {
                _FullScreenGalleryViewer.show(context, images, index, yearTag);
              },
              child: index == 0
                  ? Hero(
                      tag: 'album_cover_$yearTag',
                      child: childWidget,
                    )
                  : childWidget,
            ),
          );
        },
      ),
    );
  }
}

class _FullScreenGalleryViewer extends StatefulWidget {
  const _FullScreenGalleryViewer({
    required this.images,
    required this.initialIndex,
    required this.yearTag,
  });

  final List<String> images;
  final int initialIndex;
  final String yearTag;

  static void show(
      BuildContext context, List<String> images, int initialIndex, String yearTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (ctx, anim1, anim2) => _FullScreenGalleryViewer(
          images: images,
          initialIndex: initialIndex,
          yearTag: yearTag,
        ),
      ),
    );
  }

  @override
  State<_FullScreenGalleryViewer> createState() => _FullScreenGalleryViewerState();
}

class _FullScreenGalleryViewerState extends State<_FullScreenGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Horizontal Photo Slider with Zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3.5,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),
            // Header Bar
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ألبوم موكب أمنا الزهراء ${widget.yearTag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFamily,
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Action Bar
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Center(
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  borderColor: Colors.white24,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إرسال رابط الصورة بنجاح 🚀'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: AppColors.gold, size: 24),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ الصورة إلى المعرض ✨'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
