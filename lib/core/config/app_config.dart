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
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const appName = 'موكب أمنا الزهراء';
  static const currency = 'د.ع';

  /// أسماء صناديق Hive المحلية
  static const boxContributors = 'contributors';
  static const boxPayments = 'payments';
  static const boxDonations = 'donations';
  static const boxPosts = 'posts';
  static const boxStories = 'stories';
  static const boxStats = 'stats';
  static const boxOutbox = 'outbox';
  static const boxSettings = 'settings';
  static const boxAdminUsers = 'admin_users';
}
