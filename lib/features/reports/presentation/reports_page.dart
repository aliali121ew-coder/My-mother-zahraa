import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/permissions.dart';

/// صفحة التقارير: كارتان **مربعان بحواف ناعمة** كما طُلب — المشتركون
/// والمتبرعون. الدخول لأي كارت يفتح جدولاً احترافياً بالأسماء مع شعار
/// الموكب وتاريخ الطباعة (الجدول قيد البناء في هذه المرحلة).
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    // التقارير بالأسماء للمدير والمسؤول المالي فقط
    if (!session.role.canViewReports) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('التقارير')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: GlassCard(
              blur: true,
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 34, color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text('التقارير غير متاحة لدورك',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    'عرض وطباعة التقارير بالأسماء متاح للمدير العام '
                    'والمسؤول المالي فقط.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text('اختر التقرير المطلوب طباعته',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          // كارتان مربعان متجاوران
          LayoutBuilder(
            builder: (context, c) {
              // العرض المتاح لكل كارت مع فراغ ١٤ بينهما
              final side = (c.maxWidth - 14) / 2;
              return Row(
                children: [
                  SizedBox(
                    width: side,
                    height: side,
                    child: _SquareReportCard(
                      title: 'المشتركون',
                      icon: Icons.groups_2_rounded,
                      onTap: () => _soon(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: side,
                    height: side,
                    child: _SquareReportCard(
                      title: 'المتبرعون',
                      icon: Icons.volunteer_activism_rounded,
                      onTap: () => _soon(context),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.gold),
                    const SizedBox(width: 9),
                    Text('مواصفات الجدول', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'رأس يحتوي شعار الموكب واسمه وعنوان التقرير وتاريخ ووقت '
                  'الطباعة · عمود الاسم مثبّت مع تمرير أفقي لبقية الأعمدة · '
                  'تظليل متبادل بين السطور مع تظليل عند اللمس · تذييل بكروت '
                  'العدد الكلي ومجموع المبالغ · الطباعة تعرض كل الأعمدة بحجم A4',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جدول التقرير قيد البناء')),
      );
}

class _SquareReportCard extends StatelessWidget {
  const _SquareReportCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      blur: true,
      onTap: onTap,
      radius: AppTheme.radiusLarge,
      padding: const EdgeInsets.all(18),
      gradient: isDark ? AppColors.countCardGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('عرض الجدول',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left_rounded,
                      size: 17, color: AppColors.gold),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
