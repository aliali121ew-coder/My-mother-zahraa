import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/posts_repository.dart';

/// حوار تفاعلي لإضافة منشور جديد للموكب
class AddPostDialog extends ConsumerStatefulWidget {
  const AddPostDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AddPostDialog(),
    );
  }

  @override
  ConsumerState<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends ConsumerState<AddPostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final List<String> _images = [];
  String _selectedYearTag = '2026';

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addImage() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty) {
      if (_images.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الحد الأقصى هو 10 صور للمنشور الواحد 📸')),
        );
        return;
      }
      setState(() {
        _images.add(url);
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final caption = _captionController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? 'كربلاء المقدسة'
        : _locationController.text.trim();

    final finalImages = _images.isEmpty
        ? [
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1000&q=80',
          ]
        : _images;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(postsProvider.notifier).addPost(
            imageUrls: finalImages,
            caption: caption,
            location: location,
            yearTag: _selectedYearTag,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم نشر التغطية بنجاح 🖤✨',
                  style: TextStyle(fontFamily: AppTheme.fontFamily),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.greenDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر نشر التغطية — تحقق من الاتصال ثم أعد المحاولة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.greenDeepest : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.goldDark, AppColors.gold],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.post_add_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'إضافة منشور أو تغطية جديدة',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Caption
                        const Text(
                          'وصف المنشور / التغطية',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _captionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'اكتب تفاصيل التغطية أو نص المجلس هنا...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'الوصف مطلوب' : null,
                        ),
                        const SizedBox(height: 14),

                        // Location & Year
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الموقع (اختياري)',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: InputDecoration(
                                      hintText: 'كربلاء المقدسة',
                                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'سنة التوثيق',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedYearTag,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    items: ['2026', '2025', '2024', '2023']
                                        .map((y) => DropdownMenuItem(
                                              value: y,
                                              child: Text(y),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _selectedYearTag = v);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Image URL Input
                        const Text(
                          'رابط صورة المنشور (أو صور متعددة)',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  hintText: 'ضع رابط الصورة هنا (http...)',
                                  prefixIcon: const Icon(Icons.link_rounded, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _addImage,
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                              label: const Text('إضافة صورة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.greenAbyss,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_images.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: _images
                                .map((img) => Chip(
                                      avatar: const Icon(Icons.image, size: 16),
                                      label: Text('صورة ${_images.indexOf(img) + 1}'),
                                      onDeleted: () {
                                        setState(() => _images.remove(img));
                                      },
                                    ))
                                .toList(),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.publish_rounded),
                            label: const Text(
                              'نشر التغطية الآن',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenDeep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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
    );
  }
}
