import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_page.dart';
import '../../features/auth/presentation/pending_page.dart';
import '../../features/contributors/presentation/all_contributors_categories_page.dart';
import '../../features/contributors/presentation/contributors_page.dart';
import '../../features/contributors/presentation/contributors_list_page.dart';
import '../../features/contributors/presentation/subscriber_detail_page.dart';
import '../../features/contributors/presentation/subscriber_profile_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/posts/presentation/posts_page.dart';
import '../../features/reports/presentation/report_details_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/admin_users_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';

/// مسارات التطبيق.
///
/// الشاشات الخمس داخل [StatefulShellRoute.indexedStack] فيبقى شريط التنقّل
/// ثابتاً وتُحفظ حالة كل تبويب. الشاشات الفرعية (قوائم المساهمين، الجداول)
/// تُفتح **داخل** التبويب نفسه فلا يختفي الشريط السفلي.
/// حارس المسارات (P2): يعيد تقييم مسار كل تنقّل ويوجّه:
///  • الزائر غير المسجّل → شاشة تسجيل الدخول
///  • حساب بانتظار الموافقة أو محظور → شاشة الانتظار
///  • المسجّل المعتمد → الصفحة المطلوبة
///
/// `refreshListenable` يضمن إعادة التقييم عند كل تغيير في الجلسة.
String? _guard(BuildContext context, GoRouterState state) {
  final s = ProviderScope.containerOf(context, listen: false)
      .read(sessionProvider);

  // المسارات العامة تبقى متاحة للجميع
  final path = state.matchedLocation;
  if (path == '/splash' || path == '/auth' || path == '/pending') return null;

  // من لا يملك ملفاً شخصياً (زائر أو خرج حديثاً) → تسجيل الدخول
  if (s.isGuest) return '/auth';

  // حساب موقوف بانتظار موافقة المدير أو محظور → شاشة الانتظار
  if (s.isPending || s.isBanned) return '/pending';

  // لوحة إدارة الحسابات حصرية للمدير العام — غير المدير لا يدخلها
  if (path == '/settings/admin/users' && !s.isAdmin) return '/';

  return null;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  redirect: _guard,
  // إعادة تقييم المسارات عند كل تغيّر في الجلسة (دخول/خروج/تغيّر الدور)
  refreshListenable: SessionListenable.instance,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, _) => const SplashPage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (_, _) => const AuthPage(),
    ),
    GoRoute(path: '/pending', builder: (_, _) => const PendingPage()),
    GoRoute(
      path: '/subscriber_detail/:id',
      builder: (context, state) => SubscriberDetailPage(
        contributorId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/subscriber_profile/:id',
      builder: (context, state) => SubscriberProfilePage(
        contributorId: state.pathParameters['id']!,
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/contributors',
              builder: (_, _) => const ContributorsPage(),
              routes: [
                GoRoute(
                  path: 'donors',
                  builder: (_, _) =>
                      const ContributorsListPage(showDonors: true),
                ),
                GoRoute(
                  path: 'subscribers',
                  builder: (_, _) =>
                      const ContributorsListPage(showDonors: false),
                ),
                GoRoute(
                  path: 'subscriber_detail/:id',
                  builder: (context, state) => SubscriberDetailPage(
                    contributorId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'subscriber_profile/:id',
                  builder: (context, state) => SubscriberProfilePage(
                    contributorId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'all',
                  builder: (_, _) =>
                      const AllContributorsCategoriesPage(),
                ),
                GoRoute(
                  path: 'supporters',
                  builder: (_, _) =>
                      const ContributorsListPage(showSupporters: true),
                ),
                GoRoute(
                  path: 'list_all',
                  builder: (_, _) =>
                      const ContributorsListPage(showAll: true),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/posts', builder: (_, _) => const PostsPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (_, _) => const ReportsPage(),
              routes: [
                GoRoute(
                  path: 'subscribers',
                  builder: (_, _) => const ReportDetailPage(isDonorsReport: false),
                ),
                GoRoute(
                  path: 'donors',
                  builder: (_, _) => const ReportDetailPage(isDonorsReport: true),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'admin/users',
                  builder: (_, _) => const AdminUsersPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 14),
            Text('الصفحة غير موجودة: ${state.uri}',
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  ),
);

/// مستمع يعيد تقييم توجيه GoRouter عند كل تغيّر في الجلسة عبر Riverpod.
///
/// يستدعي `ProviderScope.containerOf` من أعلى شجرة التطبيق (عبر
/// `navigatorKey` في `MaterialApp`) ثم يشترك في `sessionProvider`، فيُشعَل
/// GoRouter بإعادة تشغيل دالة التوجيه `_guard` وتحديث المسار إن لزم.
class SessionListenable extends ChangeNotifier {
  SessionListenable._();
  static final SessionListenable instance = SessionListenable._();

  bool _started = false;

  /// يشغّل الاشتراك — يجب استدعاؤه مرة واحدة من `main()` بعد بناء
  /// `ProviderScope`، وإلا لن يتحدّث التوجيه عند الدخول/الخروج.
  void start(ProviderContainer container) {
    if (_started) return;
    _started = true;
    container.listen<AppSession>(
      sessionProvider,
      (_, __) => notifyListeners(),
      fireImmediately: true,
    );
  }
}
