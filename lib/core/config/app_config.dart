/// إعدادات التطبيق. مفاتيح Supabase تُمرَّر وقت البناء عبر --dart-define
/// ولا تُكتب في الكود المصدري:
///
///   flutter build apk --release \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// ملاحظة أمنية صريحة: مفتاح anon مُصمَّم ليكون علنياً — أي شخص يفكّ
/// التطبيق سيجده، وهذا طبيعي ولا يشكّل خطراً. الحماية الحقيقية هي سياسات
/// RLS على السيرفر التي تمنع أي وصول غير مصرّح به مهما كان المفتاح معروفاً.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nmpcbyoehmghmietzurs.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ev4vJ_FdXww-7Yp_ojV5CA_XDJcrTxW',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const appName = 'موكب أمنا الزهراء';
  static const currency = 'د.ع';

  /// معلومات الإصدار الموحّدة
  static const appVersion = '1.2.5';
  static const appBuildNumber = 15;
  static String get versionDisplay => 'الإصدار $appVersion (Build $appBuildNumber)';

  /// أسماء صناديق Hive المحلية
  static const boxContributors = 'contributors';
  static const boxPayments = 'payments';
  static const boxDonations = 'donations';
  static const boxPosts = 'posts';
  static const boxStories = 'stories';
  static const boxStats = 'stats';
  static const boxOutbox = 'outbox';
  static const boxSettings = 'settings';
  static const boxPurchases = 'purchases';
  static const boxAdminUsers = 'admin_users';

}
