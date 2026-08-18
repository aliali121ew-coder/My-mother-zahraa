import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────
/// التحديث الإجباري داخل التطبيق (الطريقة رقم 1 من دليل التحديث).
///
/// آلية العمل:
/// 1. نقرأ ملف `update_config.json` المستضاف على GitHub (branch main).
/// 2. نقارن رقم الإصدار المنشور مع رقم الإصدار الحالي داخل التطبيق.
/// 3. إذا وُجد إصدار أحدث (مع force=true) نعتّم الشاشة كاملة ونعرض حوارًا
///    يمنع أي استخدام، وننزّل ملف الـ APK الجديد مع شريط تقدم من 0٪ إلى 100٪
///    ثم نفتح المثبّت مباشرة.
/// ─────────────────────────────────────────────────────────────────

/// رقم الإصدار الحالي داخل التطبيق — يُرفَع مع كل نسخة جديدة.
/// يجب أن يطابق (أو يزيد) قيمة `version` في update_config.json.
const int currentAppVersion = AppConfig.appBuildNumber;

/// الإصدار المنشور في ملف `update_config.json` على GitHub.
/// 0 يعني عدم توفر الملف أو فشل القراءة (لا تحديث).
int latestPublishedVersion = 0;

class AppUpdateService {
  /// رابط ملف إعدادات التحديث على GitHub.
  static const String configUrl =
      'https://raw.githubusercontent.com/aliali121ew-coder/My-mother-zahraa/main/update_config.json';

  /// جلب إعدادات التحديث من الملف المستضاف.
  static Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final cacheBusterUrl = '$configUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      final req = await client.getUrl(Uri.parse(cacheBusterUrl));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// هل يوجد تحديث متاح؟ (المقارنة تتم على رقم الإصدار)
  static bool get hasUpdate => latestPublishedVersion > currentAppVersion;

  /// الفحص الأول عند فتح التطبيق — يُستدعى من MawkibApp.
  static Future<void> checkForUpdates() async {
    final config = await fetchConfig();
    if (config == null) return;
    final version = config['version'];
    if (version is int) {
      latestPublishedVersion = version;
    }
  }

  static bool _isDialogOpen = false;

  /// فتح حوار التحديث الإجباري مع شريط التقدم — يعتّم الشاشة كاملة ويبقى ثابتاً في المنتصف.
  static Future<void> showUpdateDialog([BuildContext? context]) async {
    if (_isDialogOpen) return;
    final targetContext = (context != null && context.mounted)
        ? context
        : rootNavigatorKey.currentContext;
    if (targetContext == null || !targetContext.mounted) return;

    final config = await fetchConfig() ?? {};
    final apkUrl =
        (config['apk_url'] as String?) ??
        'https://raw.githubusercontent.com/aliali121ew-coder/My-mother-zahraa/main/releases/mawkib_zahraa_release.apk';
    final message =
        (config['message'] as String?) ??
        'تحديث جديد متاح لتحسين أداء التطبيق وأمانه — يرجى التحديث للمتابعة';

    if (!targetContext.mounted) return;
    _isDialogOpen = true;
    try {
      await showDialog(
        // حوار إجباري: لا يمكن إغلاقه بالنقر خارجه ولا بزر الرجوع
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        useRootNavigator: true,
        context: targetContext,
        builder: (ctx) => PopScope(
          canPop: false,
          child: _UpdateDialogShell(
            apkUrl: apkUrl,
            message: message,
            isForce: true,
          ),
        ),
      );
    } finally {
      _isDialogOpen = false;
    }
  }
}

/// غلاف الحوار — يُبنى فوق الشاشة كاملة.
class _UpdateDialogShell extends StatefulWidget {
  const _UpdateDialogShell({
    required this.apkUrl,
    required this.message,
    required this.isForce,
  });

  final String apkUrl;
  final String message;
  final bool isForce;

  @override
  State<_UpdateDialogShell> createState() => _UpdateDialogShellState();
}

class _UpdateDialogShellState extends State<_UpdateDialogShell> {
  double _progress = 0;
  String _statusText = 'جارٍ التحقق من التحديث...';
  bool _downloading = false;
  bool _downloaded = false;
  String? _error;

  /// بدء التنزيل مع إظهار شريط التقدم.
  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _statusText = 'جارٍ تنزيل النسخة الجديدة... لا تغلق التطبيق';
      _error = null;
    });

    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(widget.apkUrl));
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('فشل جلب الملف');

      final total = res.contentLength;
      final bytes = <int>[];
      await for (final chunk in res) {
        bytes.addAll(chunk);
        if (total > 0 && mounted) {
          setState(() => _progress = bytes.length / total);
        }
      }

      if (!mounted) return;
      setState(() {
        _progress = 1;
        _downloading = false;
        _downloaded = true;
        _statusText = 'اكتمل التنزيل بنجاح — جارٍ فتح المثبّت...';
      });

      // حفظ الملف محلياً وتثبيته فوراً
      await _installApk(bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _statusText = 'تعذر التنزيل التلقائي — يمكنك الفتح عبر المتصفح';
        _error = 'حدث خطأ أثناء التنزيل. يرجى الضغط على زر التحميل المباشر أدناه.';
      });
    }
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.apkUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _installApk([List<int>? newBytes]) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mawkib-zahraa-update.apk');
      if (newBytes != null && newBytes.isNotEmpty) {
        await file.writeAsBytes(newBytes, flush: true);
      }
      if (await file.exists()) {
        final res = await OpenFilex.open(
          file.path,
          type: 'application/vnd.android.package-archive',
        );
        if (res.type != ResultType.done) {
          if (mounted) {
            setState(() {
              _statusText = 'يرجى تأكيد التثبيت أو الفتح عبر المتصفح';
              _error = 'إذا لم تظهر شاشة التثبيت تلقائياً، اضغط على زر التحميل عبر المتصفح أدناه.';
            });
          }
          await _openInBrowser();
        } else {
          if (mounted) {
            setState(() {
              _statusText = 'تم فتح مثبت التطبيقات — يرجى تأكيد التثبيت';
            });
          }
        }
      } else {
        await _openInBrowser();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusText = 'تعذر فتح المثبت مباشرة';
          _error = 'يرجى الضغط على زر التحميل المباشر عبر المتصفح لتثبيت التحديث.';
        });
      }
      await _openInBrowser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: const Color(0xFF06120A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شعار رمزي
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.6),
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.gold,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'يوجد تحديث جديد',
              style: TextStyle(
                color: AppColors.goldBright,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textOnDarkMuted
                    : AppColors.textOnLightMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // شريط التقدم 0٪ → 100٪
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _downloading ? _progress : (_downloaded ? 1 : 0),
                  minHeight: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // النسبة المئوية
            Text(
              '${(_progress * 100).toInt()}٪',
              style: const TextStyle(
                color: AppColors.goldBright,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_downloading)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  ),
                if (_downloading) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDarkMuted
                          : AppColors.textOnLightMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // رسالة خطأ إن وجدت
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.overdue.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.overdue.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.overdue,
                    fontSize: 12.5,
                  ),
                ),
              ),
            if (_error != null) const SizedBox(height: 14),

            // زر التثبيت الأساسي
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _downloading
                    ? null
                    : (_downloaded ? () => _installApk() : _startDownload),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _downloaded
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_done_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'تثبيت التحديث الآن 🚀',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _downloading ? 'جارٍ التنزيل...' : 'تحديث الآن',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (_downloaded || _error != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: AppColors.gold),
                  label: const Text(
                    'تحميل مباشر عبر المتصفح 🌐',
                    style: TextStyle(
                      color: AppColors.goldBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
