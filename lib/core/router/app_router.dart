import 'package:flutter/material.dart';
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
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../widgets/app_shell.dart';

/// مسارات التطبيق.
///
/// الشاشات الخمس داخل [StatefulShellRoute.indexedStack] فيبقى شريط التنقّل
/// ثابتاً وتُحفظ حالة كل تبويب. الشاشات الفرعية (قوائم المساهمين، الجداول)
/// تُفتح **داخل** التبويب نفسه فلا يختفي الشريط السفلي.
final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
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
                  builder: (_, _) => const ReportDetailPage(
                    isDonorsReport: false,
                    reportType: 'subscribers',
                  ),
                ),
                GoRoute(
                  path: 'donors',
                  builder: (_, _) => const ReportDetailPage(
                    isDonorsReport: true,
                    reportType: 'donors',
                  ),
                ),
                GoRoute(
                  path: ':type',
                  builder: (context, state) => ReportDetailPage(
                    isDonorsReport: false,
                    reportType: state.pathParameters['type'],
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
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
