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
      appBar: AutoHidingAppBar(
        title: const Text('وصل المشتريات والمصروفات'),
        centerTitle: true,
        actions: [
          state.maybeWhen(
            data: (list) => IconButton(
              icon: const Icon(Icons.print_rounded, color: AppColors.gold),
              tooltip: 'طباعة الكل',
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
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddPurchaseSheet(),
            );
          },
          backgroundColor: AppColors.gold,
          icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.greenDeep),
          label: const Text(
            'شراء جديد',
            style: TextStyle(
              color: AppColors.greenDeep,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (err, _) => Center(child: Text('حدث خطأ: $err')),
        data: (list) {
          final stats = ref.watch(statsProvider);
          final totalAmount = stats.valueOrNull?.totalAmount ?? 0;
          final totalPurchases = list.fold<num>(0, (sum, item) => sum + item.amount);
          final availableBalance = totalAmount - totalPurchases;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.isEmpty ? 2 : list.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FinancialSafeCard(
                    availableBalance: availableBalance,
                    loading: stats.isLoading,
                  ),
                );
              }
              
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('لا توجد مشتريات مسجلة بعد.')),
                );
              }
              
              final item = list[index - 1];
              return _PurchaseTile(
                purchase: item,
                isDark: isDark,
                onPrint: () async {
                  await PdfPurchaseService.generateAndPrint(item);
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف الشراء'),
                      content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
                      actions: [
                        TextButton(
                          onPressed: () => ctx.pop(false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => ctx.pop(true),
                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(purchasesProvider.notifier).deletePurchase(item.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({
    required this.purchase,
    required this.isDark,
    required this.onPrint,
    required this.onDelete,
  });

  final PurchaseModel purchase;
  final bool isDark;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.itemName,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Fmt.money(purchase.amount),
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                if (purchase.supplierName?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    'المشتري: ${purchase.supplierName}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  Fmt.dateShort(purchase.purchaseDate),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.print_rounded, color: Colors.blueAccent),
                tooltip: 'طباعة وصل',
                onPressed: onPrint,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                tooltip: 'حذف',
                onPressed: onDelete,
              ),
            ],
          )
        ],
      ),
    );
  }
}
