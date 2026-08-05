import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../shared/models/contributor_model.dart';
import '../../../../shared/models/enums.dart';

/// نافذة تبويب تفاعلية جذابة في وسط الشاشة لإضافة (مشترك / متبرع / داعم).
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
  String _donationType = 'نقدي دفعة واحدة';
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
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? ColorScheme.dark(
                    primary: AppColors.gold,
                    onPrimary: Colors.black,
                    surface: const Color(0xFF0D2818),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.greenDeep,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
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

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();
      final amount = num.tryParse(_amountController.text.trim()) ?? 0;

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
        notes = 'نوع التبرع: $_donationType';
      } else {
        // داعم / عيني
        final supportKind = _inKindType == 'أخرى'
            ? _customSupportTypeController.text.trim()
            : _inKindType;
        notes = 'نوع المساهمة: $supportKind · تاريخ الدعم: ${DateFormat('yyyy/MM/dd').format(_supportDate)}';
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
                    'تمت إضافة ${_titleText()} بنجاح: $name',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor();
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GlassCard(
          blur: true,
          radius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. الترويسة الجذابة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.9),
                      accent.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_headerIcon(), color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _titleText(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 2. جسم النموذج الفروقي
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                          decoration: _inputDecoration(
                            hint: 'أدخل الاسم الكامل',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                        ),
                        const SizedBox(height: 14),

                        // رقم الهاتف (إن كان مشتركاً أو متبرعاً)
                        if (widget.mode != ContributorType.inKind) ...[
                          _buildLabel('رقم الهاتف'),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              hint: '07700000000 (اختياري)',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // حقل المبلغ (د.ع) (للمشترك والمتبرع)
                        if (widget.mode != ContributorType.inKind) ...[
                          _buildLabel('المبلغ (د.ع)'),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              hint: 'مثال: 25000',
                              icon: Icons.payments_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                              if (num.tryParse(v.trim()) == null) return 'أدخل رقماً صحيحاً';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        // نوع الاشتراك (للمشترك)
                        if (widget.mode == ContributorType.subscriber) ...[
                          _buildLabel('نوع الاشتراك'),
                          Row(
                            children: [
                              _buildChoiceChip(
                                label: 'شهري',
                                selected: _subscriptionType == SubscriptionType.monthly,
                                onTap: () => setState(
                                    () => _subscriptionType = SubscriptionType.monthly),
                              ),
                              const SizedBox(width: 10),
                              _buildChoiceChip(
                                label: 'سنوي',
                                selected: _subscriptionType == SubscriptionType.yearly,
                                onTap: () => setState(
                                    () => _subscriptionType = SubscriptionType.yearly),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 14),
                        ],

                        // نوع التبرع وتاريخ الدفع (للمتبرع)
                        if (widget.mode == ContributorType.donor) ...[
                          _buildLabel('نوع التبرع'),
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
                                      selected: _donationType == t,
                                      onTap: () => setState(() => _donationType = t),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 14),
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
                                      onTap: () => setState(() => _inKindType = k),
                                    ))
                                .toList(),
                          ),
                          if (_inKindType == 'أخرى') ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _customSupportTypeController,
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
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 14),
                        ],

                        // حقل تحميل الصورة مع المعاينة
                        _buildLabel('الصورة الشخصية / التوضيحية (اختياري)'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
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
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                            onPressed: () =>
                                                setState(() => _pickedImage = null),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          color: accent, size: 28),
                                      const SizedBox(height: 4),
                                      Text(
                                        'انقر لاختيار صورة من المعرض',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textOnDarkMuted
                                              : AppColors.textOnLightMuted,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_rounded, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'حفظ وإضافة',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14.5,
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
    );
  }

  Widget _buildLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: _accentColor()),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : accent,
        ),
      ),
      selected: selected,
      selectedColor: accent,
      backgroundColor: accent.withValues(alpha: 0.12),
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  Widget _buildDatePickerButton({
    required DateTime date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: _accentColor()),
            const SizedBox(width: 10),
            Text(
              dateFormat.format(date),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
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
