import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mawkib_zahra/core/data/supabase_repository.dart';
import 'package:mawkib_zahra/core/providers/app_providers.dart';
import 'package:mawkib_zahra/features/contributors/presentation/subscriber_detail_page.dart';
import 'package:mawkib_zahra/shared/models/contributor_model.dart';
import 'package:mawkib_zahra/shared/models/enums.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('اختبار الشاشة التفصيلية للمشترك وجدول الـ 12 شهراً',
      (tester) async {
    final sub = ContributorModel(
      id: 'sub-test-1',
      type: ContributorType.subscriber,
      fullName: 'سيد عباس الغريفي',
      subscriptionAmount: 50000,
      subscriptionType: SubscriptionType.monthly,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscribersRawProvider.overrideWith(
            (ref) async => CachedResult(data: [sub], fromCache: false),
          ),
          subscribersProvider.overrideWith(
            (ref) async => [sub],
          ),
          allContributorsProvider.overrideWith(
            (ref) async => [sub],
          ),
        ],
        child: const MaterialApp(
          home: SubscriberDetailPage(contributorId: 'sub-test-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // التحقق من ترويسة العنوان والبيانات الأساسية للمشترك
    expect(find.text('ملف المشترك التفصيلي'), findsOneWidget);
    expect(find.text('سيد عباس الغريفي'), findsOneWidget);
    expect(find.text('فئة الاشتراك'), findsOneWidget);
    expect(find.text('إجمالي الدفعات'), findsOneWidget);

    // التحقق من ترويسة جدول المشتركين
    expect(find.text('جدول التسديدات الشهري (12 شهراً)'), findsOneWidget);
    expect(find.text('الشهر'), findsOneWidget);
    expect(find.text('مبلغ الاشتراك'), findsOneWidget);
    expect(find.text('الحالة'), findsOneWidget);
    expect(find.text('الأول'), findsOneWidget);
    expect(find.text('العاشر'), findsOneWidget);
    expect(find.text('الثاني\nعشر'), findsOneWidget);

    // التحقق من أزرار التعديل/الإضافة الـ 12 للأشهر (لم يسدد أي شهر بعد، فتظهر أيقونة الإضافة)
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsNWidgets(12));
  });

  testWidgets('اختبار الشاشة التفصيلية للمتبرع (عدم وجود عمود الحالة)',
      (tester) async {
    final donor = ContributorModel(
      id: 'donor-test-1',
      type: ContributorType.donor,
      fullName: 'أحمد المتبرع',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscribersRawProvider.overrideWith(
            (ref) async => CachedResult(data: [donor], fromCache: false),
          ),
          subscribersProvider.overrideWith(
            (ref) async => [donor],
          ),
          allContributorsProvider.overrideWith(
            (ref) async => [donor],
          ),
        ],
        child: const MaterialApp(
          home: SubscriberDetailPage(contributorId: 'donor-test-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ملف المتبرع التفصيلي'), findsOneWidget);
    expect(find.text('أحمد المتبرع'), findsOneWidget);

    // التحقق من ترويسة جدول المتبرع (يوجد مبلغ التبرع وتاريخ التبرع، ولا يوجد عمود الحالة)
    expect(find.text('مبلغ التبرع'), findsOneWidget);
    expect(find.text('تاريخ التبرع'), findsOneWidget);
    expect(find.text('الحالة'), findsNothing);
  });

  testWidgets('اختبار الشاشة التفصيلية للداعم (جدول المواد العينية)',
      (tester) async {
    final supporter = ContributorModel(
      id: 'supporter-test-1',
      type: ContributorType.inKind,
      fullName: 'محمد الداعم',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscribersRawProvider.overrideWith(
            (ref) async => CachedResult(data: [supporter], fromCache: false),
          ),
          subscribersProvider.overrideWith(
            (ref) async => [supporter],
          ),
          allContributorsProvider.overrideWith(
            (ref) async => [supporter],
          ),
        ],
        child: const MaterialApp(
          home: SubscriberDetailPage(contributorId: 'supporter-test-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ملف الداعم التفصيلي'), findsOneWidget);
    expect(find.text('محمد الداعم'), findsOneWidget);

    // التحقق من ترويسة جدول الداعم (مواد غذائية ومواد أنشائية)
    expect(find.text('مواد غذائية'), findsOneWidget);
    expect(find.text('مواد أنشائية'), findsOneWidget);
  });
}
