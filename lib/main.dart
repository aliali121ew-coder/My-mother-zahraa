import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // بيانات التواريخ العربية لحزمة intl
  initializeDateFormatting('ar');

  // شريط النظام شفاف ليمتد التصميم لحدود الشاشة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // التخزين المحلي المشفّر — يجب أن يجهز قبل قراءة الإعدادات
  await HiveService.instance.init();

  // Supabase يُهيَّأ فقط إذا مُرِّرت المفاتيح وقت البناء.
  // بلا مفاتيح يعمل التطبيق ببيانات تجريبية كاملة، فيمكن تجربة كل الواجهات
  // قبل إعداد قاعدة البيانات.
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // publishableKey يقبل مفاتيح anon القديمة ومفاتيح sb_publishable الجديدة
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  // حارس المسارات (P2): الاشتراك في الجلسة يعيد تقييم التوجيه عند كل
  // تغيّر — الدخول والخروج وتغيّر الدور أو حالة الحظر.
  // نُنشئ الحاوية يدوياً قبل بناء الشجرة لأن ProviderScope.containerOf
  // يحتاج BuildContext الذي لا يتوفر قبل runApp في riverpod 2.6.x
  final container = ProviderContainer(
    overrides: const [],
  );
  runApp(UncontrolledProviderScope(
    container: container,
    child: const MawkibApp(),
  ));
  SessionListenable.instance.start(container);
}
