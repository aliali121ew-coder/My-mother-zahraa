import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../models/contributor_model.dart';

/// عارض الصورة التفاعلي عالي الجودة لجميع الأعضاء والمشرفين
class AppPhotoViewerDialog extends StatelessWidget {
  const AppPhotoViewerDialog({
    super.key,
    required this.contributor,
  });

  final ContributorModel contributor;

  /// فتح نافذة عرض الصورة لجميع الأعضاء
  static Future<void> show(
    BuildContext context, {
    required ContributorModel contributor,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (ctx) => AppPhotoViewerDialog(contributor: contributor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = contributor.photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;

    Widget imageWidget;
    if (!hasPhoto) {
      imageWidget = Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.greenDeep.withValues(alpha: 0.6),
            border: Border.all(color: AppColors.goldBright, width: 2),
          ),
          child: Center(
            child: Text(
              contributor.fullName.isNotEmpty
                  ? contributor.fullName.characters.first
                  : 'م',
              style: const TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppColors.goldBright,
              ),
            ),
          ),
        ),
      );
    } else if (url.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(
          child: CircularProgressIndicator(color: AppColors.goldBright),
        ),
        errorWidget: (_, _, _) => _errorPlaceholder(),
      );
    } else if (url.startsWith('data:image') || url.startsWith('data:')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _errorPlaceholder(),
        );
      } catch (_) {
        imageWidget = _errorPlaceholder();
      }
    } else {
      final file = File(url);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _errorPlaceholder(),
        );
      } else {
        imageWidget = _errorPlaceholder();
      }
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.88),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. عارض الصورة مع التكبير التفاعلي
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
                  child: Hero(
                    tag: 'contributor_avatar_${contributor.id}',
                    child: imageWidget,
                  ),
                ),
              ),
            ),

            // 2. الشريط العلوي مع اسم المساهم وزر الإغلاق
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'إغلاق',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            contributor.fullName,
                            style: const TextStyle(
                              fontFamily: AppTheme.displayFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldBright,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.greenDeep
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  contributor.type.label,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (contributor.phone != null &&
                                  contributor.phone!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  contributor.phone!,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. تلميح في الأسفل
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white24,
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch_rounded, size: 16, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'يمكنك التكبير والسحب بإصبعين لمعاينة أدق التفاصيل',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5,
                          color: Colors.white70,
                        ),
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

  Widget _errorPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'تعذّر عرض الصورة',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
