import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/contributor_model.dart';
import '../../../../shared/models/enums.dart';

/// نافذة حوارية تفاعلية جذابة في وسط الشاشة بحجم 50% مع انطباع 3D وتدرج داكن وفاخر.
class AddContributorDialog extends ConsumerStatefulWidget {
  const AddContributorDialog({
    super.key,
    required this.mode,
  });

  final ContributorType mode;

  static Future<void> show(BuildContext context, ContributorType mode) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddContributorDialog(mode: mode),
    );
  }

  @override
  ConsumerState<AddContributorDialog> createState() =>
      _AddContributorDialogState();
}

class _AddContributorDialogState extends ConsumerState<AddContributorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _customSupportTypeController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _paymentDate = DateTime.now();
  DateTime _supportDate = DateTime.now();

  SubscriptionType _subscriptionType = SubscriptionType.monthly;

  // للمتبرع: نوع التبرع يفتح حقل المبلغ بعد الاختيار
  String? _selectedDonationType;

  String _inKindType = 'غذائية';

  XFile? _pickedImage;
  bool _isLoading = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _customSupportTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime initialDate,
    ValueChanged<DateTime> onSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: const Color(0xFF0D2818),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.mode == ContributorType.donor && _selectedDonationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'يرجى اختيار نوع التبرع أولاً قبل الحفظ',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.overdue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();

      // تنظيف النص من الفوارز عند تحويله إلى عدد
      final cleanAmountText =
          _amountController.text.replaceAll(',', '').replaceAll('٬', '').trim();
      final amount = num.tryParse(cleanAmountText) ?? 0;

      String? notes;
      SubscriptionType? subType;
      num? subAmount;
      num totalPaidAmount = 0;

      if (widget.mode == ContributorType.subscriber) {
        subType = _subscriptionType;
        subAmount = amount;
        totalPaidAmount = amount;
        notes = 'تاريخ الاشتراك: ${DateFormat('yyyy/MM/dd').format(_startDate)}';
      } else if (widget.mode == ContributorType.donor) {
        totalPaidAmount = amount;
        notes = 'نوع التبرع: ${_selectedDonationType ?? "نقدي"}';
      } else {
        // داعم / عيني
        final supportKind = _inKindType == 'أخرى'
            ? _customSupportTypeController.text.trim()
            : _inKindType;
        notes =
            'نوع المساهمة: $supportKind · تاريخ الدعم: ${DateFormat('yyyy/MM/dd').format(_supportDate)}';
      }

      final newContributor = ContributorModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.mode,
        fullName: name,
        phone: phone,
        photoUrl: _pickedImage?.path,
        subscriptionAmount: subAmount,
        subscriptionType: subType,
        lastPaymentAt: widget.mode == ContributorType.inKind
            ? _supportDate
            : _paymentDate,
        totalPaid: totalPaidAmount,
        notes: notes,
        createdAt: DateTime.now(),
      );

      // حفظ المساهم عبر المخزن
      await ref.read(contributorsRepositoryProvider).create(newContributor);

      // تحديث المزوّدات
      ref.invalidate(statsProvider);
      ref.invalidate(donorsProvider);
      ref.invalidate(subscribersProvider);
      ref.invalidate(allContributorsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تمت إضافة ${_titleText()} بنجاح (المبلغ: ${Fmt.money(totalPaidAmount)})',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenDeep,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    }
  }

  String _titleText() {
    switch (widget.mode) {
      case ContributorType.subscriber:
        return 'إضافة مشترك جديد';
      case ContributorType.donor:
        return 'إضافة متبرع جديد';
      case ContributorType.inKind:
        return 'إضافة داعم / مساهمة عينية';
    }
  }

  Color _accentColor() {
    switch (widget.mode) {
      case ContributorType.subscriber:
        return const Color(0xFF2E9E6B);
      case ContributorType.donor:
        return const Color(0xFFD79A3C);
      case ContributorType.inKind:
        return const Color(0xFF0077B6);
    }
  }

  IconData _headerIcon() {
    switch (widget.mode) {
      case ContributorType.subscriber:
        return Icons.person_add_rounded;
      case ContributorType.donor:
        return Icons.volunteer_activism_rounded;
      case ContributorType.inKind:
        return Icons.handshake_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final dateFormat = DateFormat('yyyy/MM/dd');

    // تصغير الحجم إلى حوالي 50% من عرض الشاشة مخصص للتمركز المريح
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.52).clamp(330.0, 420.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          // طابع داكن متدرج يبرز الكارت بقوة
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0F2D1C), // أخضر زردي عميق
              Color(0xFF05150D), // أسود مائل للأخضر
              Color(0xFF143823), // أخضر داكن فاخر
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.65),
            width: 1.5,
          ),
          // انطباع 3D برفع وتوهّج عميق متعدد الطبقات
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. الترويسة الفاخرة ذات الانطباع البارز
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.95),
                        accent.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(_headerIcon(), color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _titleText(),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 2. جسم التبويب المتمرّر (SCROLL) مع الفيزياء المرنة
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الاسم الثلاثي
                          _buildLabel(
                            widget.mode == ContributorType.subscriber
                                ? 'اسم المشترك الثلاثي'
                                : (widget.mode == ContributorType.donor
                                    ? 'اسم المتبرع الثلاثي'
                                    : 'اسم الداعم الثلاثي'),
                          ),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              hint: 'أدخل الاسم الكامل',
                              icon: Icons.person_outline_rounded,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'الاسم مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // رقم الهاتف (إن كان مشتركاً أو متبرعاً)
                          if (widget.mode != ContributorType.inKind) ...[
                            _buildLabel('رقم الهاتف'),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13.5,
                                color: Colors.white,
                              ),
                              decoration: _inputDecoration(
                                hint: '07700000000 (اختياري)',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // للمتبرع: اختيار نوع التبرع أولاً
                          if (widget.mode == ContributorType.donor) ...[
                            _buildLabel('اختر نوع التبرع أولاً'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'نقدي دفعة واحدة',
                                'كفالة',
                                'تبرع دوري',
                              ]
                                  .map((t) => _buildChoiceChip(
                                        label: t,
                                        selected: _selectedDonationType == t,
                                        onTap: () {
                                          setState(() => _selectedDonationType = t);
                                        },
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // للمشترك: حقل المبلغ مباشرة
                          if (widget.mode == ContributorType.subscriber ||
                              (widget.mode == ContributorType.donor &&
                                  _selectedDonationType != null)) ...[
                            _buildLabel('المبلغ (د.ع) — يُكتب بفوارز'),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                              onChanged: (val) {
                                // تنسيق الرقم بفوارز آلاف تلقائياً عند الكتابة
                                final raw = val
                                    .replaceAll(',', '')
                                    .replaceAll('٬', '')
                                    .trim();
                                if (raw.isNotEmpty) {
                                  final numVal = num.tryParse(raw);
                                  if (numVal != null) {
                                    final formatted = Fmt.amount(numVal);
                                    if (formatted != val) {
                                      _amountController.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              decoration: _inputDecoration(
                                hint: 'مثال: 25,000',
                                icon: Icons.payments_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'المبلغ مطلوب';
                                }
                                final raw = v
                                    .replaceAll(',', '')
                                    .replaceAll('٬', '')
                                    .trim();
                                if (num.tryParse(raw) == null) {
                                  return 'أدخل رقماً صحيحاً';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // نوع الاشتراك (للمشترك)
                          if (widget.mode == ContributorType.subscriber) ...[
                            _buildLabel('نوع الاشتراك'),
                            Row(
                              children: [
                                _buildChoiceChip(
                                  label: 'شهري',
                                  selected: _subscriptionType ==
                                      SubscriptionType.monthly,
                                  onTap: () => setState(() =>
                                      _subscriptionType =
                                          SubscriptionType.monthly),
                                ),
                                const SizedBox(width: 8),
                                _buildChoiceChip(
                                  label: 'سنوي',
                                  selected: _subscriptionType ==
                                      SubscriptionType.yearly,
                                  onTap: () => setState(() =>
                                      _subscriptionType =
                                          SubscriptionType.yearly),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildLabel('تاريخ الاشتراك'),
                            _buildDatePickerButton(
                              date: _startDate,
                              onTap: () => _selectDate(
                                context,
                                _startDate,
                                (d) => setState(() => _startDate = d),
                              ),
                              dateFormat: dateFormat,
                            ),
                            const SizedBox(height: 12),

                            _buildLabel('تاريخ الدفع'),
                            _buildDatePickerButton(
                              date: _paymentDate,
                              onTap: () => _selectDate(
                                context,
                                _paymentDate,
                                (d) => setState(() => _paymentDate = d),
                              ),
                              dateFormat: dateFormat,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // تاريخ الدفع (للمتبرع بعد اختيار نوع التبرع)
                          if (widget.mode == ContributorType.donor &&
                              _selectedDonationType != null) ...[
                            _buildLabel('تاريخ الدفع'),
                            _buildDatePickerButton(
                              date: _paymentDate,
                              onTap: () => _selectDate(
                                context,
                                _paymentDate,
                                (d) => setState(() => _paymentDate = d),
                              ),
                              dateFormat: dateFormat,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // نوع المساهمة وتاريخ الدعم (للداعم)
                          if (widget.mode == ContributorType.inKind) ...[
                            _buildLabel('نوع المساهمة'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['غذائية', 'خدمية', 'أثاث وقاعات', 'أخرى']
                                  .map((k) => _buildChoiceChip(
                                        label: k,
                                        selected: _inKindType == k,
                                        onTap: () =>
                                            setState(() => _inKindType = k),
                                      ))
                                  .toList(),
                            ),
                            if (_inKindType == 'أخرى') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customSupportTypeController,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13.5,
                                  color: Colors.white,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'اكتب نوع المساهمة يدويّاً...',
                                  icon: Icons.edit_note_rounded,
                                ),
                                validator: (v) => (_inKindType == 'أخرى' &&
                                        (v == null || v.trim().isEmpty))
                                    ? 'اكتب نوع المساهمة'
                                    : null,
                              ),
                            ],
                            const SizedBox(height: 12),

                            _buildLabel('تاريخ الدعم'),
                            _buildDatePickerButton(
                              date: _supportDate,
                              onTap: () => _selectDate(
                                context,
                                _supportDate,
                                (d) => setState(() => _supportDate = d),
                              ),
                              dateFormat: dateFormat,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // حقل تحميل الصورة مع المعاينة
                          _buildLabel('الصورة الشخصية / التوضيحية (تحميل)'),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 90,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.4),
                                  style: BorderStyle.solid,
                                  width: 1.2,
                                ),
                              ),
                              child: _pickedImage != null
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image.file(
                                            File(_pickedImage!.path),
                                            width: double.infinity,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: CircleAvatar(
                                            radius: 13,
                                            backgroundColor: Colors.black54,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.close,
                                                  size: 13, color: Colors.white),
                                              onPressed: () => setState(
                                                  () => _pickedImage = null),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cloud_upload_outlined,
                                            color: accent, size: 26),
                                        const SizedBox(height: 4),
                                        Text(
                                          'انقر لاختيار صورة من المعرض',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textOnDarkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. أزرار الإجراءات في الأسفل
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: accent.withValues(alpha: 0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_rounded, size: 19),
                                    SizedBox(width: 5),
                                    Text(
                                      'حفظ وإضافة',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.4),
      ),
      prefixIcon: Icon(icon, size: 19, color: _accentColor()),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: _accentColor(), width: 1.5),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = _accentColor();
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : accent,
        ),
      ),
      selected: selected,
      selectedColor: accent,
      backgroundColor: accent.withValues(alpha: 0.14),
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      showCheckmark: false,
    );
  }

  Widget _buildDatePickerButton({
    required DateTime date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 17, color: _accentColor()),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(date),
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}
