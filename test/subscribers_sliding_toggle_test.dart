import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawkib_zahra/core/providers/app_providers.dart';
import 'package:mawkib_zahra/features/home/data/demo_data.dart';
import 'package:mawkib_zahra/features/contributors/presentation/contributors_list_page.dart';

void main() {
  testWidgets('اختبار التبويب المنزلق في قائمة المشتركين', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscribersProvider.overrideWith((ref) async => DemoData.subscribers),
        ],
        child: const MaterialApp(
          home: ContributorsListPage(showDonors: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // التحقق من وجود شريط البحث وتبويبي شهري وسنوي
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('شهري'), findsWidgets);
    expect(find.text('سنوي'), findsWidgets);

    // اختيار تبويب سنوي للتحقق من الانزلاق والتفاعل
    final yearlyFinder = find.text('سنوي').first;
    await tester.tap(yearlyFinder);
    await tester.pumpAndSettle();
  });
}
