import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/profile_model.dart';

import '../../reports/data/login_audit_service.dart';

/// شاشة طلبات الحسابات الباقية بانتظار موافقة المدير.
///
/// تعرض الطلبات بكروت متدرجة ناعمة (أبيض بزمردي خفيف) تحتوي على الاسم فقط،
/// وعند النقر على أي كارت تفتح نافذة تفاصيل ضبابية وسط الشاشة تحتوي على:
/// - الاسم الثلاثي
/// - البريد الإلكتروني المسجّل به
/// - رقم الهاتف
/// - تاريخ الطلب
/// - زري القبول والرفض
class AccountRequestsPage extends ConsumerStatefulWidget {
  const AccountRequestsPage({super.key});

  @override
  ConsumerState<AccountRequestsPage> createState() => _AccountRequestsPageState();
}

class _AccountRequestsPageState extends ConsumerState<AccountRequestsPage> {
  late Future<List<ProfileModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _future = repo.fetchPendingProfiles();
    });
  }

  String _findFallbackEmail(ProfileModel profile) {
    if (profile.email?.isNotEmpty == true) return profile.email!;
    try {
      final auditRecords = ref.read(loginAuditProvider);
      for (final rec in auditRecords) {
        if (rec.accountName.trim() == profile.fullName.trim() &&
            rec.emailOrPhone.contains('@')) {
          return rec.emailOrPhone;
        }
      }
    } catch (_) {}
    return 'غير مسجل';
  }

  String _findFallbackPhone(ProfileModel profile) {
    if (profile.phone?.isNotEmpty == true) return profile.phone!;
    try {
      final auditRecords = ref.read(loginAuditProvider);
      for (final rec in auditRecords) {
        if (rec.accountName.trim() == profile.fullName.trim() &&
            !rec.emailOrPhone.contains('@') &&
            rec.emailOrPhone.isNotEmpty) {
          return rec.emailOrPhone;
        }
      }
    } catch (_) {}
    return 'غير مسجل';
  }

  Future<void> _updateStatus(
    ProfileModel profile,
    UserStatus status, {
    BuildContext? dialogContext,
  }) async {
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfileStatus(profile.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == UserStatus.approved
              ? 'تمت الموافقة على حساب «${profile.fullName}» بنجاح'
              : 'تم رفض طلب حساب «${profile.fullName}»'),
          backgroundColor:
              status == UserStatus.approved ? AppColors.paid : AppColors.overdue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(arabicError(e)),
          backgroundColor: AppColors.overdue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// فتح نافذة التفاصيل وسط الشاشة بخلفية ضبابية
  void _showRequestDetails(ProfileModel profile) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'تفاصيل طلب الحساب',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogCtx, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F261B) : Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? AppColors.gold.withValues(alpha: 0.35)
                          : const Color(0xFFCBE2D4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // رأس النافذة
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF163E2D)
                              : const Color(0xFFEAF5EE),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFD7EADB),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_pin_rounded,
                                color: AppColors.goldBright,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تفاصيل طلب الانضمام',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'مراجعة بيانات المستخدم للقبول أو الرفض',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              style: IconButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor:
                                    isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // بنود التفاصيل
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.person_rounded,
                              label: 'الاسم الثلاثي',
                              value: profile.fullName,
                              isDark: isDark,
                              isPrimary: true,
                            ),
                            const SizedBox(height: 14),
                            _buildDetailRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'البريد الإلكتروني',
                              value: _findFallbackEmail(profile),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            _buildDetailRow(
                              icon: Icons.phone_iphone_rounded,
                              label: 'رقم الهاتف',
                              value: _findFallbackPhone(profile),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            _buildDetailRow(
                              icon: Icons.calendar_month_rounded,
                              label: 'تاريخ الطلب',
                              value: profile.createdAt != null
                                  ? Fmt.dateTime(profile.createdAt)
                                  : 'اليوم',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 26),

                            // أزرار اتخاذ القرار (قبول / رفض)
                            Row(
                              children: [
                                // زر الرفض
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _updateStatus(
                                      profile,
                                      UserStatus.rejected,
                                      dialogContext: dialogCtx,
                                    ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                      color: AppColors.overdue,
                                    ),
                                    label: const Text(
                                      'رفض الطلب',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.overdue,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                      side: BorderSide(
                                        color: AppColors.overdue
                                            .withValues(alpha: 0.6),
                                        width: 1.3,
                                      ),
                                      backgroundColor: AppColors.overdue
                                          .withValues(alpha: 0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // زر القبول
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _updateStatus(
                                      profile,
                                      UserStatus.approved,
                                      dialogContext: dialogCtx,
                                    ),
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'قبول الحساب',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                      backgroundColor: AppColors.paid,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ويدجت صف تفاصيل الطلب داخل النافذة
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF6FAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2EFE7),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE0EFE6)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? AppColors.goldBright
                  : (isDark ? AppColors.goldBright : AppColors.greenRich),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: isPrimary ? 15 : 13.5,
                    fontWeight:
                        isPrimary ? FontWeight.bold : FontWeight.w600,
                    color: isPrimary && isDark
                        ? AppColors.goldBright
                        : (isDark ? Colors.white : const Color(0xFF132F20)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('طلبات الحسابات'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<ProfileModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 44, color: AppColors.overdue),
                      const SizedBox(height: 12),
                      Text(arabicError(snapshot.error!)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.how_to_reg_outlined,
                        size: 48,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات تسجيل معلّقة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جميع الحسابات المسجّلة تمت مراجعتها وموافقة الإدارة عليها.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];

                // كارت جميل ذات حواف ناعمة متدرج أبيض بزمردي خفيف يعرض الاسم فقط
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showRequestDetails(item),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF143826)
                                      .withValues(alpha: 0.85),
                                  const Color(0xFF0C2418)
                                      .withValues(alpha: 0.95),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFEBF6F0),
                                ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : const Color(0xFFD0E8DC),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : const Color(0xFF0F3824)
                                    .withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // أيقونة الحساب الرمزية
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppColors.gold.withValues(alpha: 0.18),
                            child: Text(
                              item.fullName.isNotEmpty
                                  ? item.fullName.substring(0, 1)
                                  : 'م',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: AppColors.goldBright,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // الاسم فقط في الكارت
                          Expanded(
                            child: Text(
                              item.fullName,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF113222),
                              ),
                            ),
                          ),

                          // أيقونة فتح تفاصيل الطلب
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFE2F0E7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
