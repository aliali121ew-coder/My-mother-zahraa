import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/widgets/mawkib_logo.dart';

/// واجهة الترحيب مع شعار الموكب.
///
/// الشعار يظهر بتلاشٍ وتكبير خفيف، ثم ينتقل التطبيق للرئيسية.
/// مدة العرض قصيرة (١٨٠٠ مللي) لأن شاشة ترحيب أطول تُشعر المستخدم بالبطء.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future<void>.delayed(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      await AppUpdateService.checkForUpdates();
      if (AppUpdateService.hasUpdate && mounted) {
        // إذا وجد تحديث، نثبّت نافذة التحديث وسط الشاشة ولا ننتقل للرئيسية أبداً
        await AppUpdateService.showUpdateDialog(context);
        return;
      }
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // الشعار الرسمي للموكب بخلفيته البيضاء، داخل لوحة
                  MawkibLogo(
                    width: MediaQuery.sizeOf(context).width * 0.52,
                    radius: 28,
                    padding: const EdgeInsets.all(16),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'موكب أمنا الزهراء',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldBright,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عليها السلام',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      color: AppColors.textOnDark.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.gold.withValues(alpha: 0.75),
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
