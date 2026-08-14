import 'enums.dart';

/// صلاحيات كل دور — **مرآة** لسياسات RLS في Postgres.
///
/// مهم: هذه الطبقة لإخفاء الأزرار وتحسين التجربة فقط. الحماية الحقيقية
/// مفروضة في قاعدة البيانات، فلو تلاعب أحدهم بالتطبيق لن يتجاوز RLS.
/// أي تعديل هنا يجب أن يقابله تعديل في ملف supabase/schema.sql.
extension RolePermissions on UserRole {
  /// إضافة وتعديل وحذف المشتركين والمتبرعين والمبالغ — المدير العام فقط
  bool get canManageContributors => this == UserRole.admin;

  /// تسجيل الدفعات وإصدار الوصولات — المدير فقط
  bool get canRecordPayments => this == UserRole.admin;

  /// عرض وطباعة التقارير بالأسماء — المدير والمسؤول المالي
  bool get canViewReports => this == UserRole.admin || this == UserRole.finance;

  /// رؤية أسماء المساهمين في القوائم — العضو لا يرى أسماء
  bool get canSeeNames => this == UserRole.admin || this == UserRole.finance;

  /// النشر في المنشورات ورفع الستوريز
  bool get canPublish => this == UserRole.admin || this == UserRole.publisher;

  /// إدارة أقسام الستوريز — المدير فقط
  bool get canManageStoryCategories => this == UserRole.admin;

  /// الموافقة على الحسابات وتغيير الأدوار والحظر — المدير فقط
  bool get canManageUsers => this == UserRole.admin;

  /// رؤية الإحصائيات والمجاميع — كل من سجّل واعتُمد
  ///
  /// تعديل أمني (P4): الامتداد وحده يعيد true لكل الأدوار (العضو أيضًا)،
  /// أما الاعتماد الفعلي `status='approved'` فيُفحص في
  /// `AppSession.canSeeStats` عند طبقة الجلسة. تركنا هنا التعريف الدقيق
  /// «الإحصائيات متاحة لكل الأدوار» مع توثيق واضح، والفيصل هو
  /// `AppSession.canSeeStats` الذي يشرط الاعتماد.
  bool get canSeeStats => true; // يعتمد على [AppSession.canSeeStats]
}
