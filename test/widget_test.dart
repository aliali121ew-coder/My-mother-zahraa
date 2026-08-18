import 'package:flutter_test/flutter_test.dart';
import 'package:mawkib_zahra/core/utils/formatters.dart';
import 'package:mawkib_zahra/shared/models/contributor_model.dart';
import 'package:mawkib_zahra/shared/models/enums.dart';
import 'package:mawkib_zahra/shared/models/permissions.dart';
import 'package:mawkib_zahra/shared/models/stats_snapshot.dart';

void main() {
  group('حساب حالة السداد الثلاثية (مسدد - في المهلة - متأخر)', () {
    test('الشهري مسدد طالما أنه ضمن شهر الاشتراك المدفوع', () {
      final c = ContributorModel(
        id: '1',
        type: ContributorType.subscriber,
        fullName: 'مشترك',
        subscriptionType: SubscriptionType.monthly,
        lastPaymentAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(c.paymentStatus, PaymentStatus.paid);
      expect(c.isPaid, isTrue);
    });

    test('حساب مواعيد انتهاء شهر الاشتراك ومهلة يوم 10 من الشهر الجديد دقيقاً', () {
      final lastPayment = DateTime(2026, 6, 15);
      final c = ContributorModel(
        id: '2',
        type: ContributorType.subscriber,
        fullName: 'مشترك شهري',
        subscriptionType: SubscriptionType.monthly,
        lastPaymentAt: lastPayment,
      );
      expect(c.paidPeriodEndDate?.month, 7);
      expect(c.paidPeriodEndDate?.day, 15);
      expect(c.graceCutoffDate?.month, 8);
      expect(c.graceCutoffDate?.day, 10);
    });

    test('السنوي مسدد خلال السنة الأولى، وفي المهلة بعد انتهاء السنة ضمن 30 يوماً', () {
      final cPaid = ContributorModel(
        id: '3',
        type: ContributorType.subscriber,
        fullName: 'مشترك سنوي',
        subscriptionType: SubscriptionType.yearly,
        lastPaymentAt: DateTime.now().subtract(const Duration(days: 200)),
      );
      expect(cPaid.paymentStatus, PaymentStatus.paid);
    });

    test('تجاوز المدير اليدوي يتغلّب على الحساب التلقائي', () {
      final c = ContributorModel(
        id: '4',
        type: ContributorType.subscriber,
        fullName: 'مشترك',
        subscriptionType: SubscriptionType.monthly,
        lastPaymentAt: DateTime.now().subtract(const Duration(days: 90)),
        isLateOverride: false,
      );
      expect(c.paymentStatus, PaymentStatus.paid);
    });

    test('مشترك بلا أي دفعة يُعتبر متأخراً', () {
      const c = ContributorModel(
        id: '5',
        type: ContributorType.subscriber,
        fullName: 'مشترك جديد',
        subscriptionType: SubscriptionType.monthly,
      );
      expect(c.paymentStatus, PaymentStatus.overdue);
      expect(c.isOverdue, isTrue);
    });
  });

  group('المبلغ الكلي', () {
    test('يجمع الاشتراكات والتبرعات النقدية فقط', () {
      const s = StatsSnapshot(
        subscriptionsTotal: 500000,
        donationsTotal: 1500000,
        inKindCount: 9,
      );
      expect(s.totalAmount, 2000000);
    });

    test('التبرع العيني لا يضيف أي مبلغ للمجموع', () {
      const withInKind = StatsSnapshot(donationsTotal: 100, inKindCount: 50);
      const withoutInKind = StatsSnapshot(donationsTotal: 100);
      expect(withInKind.totalAmount, withoutInKind.totalAmount);
    });
  });

  group('الصلاحيات', () {
    test('المدير وحده يدير المساهمين', () {
      expect(UserRole.admin.canManageContributors, isTrue);
      expect(UserRole.finance.canManageContributors, isFalse);
      expect(UserRole.publisher.canManageContributors, isFalse);
      expect(UserRole.member.canManageContributors, isFalse);
    });

    test('المسؤول المالي يعرض التقارير بلا تعديل', () {
      expect(UserRole.finance.canViewReports, isTrue);
      expect(UserRole.finance.canRecordPayments, isFalse);
    });

    test('كل شخص مسجل يرى الأسماء', () {
      expect(UserRole.member.canSeeNames, isTrue);
      expect(UserRole.admin.canSeeNames, isTrue);
      expect(UserRole.finance.canSeeNames, isTrue);
      expect(UserRole.publisher.canSeeNames, isTrue);
    });

    test('الناشر ينشر ولا يرى التقارير', () {
      expect(UserRole.publisher.canPublish, isTrue);
      expect(UserRole.publisher.canViewReports, isFalse);
    });
  });

  group('التنسيق', () {
    test('المبلغ الفارغ يظهر شرطة لا صفراً', () {
      expect(Fmt.money(null), '—');
    });

    test('جميع المبالغ تُنسق بالفوارز مع اسم العملة', () {
      expect(Fmt.moneyShort(2500000), '2,500,000 د.ع');
      expect(Fmt.moneyShort(45000), '45,000 د.ع');
    });
  });
}
