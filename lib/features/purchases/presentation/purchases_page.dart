import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/purchase_model.dart';
import '../../../shared/widgets/stat_cards.dart';
import '../../../core/providers/app_providers.dart';
import '../data/purchases_provider.dart';
import 'widgets/add_purchase_sheet.dart';
import '../data/pdf_purchase_service.dart';

class PurchasesPage extends ConsumerWidget {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchasesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AutoHidingAppBar(
        title: const Text('سجل الخزنة والمصروفات'),
        centerTitle: true,
        actions: [
          state.maybeWhen(
            data: (list) => IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : AppColors.greenDeep.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isDark
                        ? AppColors.gold.withValues(alpha: 0.35)
                        : AppColors.greenDeep.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(Icons.print_rounded, color: AppColors.gold, size: 19),
              ),
              tooltip: 'طباعة كشف المشتريات A4',
              onPressed: () {
                if (list.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا توجد مشتريات لطباعتها')),
                  );
                  return;
                }
                PdfPurchaseService.generateAndPrintAll(list);
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                AppColors.goldBright,
                AppColors.gold,
                AppColors.goldDark,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldDark.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddPurchaseSheet(),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppColors.greenDeep,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'تسجيل شراء جديد',
                      style: TextStyle(
                        color: AppColors.greenDeep,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(purchasesProvider.notifier).load();
          ref.invalidate(statsRawProvider);
        },
        color: AppColors.gold,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (err, _) => Center(child: Text('حدث خطأ: $err')),
          data: (list) {
            final stats = ref.watch(statsProvider);
            final totalAmount = stats.valueOrNull?.totalAmount ?? 0;
            final totalPurchases =
                list.fold<num>(0, (sum, item) => sum + item.amount);
            final availableBalance = totalAmount - totalPurchases;

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: list.isEmpty ? 2 : list.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FinancialSafeCard(
                      availableBalance: availableBalance,
                      totalExpenses: totalPurchases,
                      purchasesCount: list.length,
                      loading: state.isLoading,
                    ),
                  );
                }

                if (list.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 42,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'لا توجد مشتريات أو مصروفات مسجلة بعد',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اضغط على زر «تسجيل شراء جديد» لإضافة وصل شراء وتحديث رصيد الخزنة تلقائياً.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textOnLightMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final item = list[index - 1];
                return _PurchaseTile(
                  index: index,
                  purchase: item,
                  isDark: isDark,
                  onPrint: () async {
                    await PdfPurchaseService.generateAndPrint(item);
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف وصل الشراء'),
                        content: const Text(
                          'هل أنت متأكد من حذف هذا السجل؟ سيُعاد المبلغ لرصيد الخزنة فوراً.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => ctx.pop(false),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () => ctx.pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.overdue,
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(purchasesProvider.notifier).deletePurchase(item.id);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({
    required this.index,
    required this.purchase,
    required this.isDark,
    required this.onPrint,
    required this.onDelete,
  });

  final int index;
  final PurchaseModel purchase;
  final bool isDark;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8E4),
      gradient: LinearGradient(
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ]
            : [
                Colors.white,
                const Color(0xFFF7FBF8),
              ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      child: Row(
        children: [
          // وسم وصل الشراء بألوان التطبيق الملكية (الأخضر والذهبي)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.greenDeep,
                        AppColors.greenRich,
                      ]
                    : [
                        AppColors.greenDeep.withValues(alpha: 0.1),
                        AppColors.greenDeep.withValues(alpha: 0.2),
                      ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : AppColors.greenDeep.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.receipt_long_rounded,
                color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        purchase.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textOnLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.greenDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.gold.withValues(alpha: 0.35)
                              : AppColors.greenDeep.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        Fmt.money(purchase.amount),
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.goldBright
                              : AppColors.greenDeep,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (purchase.supplierName?.isNotEmpty == true) ...[
                      Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: isDark ? AppColors.gold : AppColors.greenDeep,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          purchase.supplierName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textOnLightMuted,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.greenDeep.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: isDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textOnLightMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Fmt.dateShort(purchase.purchaseDate),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textOnDarkMuted
                                  : AppColors.textOnLightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // أزرار العمليات المصغرة الأنيقة
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onPrint,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.gold.withValues(alpha: 0.12)
                        : AppColors.goldBright.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.overdue.withValues(alpha: 0.12)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.overdue.withValues(alpha: 0.3)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.overdue,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
