import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';

/// صفحة تعديل وضبط الملف الشخصي (الاسم، رقم الهاتف، وصورة الحساب)
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  static void navigate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EditProfilePage(),
      ),
    );
  }

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String? _avatarPath; // مسار محلي أو Data URL أو URL قديم
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(sessionProvider).profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _avatarPath = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;

      // تحويل الصورة إلى Data URL لضمان الحفظ في قاعدة البيانات والعمل دون انترنت
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = picked.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mimeType;base64,$base64String';

      setState(() {
        _avatarPath = dataUri;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اختيار الصورة: $e'),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateMyProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        avatarUrl: _avatarPath,
      );

      // تحديث الجلسة فوراً
      await ref.read(sessionProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.greenDeep,
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.goldBright, size: 20),
                SizedBox(width: 8),
                Text(
                  'تم حفظ بيانات الملف الشخصي بنجاح',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1410) : const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF151C16) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── صورة الحساب مع زر التغيير ──
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gold,
                            AppColors.greenDeep,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131714) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(isDark),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F1410) : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'انقر على الكاميرا لتغيير الصورة الشخصية',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                ),
              ),

              const SizedBox(height: 28),

              // ── بطاقة البيانات الشخصية ──
              GlassCard(
                blur: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'البيانات الشخصية',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // الاسم الكامل
                    Text(
                      'الاسم الكامل *',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أدخل الاسم الكامل',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.gold, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E2620) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                    ),

                    const SizedBox(height: 16),

                    // رقم الهاتف
                    Text(
                      'رقم الهاتف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: '07XXXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.gold, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E2620) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // الدور والحالة (للقراءة فقط)
                    if (session.profile != null) ...[
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الدور الحالي:',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              session.role.label,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── زر الحفظ الفخم ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.goldBright],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'حفظ التعديلات',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
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
      ),
    );
  }

  Widget _buildAvatarImage(bool isDark) {
    final url = _avatarPath;
    if (url == null || url.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF222823) : Colors.grey.shade200,
        child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 54),
      );
    }

    // 1. ملف محلي
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:image')) {
      try {
        final file = File(url);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover, width: 105, height: 105);
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
          return Image.memory(bytes, fit: BoxFit.cover, width: 105, height: 105);
        }
      } catch (_) {}
    }

    // 3. Network
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: 105,
      height: 105,
      errorBuilder: (_, _, _) => Container(
        color: isDark ? const Color(0xFF222823) : Colors.grey.shade200,
        child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 54),
      ),
    );
  }
}
