import 'package:flutter_test/flutter_test.dart';
import 'package:mawkib_zahra/core/utils/formatters.dart';
import 'package:mawkib_zahra/shared/models/contributor_model.dart';
import 'package:mawkib_zahra/shared/models/enums.dart';
import 'package:mawkib_zahra/shared/models/permissions.dart';
import 'package:mawkib_zahra/shared/models/stats_snapshot.dart';

void main() {
  group('حساب حالة السداد', () {
    ContributorModel sub({
      required SubscriptionType type,
      required int daysSinceLastPayment,
      bool? override,
    }) =>
        ContributorModel(
          id: 't',
          type: ContributorType.subscriber,
          fullName: 'مشترك',
          subscriptionAmount: 100000,
          subscriptionType: type,
          lastPaymentAt:
              DateTime.now().subtract(Duration(days: daysSinceLastPayment)),
          isLateOverride: override,
        );

    test('الشهري مسدد إذا دفع قبل أقل من ٣٠ يوماً', () {
      expect(
        sub(type: SubscriptionType.monthly, daysSinceLastPayment: 20)
            .paymentStatus,
        PaymentStatus.paid,
      );
    });

    test('الشهري متأخر إذا مضى أكثر من ٣٠ يوماً', () {
      final c = sub(type: SubscriptionType.monthly, daysSinceLastPayment: 45);
      expect(c.paymentStatus, PaymentStatus.overdue);
      expect(c.daysOverdue, 15);
    });

    test('السنوي مسدد بعد ٤٥ يوماً — لا يُقاس بمقياس الشهري', () {
      expect(
        sub(type: SubscriptionType.yearly, daysSinceLastPayment: 45)
            .paymentStatus,
        PaymentStatus.paid,
      );
    });

    test('السنوي متأخر بعد أكثر من ٣٦٥ يوماً', () {
      expect(
        sub(type: SubscriptionType.yearly, daysSinceLastPayment: 400)
            .paymentStatus,
        PaymentStatus.overdue,
      );
    });

    test('تجاوز المدير اليدوي يتغلّب على الحساب التلقائي', () {
      // مضى ٤٥ يوماً على اشتراك شهري = متأخر تلقائياً، لكن المدير يقول مسدد
      expect(
        sub(
          type: SubscriptionType.monthly,
          daysSinceLastPayment: 45,
          override: false,
        ).paymentStatus,
        PaymentStatus.paid,
      );
    });

    test('مشترك بلا أي دفعة يُعتبر متأخراً', () {
      const c = ContributorModel(
        id: 't',
        type: ContributorType.subscriber,
        fullName: 'مشترك',
        subscriptionType: SubscriptionType.monthly,
      );
      expect(c.paymentStatus, PaymentStatus.overdue);
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

    test('العضو لا يرى الأسماء', () {
      expect(UserRole.member.canSeeNames, isFalse);
      expect(UserRole.admin.canSeeNames, isTrue);
      expect(UserRole.finance.canSeeNames, isTrue);
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

    test('الاختصار يستخدم ألف ومليون', () {
      expect(Fmt.moneyShort(2500000).contains('مليون'), isTrue);
      expect(Fmt.moneyShort(45000).contains('ألف'), isTrue);
    });
  });
}
