@Tags(['preview'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mawkib_zahra/core/theme/app_theme.dart';
import 'package:mawkib_zahra/core/widgets/glass.dart';
import 'package:mawkib_zahra/features/home/data/demo_data.dart';
import 'package:mawkib_zahra/shared/widgets/contributor_tile.dart';
import 'package:mawkib_zahra/shared/widgets/mawkib_logo.dart';
import 'package:mawkib_zahra/shared/widgets/stat_cards.dart';

/// معاينة التصميم: ترسم مكوّنات الواجهة إلى صورة PNG داخل الاختبارات.
///
/// **لماذا:** تطوير الواجهة بلا رؤيتها تخمين. هذا الاختبار يرسم الشاشة
/// فعلياً بالخطوط الحقيقية فيمكن فحص النتيجة بصرياً قبل بناء التطبيق،
/// ويكشف مشاكل التخطيط والـoverflow مبكراً.
///
/// التشغيل:  flutter test test/design_preview_test.dart --update-goldens
/// الناتج :  test/goldens/home_dark.png و home_light.png
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await _loadFont('Cairo', const ['assets/fonts/Cairo-Variable.ttf']);
    await _loadFont('IBMPlexSansArabic', const [
      'assets/fonts/IBMPlexSansArabic-Regular.ttf',
      'assets/fonts/IBMPlexSansArabic-Medium.ttf',
      'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
      'assets/fonts/IBMPlexSansArabic-Bold.ttf',
    ]);
    await _loadFont('Amiri', const [
      'assets/fonts/Amiri-Regular.ttf',
      'assets/fonts/Amiri-Bold.ttf',
    ]);
    // خط أيقونات Material من داخل Flutter SDK — بدونه تظهر الأيقونات
    // مربّعات فارغة في المعاينة فيتعذّر الحكم على التصميم
    final iconFont = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '/agent/sdk/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (iconFont.existsSync()) {
      await _loadFont('MaterialIcons', [iconFont.path]);
    }
  });

  for (final mode in [Brightness.dark, Brightness.light]) {
    final name = mode == Brightness.dark ? 'dark' : 'light';

    testWidgets('معاينة الرئيسية — $name', (tester) async {
      tester.view
        ..physicalSize = const Size(1170, 2320)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: mode == Brightness.dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _HomePreview(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(_HomePreview),
        matchesGoldenFile('goldens/home_$name.png'),
      );
    });
  }
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(
      File(p).readAsBytes().then((b) => ByteData.view(b.buffer)),
    );
  }
  await loader.load();
}

/// نسخة مطابقة لتخطيط الرئيسية، مبنية على البيانات التجريبية بلا مزوّدات.
class _HomePreview extends StatelessWidget {
  const _HomePreview();

  @override
  Widget build(BuildContext context) {
    final stats = DemoData.stats;
    final donors = [...DemoData.donors]
      ..sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // شريط علوي
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    const MawkibLogo(
                      height: 34,
                      small: true,
                      radius: 10,
                      padding: EdgeInsets.all(3),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'موكب أمنا الزهراء',
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                    Icon(Icons.light_mode_outlined,
                        color: theme.textTheme.bodyMedium?.color),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TotalAmountCard(total: stats.totalAmount, onTap: () {}),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: CountCard(
                          label: 'عدد المتبرعين',
                          icon: Icons.volunteer_activism_outlined,
                          count: stats.donorsCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CountCard(
                          label: 'عدد المشتركين',
                          icon: Icons.groups_2_outlined,
                          count: stats.subscribersCount,
                          badge: '${stats.overdueCount} متأخر',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                child: SectionHeader(
                  title: 'أعلى المتبرعين',
                  icon: Icons.emoji_events_outlined,
                  action: TextButton(
                    onPressed: () {},
                    child: const Text('عرض الكل'),
                  ),
                ),
              ),
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: ContributorTile(
                    contributor: donors[i],
                    rank: i + 1,
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
