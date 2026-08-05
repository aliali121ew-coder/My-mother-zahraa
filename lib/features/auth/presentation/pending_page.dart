import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/widgets/mawkib_logo.dart';

/// شاشة «حسابك بانتظار موافقة المدير».
///
/// تُعرض بعد التسجيل الناجح. المستخدم يستطيع تصفّح المنشورات في أثناء
/// الانتظار، وزر «تحقّق الآن» يعيد قراءة حالة الحساب فينتقل تلقائياً إلى
/// الرئيسية لحظة موافقة المدير بلا حاجة لإعادة تسجيل الدخول.
class PendingPage extends ConsumerStatefulWidget {
  const PendingPage({super.key});

  @override
  ConsumerState<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends ConsumerState<PendingPage> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    await ref.read(sessionProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _checking = false);

    final s = ref.read(sessionProvider);
    if (s.isApproved) {
      context.go('/home');
    } else if (s.isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حسابك محظور — راجع إدارة الموكب'),
          backgroundColor: AppColors.overdue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم تصل الموافقة بعد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                blur: true,
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MawkibLogo(height: 92, radius: 20),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.pending.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.pending,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'حسابك بانتظار موافقة المدير',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تم إنشاء حسابك بنجاح'
                      '${session.profile != null ? ' باسم ${session.profile!.fullName}' : ''}.'
                      ' سيظهر لك المبلغ الكلي وأعداد المشتركين والمتبرعين '
                      'مباشرة بعد موافقة المدير.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: _checking ? null : _check,
                      icon: _checking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 19),
                      label: Text(_checking ? 'جارٍ التحقّق…' : 'تحقّق الآن'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/posts'),
                      icon: const Icon(Icons.dynamic_feed_outlined, size: 19),
                      label: const Text('تصفّح المنشورات في أثناء الانتظار'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () async {
                        await ref.read(sessionProvider.notifier).signOut();
                        if (context.mounted) context.go('/home');
                      },
                      child: const Text('تسجيل الخروج'),
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
