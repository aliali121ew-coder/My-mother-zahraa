import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        color: isDark ? const Color(0xFF032214) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.greenDeep.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تسجيل شراء / مصروف جديد',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildModernField(
                controller: _itemNameCtrl,
                isDark: isDark,
                label: 'اسم المادة / المتطلب (مثال: أرز، لحم، خيم)',
                icon: Icons.inventory_2_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 12),
              _buildModernField(
                controller: _amountCtrl,
                isDark: isDark,
                label: 'المبلغ الإجمالي (د.ع)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                formatters: [ThousandsFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
                  if (num.tryParse(v.replaceAll(',', '')) == null) return 'يجب أن يكون رقماً صالحاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildModernField(
                controller: _supplierCtrl,
                isDark: isDark,
                label: 'اسم المشتري / أمين الصندوق (اختياري)',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF7FBF8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFDDE6E0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'تاريخ الشراء: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildModernField(
                controller: _notesCtrl,
                isDark: isDark,
                label: 'ملاحظات وتفاصيل إضافية (اختياري)',
                icon: Icons.edit_note_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.goldBright,
                        AppColors.gold,
                        AppColors.goldDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldDark.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _submit,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.greenDeep,
                                ),
                              )
                            : const Text(
                                'حفظ وتحديث الخزنة',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.greenDeep,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required bool isDark,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFDDE6E0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.5,
            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
          ),
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }
}
