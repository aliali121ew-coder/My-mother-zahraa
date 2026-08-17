import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// نافذة زجاجية أنيقة تعرض سياسة الخصوصية وحماية البيانات لموكب أمنا الزهراء
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: const PrivacyPolicyDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 520.0 : (screenWidth * 0.92);

    final bgColor = isDark ? const Color(0xFF151C17) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2822);
    final mutedColor = isDark ? AppColors.textOnDarkMuted : const Color(0xFF5B6E62);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: isDark ? 0.5 : 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الترويسة الذهبية الفاخرة
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
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'سياسة الخصوصية وحماية البيانات',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // نصوص وبنود سياسة الخصوصية مع التمرير
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك في تطبيق «موكب أمنا الزهراء (عليها السلام)». نحن نولي خصوصيتك وحماية بيانات المساهمين والخدمة الحسينية أعلى درجات الأهمية والأمان.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          height: 1.6,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        icon: Icons.shield_outlined,
                        title: '1. التشفير والحماية المحلية (AES-256)',
                        content:
                            'تُخزن بيانات المساهمين والحركات المالية محلياً داخل خوادم مشفرة بنظام AES-256 ومحمية بمفاتيح أمان الأجهزة (Android Keystore / iOS Keychain)، ويتم مسح السجلات الحساسة تلقائياً عند تسجيل الخروج.',
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 14),

                      _buildSection(
                        icon: Icons.lock_person_outlined,
                        title: '2. سياسات الوصول ومستويات الأمان (RLS)',
                        content:
                            'تعتمد قاعدة البيانات السحابية سياسات صارمة لمنع الوصول غير المصرح؛ حيث تُحجب أسماء المشتركين والبيانات المالية عن الحسابات العامة، وتتاح حصراً للإدارة والمسؤول المالي المعتمد.',
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 14),

                      _buildSection(
                        icon: Icons.https_outlined,
                        title: '3. أمان الاتصال والشبكة (SSL / HTTPS)',
                        content:
                            'كافة عمليات نقل البيانات بين التطبيق وقاعدة البيانات السحابية مشفرة ببروتوكولات TLS 1.3 المعتمدة، مع حظر كامل لحركة البيانات غير المشفرة (Cleartext Traffic).',
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 14),

                      _buildSection(
                        icon: Icons.handshake_outlined,
                        title: '4. عدم مشاركة البيانات مع أطراف ثالثة',
                        content:
                            'جميع البيانات والمعلومات المسجلة مخصصة حصراً لإدارة شؤون الموكب وخدمة الزائرين، ولا يتم بيعها أو مشاركتها أو استخدامها لأي أغراض إعلانية أو تجارية.',
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                    ],
                  ),
                ),
              ),

              // زر الإغلاق والموافقة
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'فهمت وموافق',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              height: 1.5,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
