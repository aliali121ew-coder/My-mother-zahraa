import 'dart:convert';

/// نموذج بيانات صلاحيات التطبيق القابلة للتفعيل والإلغاء من قبل مدير النظام.
class AppPermissionsModel {
  const AppPermissionsModel({
    this.canAddSubscriber = false,
    this.canAddDonor = false,
    this.canAddSupporter = false,
    this.canShowSubscriberNames = true,
    this.canShowDonorNames = true,
    this.canShowSupporterNames = true,
    this.canViewVaultReport = false,
    this.canViewConsolidatedReport = false,
    this.canViewSubscribersReport = false,
    this.canViewDonorsReport = false,
    this.canViewSupportersReport = false,
    this.canViewPaidReport = false,
    this.canViewOverdueReport = false,
    this.canViewVisitsLog = false,
    this.canViewInteractionsLog = false,
    this.canViewAccountRequests = false,
    this.canViewBlockedUsers = false,
    this.canViewArchiveLog = false,
  });

  // عمليات الإضافة (افتراضياً للمدير فقط، ويمكن للمدير تفعيلها للجميع)
  final bool canAddSubscriber;
  final bool canAddDonor;
  final bool canAddSupporter;

  // عرض الأسماء (افتراضياً متاح لكل من سجّل)
  final bool canShowSubscriberNames;
  final bool canShowDonorNames;
  final bool canShowSupporterNames;

  // كارتات التقارير والكشوفات التفصيلية
  final bool canViewVaultReport;
  final bool canViewConsolidatedReport;
  final bool canViewSubscribersReport;
  final bool canViewDonorsReport;
  final bool canViewSupportersReport;
  final bool canViewPaidReport;
  final bool canViewOverdueReport;
  final bool canViewVisitsLog;
  final bool canViewInteractionsLog;
  final bool canViewAccountRequests;
  final bool canViewBlockedUsers;
  final bool canViewArchiveLog;

  AppPermissionsModel copyWith({
    bool? canAddSubscriber,
    bool? canAddDonor,
    bool? canAddSupporter,
    bool? canShowSubscriberNames,
    bool? canShowDonorNames,
    bool? canShowSupporterNames,
    bool? canViewVaultReport,
    bool? canViewConsolidatedReport,
    bool? canViewSubscribersReport,
    bool? canViewDonorsReport,
    bool? canViewSupportersReport,
    bool? canViewPaidReport,
    bool? canViewOverdueReport,
    bool? canViewVisitsLog,
    bool? canViewInteractionsLog,
    bool? canViewAccountRequests,
    bool? canViewBlockedUsers,
    bool? canViewArchiveLog,
  }) {
    return AppPermissionsModel(
      canAddSubscriber: canAddSubscriber ?? this.canAddSubscriber,
      canAddDonor: canAddDonor ?? this.canAddDonor,
      canAddSupporter: canAddSupporter ?? this.canAddSupporter,
      canShowSubscriberNames:
          canShowSubscriberNames ?? this.canShowSubscriberNames,
      canShowDonorNames: canShowDonorNames ?? this.canShowDonorNames,
      canShowSupporterNames:
          canShowSupporterNames ?? this.canShowSupporterNames,
      canViewVaultReport: canViewVaultReport ?? this.canViewVaultReport,
      canViewConsolidatedReport:
          canViewConsolidatedReport ?? this.canViewConsolidatedReport,
      canViewSubscribersReport:
          canViewSubscribersReport ?? this.canViewSubscribersReport,
      canViewDonorsReport: canViewDonorsReport ?? this.canViewDonorsReport,
      canViewSupportersReport:
          canViewSupportersReport ?? this.canViewSupportersReport,
      canViewPaidReport: canViewPaidReport ?? this.canViewPaidReport,
      canViewOverdueReport: canViewOverdueReport ?? this.canViewOverdueReport,
      canViewVisitsLog: canViewVisitsLog ?? this.canViewVisitsLog,
      canViewInteractionsLog:
          canViewInteractionsLog ?? this.canViewInteractionsLog,
      canViewAccountRequests:
          canViewAccountRequests ?? this.canViewAccountRequests,
      canViewBlockedUsers: canViewBlockedUsers ?? this.canViewBlockedUsers,
      canViewArchiveLog: canViewArchiveLog ?? this.canViewArchiveLog,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canAddSubscriber': canAddSubscriber,
      'canAddDonor': canAddDonor,
      'canAddSupporter': canAddSupporter,
      'canShowSubscriberNames': canShowSubscriberNames,
      'canShowDonorNames': canShowDonorNames,
      'canShowSupporterNames': canShowSupporterNames,
      'canViewVaultReport': canViewVaultReport,
      'canViewConsolidatedReport': canViewConsolidatedReport,
      'canViewSubscribersReport': canViewSubscribersReport,
      'canViewDonorsReport': canViewDonorsReport,
      'canViewSupportersReport': canViewSupportersReport,
      'canViewPaidReport': canViewPaidReport,
      'canViewOverdueReport': canViewOverdueReport,
      'canViewVisitsLog': canViewVisitsLog,
      'canViewInteractionsLog': canViewInteractionsLog,
      'canViewAccountRequests': canViewAccountRequests,
      'canViewBlockedUsers': canViewBlockedUsers,
      'canViewArchiveLog': canViewArchiveLog,
    };
  }

  factory AppPermissionsModel.fromMap(Map<String, dynamic> map) {
    return AppPermissionsModel(
      canAddSubscriber: map['canAddSubscriber'] as bool? ?? false,
      canAddDonor: map['canAddDonor'] as bool? ?? false,
      canAddSupporter: map['canAddSupporter'] as bool? ?? false,
      canShowSubscriberNames: map['canShowSubscriberNames'] as bool? ?? true,
      canShowDonorNames: map['canShowDonorNames'] as bool? ?? true,
      canShowSupporterNames: map['canShowSupporterNames'] as bool? ?? true,
      canViewVaultReport: map['canViewVaultReport'] as bool? ?? false,
      canViewConsolidatedReport:
          map['canViewConsolidatedReport'] as bool? ?? false,
      canViewSubscribersReport:
          map['canViewSubscribersReport'] as bool? ?? false,
      canViewDonorsReport: map['canViewDonorsReport'] as bool? ?? false,
      canViewSupportersReport:
          map['canViewSupportersReport'] as bool? ?? false,
      canViewPaidReport: map['canViewPaidReport'] as bool? ?? false,
      canViewOverdueReport: map['canViewOverdueReport'] as bool? ?? false,
      canViewVisitsLog: map['canViewVisitsLog'] as bool? ?? false,
      canViewInteractionsLog: map['canViewInteractionsLog'] as bool? ?? false,
      canViewAccountRequests: map['canViewAccountRequests'] as bool? ?? false,
      canViewBlockedUsers: map['canViewBlockedUsers'] as bool? ?? false,
      canViewArchiveLog: map['canViewArchiveLog'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppPermissionsModel.fromJson(String source) =>
      AppPermissionsModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
