import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/app_update_service.dart';
import 'core/theme/app_theme.dart';

/// جذر التطبيق.
///
/// اللغة العربية هي اللغة الوحيدة، والاتجاه من اليمين لليسار يُطبَّق تلقائياً
/// من إعداد اللغة فلا حاجة لتغليف الشجرة بـ Directionality يدوياً.
///
/// التحديث الإجباري: عند فتح التطبيق يُقارَن الإصدار الحالي مع ملف
/// update_config.json المستضاف — لو وُجد إصدار أحدث ظهر حوار إجباري
/// في وسط الشاشة يمنع أي استخدام حتى ينزّل العميل النسخة الجديدة.
class MawkibApp extends ConsumerStatefulWidget {
  const MawkibApp({super.key});

  @override
  ConsumerState<MawkibApp> createState() => _MawkibAppState();
}

class _MawkibAppState extends ConsumerState<MawkibApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. تحديث فوري لكافة البيانات من السيرفر بمجرد الدخول
      refreshAllAppData(ref);

      // 2. التحقق من التحديثات
      await AppUpdateService.checkForUpdates();
      if (AppUpdateService.hasUpdate && mounted) {
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          await AppUpdateService.showUpdateDialog(navContext);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // تحديث البيانات تلقائياً بمجرد العودة للتطبيق
      refreshAllAppData(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // تثبيت مقياس الخط: يمنع تكسّر التخطيط (overflow) إذا كبّر المستخدم
        // خط النظام كثيراً، مع السماح بتكبير معقول لإمكانية الوصول.
        final scale = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
