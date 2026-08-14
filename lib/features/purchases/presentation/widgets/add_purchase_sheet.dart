import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thousands_formatter.dart';
import '../../../../shared/models/purchase_model.dart';
import '../../../../shared/widgets/app_date_picker_dialog.dart';
import '../../data/purchases_provider.dart';

class AddPurchaseSheet extends ConsumerStatefulWidget {
  const AddPurchaseSheet({super.key});

  @override
  ConsumerState<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends ConsumerState<AddPurchaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await AppDatePickerDialog.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      primaryColor: AppColors.greenDeep,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _amountCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final purchase = PurchaseModel(
        id: const Uuid().v4(),
        itemName: _itemNameCtrl.text.trim(),
        amount: num.parse(_amountCtrl.text.trim().replaceAll(',', '')),
        supplierName: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        purchaseDate: _selectedDate,
      );

      await ref.read(purchasesProvider.notifier).addPurchase(purchase);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الشراء بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تسجيل شراء / متطلب جديد',
              style: TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.greenDeep,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.greenDeep.withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _itemNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المتطلب (مثال: أكياس رز، لحم، خيم)',
                  prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.gold),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.greenDeep.withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                decoration: const InputDecoration(
                  labelText: 'المبلغ الإجمالي (د.ع)',
                  prefixIcon: Icon(Icons.money, color: AppColors.gold),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
                  if (num.tryParse(v.replaceAll(',', '')) == null) return 'يجب أن يكون رقماً صالحاً';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.greenDeep.withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _supplierCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم أمين الصندوق / المشتري (اختياري)',
                  prefixIcon: Icon(Icons.person_rounded, color: AppColors.gold),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.greenDeep.withValues(alpha: 0.3) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Text(
                      'تاريخ الشراء: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.greenDeep.withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.gold.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات وتفاصيل إضافية (اختياري)',
                  prefixIcon: Icon(Icons.notes, color: AppColors.gold),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ وتسجيل',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
