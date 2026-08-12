/// تعدادات التطبيق. قيمة `value` هي **نفسها** المخزّنة في Postgres،
/// لذا أي تعديل هنا يجب أن يقابله تعديل في مخطط قاعدة البيانات.
library;

/// أدوار المستخدمين الأربعة كما حُدّدت.
enum UserRole {
  admin('admin', 'مدير عام'),
  finance('finance', 'مسؤول مالي'),
  publisher('publisher', 'ناشر'),
  member('member', 'عضو');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => member);
}

/// حالة الحساب — التسجيل يتطلب موافقة المدير.
enum UserStatus {
  pending('pending', 'بانتظار الموافقة'),
  approved('approved', 'معتمد'),
  rejected('rejected', 'مرفوض'),
  banned('banned', 'محظور');

  const UserStatus(this.value, this.label);
  final String value;
  final String label;

  static UserStatus fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => pending);
}

/// نوع المساهم: مشترك أو متبرع — كلاهما مانح بفئتين مختلفتين.
enum ContributorType {
  subscriber('subscriber', 'مشترك'),
  donor('donor', 'متبرع'),
  inKind('in_kind', 'داعم');

  const ContributorType(this.value, this.label);
  final String value;
  final String label;

  static ContributorType fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => subscriber);
}

/// نوع الاشتراك — التسمية المعتمدة في الواجهة "نوع الاشتراك" لا "الدورية".
enum SubscriptionType {
  monthly('monthly', 'شهري', 30),
  yearly('yearly', 'سنوي', 365);

  const SubscriptionType(this.value, this.label, this.days);
  final String value;
  final String label;

  /// عدد الأيام المسموح بها قبل اعتبار المشترك متأخراً
  final int days;

  static SubscriptionType fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => monthly);
}

/// نوع التبرع. العيني **لا يدخل** في المبلغ الكلي إطلاقاً.
enum DonationKind {
  cash('cash', 'نقدي'),
  inKind('in_kind', 'عيني');

  const DonationKind(this.value, this.label);
  final String value;
  final String label;

  static DonationKind fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => cash);
}

/// حالة السداد — تُحسب تلقائياً ويمكن للمدير تجاوزها يدوياً.
enum PaymentStatus {
  paid('paid', 'مسدد'),
  grace('grace', 'في المهلة'),
  overdue('overdue', 'متأخر');

  const PaymentStatus(this.value, this.label);
  final String value;
  final String label;

  static PaymentStatus fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => overdue);
}
