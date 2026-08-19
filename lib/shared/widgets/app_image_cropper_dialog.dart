import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// نافذة قص وضبط وتدوير الصورة لفئات المشتركين والمتبرعين والداعمين
class AppImageCropperDialog extends StatefulWidget {
  const AppImageCropperDialog({
    super.key,
    required this.imageFile,
    this.title = 'قص وضبط الصورة',
  });

  final XFile imageFile;
  final String title;

  /// دالة مساعدة سريعة لفتح نافذة القص وإرجاع الملف المقصوص
  static Future<XFile?> cropImage(
    BuildContext context,
    XFile imageFile, {
    String title = 'قص وضبط الصورة',
  }) async {
    final result = await showDialog<XFile?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppImageCropperDialog(
        imageFile: imageFile,
        title: title,
      ),
    );
    return result;
  }

  @override
  State<AppImageCropperDialog> createState() => _AppImageCropperDialogState();
}

class _AppImageCropperDialogState extends State<AppImageCropperDialog> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
  int _quarterTurns = 0;
  bool _isProcessing = false;
  bool _isCircleMask = true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _resetTransform() {
    setState(() {
      _quarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _onConfirm() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _cropKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(widget.imageFile);
        return;
      }

      final uiImage = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(widget.imageFile);
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File(targetPath);
      await croppedFile.writeAsBytes(bytes);

      if (mounted) {
        Navigator.of(context).pop(XFile(croppedFile.path));
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(widget.imageFile);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const cropBoxSize = 270.0;

    return PopScope(
      canPop: !_isProcessing,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14241E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.4 : 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. الشريط العلوي
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.greenAbyss.withValues(alpha: 0.8)
                      : AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.crop_rotate_rounded,
                      color: isDark ? AppColors.goldBright : AppColors.goldDark,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.goldBright
                              : AppColors.goldDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? Colors.white70 : Colors.black54,
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(null),
                      tooltip: 'إلغاء',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // تعليمات الاستخدام السريعة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'اسحب الصورة بإصبعك أو قرّبها وباعِدها للضبط داخل الإطار',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textOnDarkMuted
                        : AppColors.textOnLightMuted,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. منطقة القص التفاعلية
              Center(
                child: Container(
                  width: cropBoxSize,
                  height: cropBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(
                        _isCircleMask ? cropBoxSize / 2 : 16),
                    border: Border.all(
                      color: AppColors.goldBright,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        _isCircleMask ? cropBoxSize / 2 : 14),
                    child: RepaintBoundary(
                      key: _cropKey,
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 0.5,
                          maxScale: 4.0,
                          boundaryMargin: const EdgeInsets.all(120),
                          clipBehavior: Clip.hardEdge,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: _quarterTurns,
                              child: Image.file(
                                File(widget.imageFile.path),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. أزرار التحكم بالتدوير وشكل الإطار
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر التدوير 90 درجة
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? AppColors.goldBright : AppColors.goldDark,
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.rotate_right_rounded, size: 18),
                      label: const Text(
                        'تدوير 90°',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _isProcessing ? null : _rotateClockwise,
                    ),
                    const SizedBox(width: 8),

                    // زر تغيير شكل الإطار (دائري / مربع)
                    IconButton.outlined(
                      tooltip: _isCircleMask ? 'إطار مربع' : 'إطار دائري',
                      icon: Icon(
                        _isCircleMask
                            ? Icons.crop_square_rounded
                            : Icons.circle_outlined,
                        size: 20,
                        color:
                            isDark ? AppColors.goldBright : AppColors.goldDark,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => setState(() => _isCircleMask = !_isCircleMask),
                    ),
                    const SizedBox(width: 8),

                    // زر إعادة الضبط
                    IconButton.outlined(
                      tooltip: 'إعادة ضبط الموضع',
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textOnDarkMuted
                            : AppColors.textOnLightMuted,
                      ),
                      onPressed: _isProcessing ? null : _resetTransform,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. أزرار الحفظ والإلغاء
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(null),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldBright, AppColors.goldDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.greenAbyss,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.greenAbyss,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isProcessing ? 'جارِ القص...' : 'تأكيد وضبط الصورة',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isProcessing ? null : _onConfirm,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
