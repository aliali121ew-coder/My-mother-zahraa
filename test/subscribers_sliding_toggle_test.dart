import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mawkib_zahra/shared/models/enums.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('اختبار التبويب المنزلق في قائمة المشتركين', (tester) async {

    SubscriptionType current = SubscriptionType.monthly;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  const TextField(),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => current = SubscriptionType.monthly),
                        child: const Text('شهري'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => current = SubscriptionType.yearly),
                        child: const Text('سنوي'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // التحقق من وجود شريط البحث وتبويبي شهري وسنوي
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('شهري'), findsWidgets);
    expect(find.text('سنوي'), findsWidgets);

    // اختيار تبويب سنوي للتحقق من التفاعل
    final yearlyFinder = find.text('سنوي').first;
    await tester.tap(yearlyFinder);
    await tester.pumpAndSettle();
    expect(current, SubscriptionType.yearly);
  });
}
