import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/supabase_repository.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thousands_formatter.dart';
import '../../../../shared/models/contributor_model.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/widgets/app_date_picker_dialog.dart';
import '../../../../shared/widgets/app_image_cropper_dialog.dart';

/// نافذة حوارية تفاعلية جذابة بعرض 50% موحّد، ترويسة ملونة في الأعلى وخلفية ضبابية زجاجية خلف النافذة.
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AddContributorDialog(mode: mode),
        );
      },
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

  // للمشترك: اختيار نوع الاشتراك غير محدد مسبقاً (تظهر باقي التفاصيل عند الضغط عليه كما في السابق)
  SubscriptionType? _selectedSubscriptionType;

  // للمتبرع: اختيار نوع التبرع غير محدد مسبقاً
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
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      final categoryName = widget.mode.label;
      final cropped = await AppImageCropperDialog.cropImage(
        context,
        picked,
        title: 'قص وضبط صورة $categoryName',
      );
      if (cropped != null && mounted) {
        setState(() => _pickedImage = cropped);
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime initialDate,
    ValueChanged<DateTime> onSelected,
  ) async {
    final picked = await AppDatePickerDialog.show(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      primaryColor: _accentColor(),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.mode == ContributorType.subscriber &&
        _selectedSubscriptionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تحديد نوع الاشتراك أولاً قبل الحفظ',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.overdue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.mode == ContributorType.donor && _selectedDonationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تحديد نوع التبرع أولاً قبل الحفظ',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.overdue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // فحص الصلاحية عند الحفظ — إن لم تكن الصلاحية مفعّلة تظهر نافذة تنبيه مخصصة لمدير النظام فقط
    final session = ref.read(sessionProvider);
    final permissions = ref.read(appPermissionsProvider);
    final isAllowed = session.isAdmin ||
        switch (widget.mode) {
          ContributorType.subscriber => permissions.canAddSubscriber,
          ContributorType.donor => permissions.canAddDonor,
          ContributorType.inKind => permissions.canAddSupporter,
        };

    if (!isAllowed) {
      _showAdminOnlyDialog(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();

      final cleanAmountText =
          _amountController.text.replaceAll(',', '').replaceAll('٬', '').trim();
      final amount = num.tryParse(cleanAmountText) ?? 0;

      String? notes;
      SubscriptionType? subType;
      num? subAmount;
      num totalPaidAmount = 0;

      if (widget.mode == ContributorType.subscriber) {
        subType = _selectedSubscriptionType;
        subAmount = amount;
        totalPaidAmount = amount;
        notes =
            'نوع الاشتراك: ${_selectedSubscriptionType?.label} · تاريخ الاشتراك: ${DateFormat('yyyy/MM/dd').format(_startDate)}';
      } else if (widget.mode == ContributorType.donor) {
        totalPaidAmount = amount;
        notes = 'نوع التبرع: ${_selectedDonationType ?? "نقدي"}';
      } else {
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

      final savedContributor =
          await ref.read(contributorsRepositoryProvider).create(newContributor);

      // تسجيل تسديد الشهر المختار تلقائياً في جدول التسديدات الشهري للمشترك الجديد
      if (widget.mode == ContributorType.subscriber && totalPaidAmount > 0) {
        await ref.read(contributorsRepositoryProvider).saveMonthPayment(
              contributorId: savedContributor.id,
              year: _paymentDate.year,
              month: _paymentDate.month,
              amount: totalPaidAmount,
              paidAt: _paymentDate,
              isPaid: true,
            );
      } else if (widget.mode == ContributorType.donor && totalPaidAmount > 0) {
        await ref.read(contributorsRepositoryProvider).addPayment(
              contributorId: savedContributor.id,
              amount: totalPaidAmount,
              paidAt: _paymentDate,
              note: notes,
            );
      }

      // تحديث المزوّدات في الخلفية لتنعكس التغييرات فوراً
      ref.invalidate(subscribersRawProvider);
      ref.invalidate(donorsRawProvider);
      ref.invalidate(allContributorsRawProvider);
      ref.invalidate(statsRawProvider);

      if (mounted) {
        // إغلاق النافذة والترحيل المباشر
        Navigator.of(context).pop();
        final destination = switch (widget.mode) {
          ContributorType.subscriber => '/contributors/subscribers',
          ContributorType.donor      => '/contributors/donors',
          ContributorType.inKind     => '/contributors/all',
        };
        if (mounted) context.go(destination);
        if (mounted) {
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
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تعذر الحفظ: ${arabicError(e)}',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.overdue,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        return Icons.shopping_basket_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor();
    final dateFormat = DateFormat('yyyy/MM/dd');

    // مقاسات متجاوبة ممتازة للهواتف والشاشات
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 460.0 : (screenWidth * 0.92);

    // ألوان داكنة للترويسة فقط وباقي الجسم أبيض ناصع في النهاري
    final bodyBgColor = isDark ? const Color(0xFF131A15) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A261D);
    final mutedTextColor =
        isDark ? AppColors.textOnDarkMuted : const Color(0xFF5A6E60);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          color: bodyBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.65 : 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.15),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.15),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. الترويسة الملونة الداكنة البارزة فوق فقط
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      accent.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(23)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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

              // 2. جسم التبويب الأبيض الصريح في النهاري مع التمرير (SCROLL)
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
                          textColor,
                        ),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.5,
                            color: textColor,
                          ),
                          decoration: _inputDecoration(
                            hint: 'أدخل الاسم الكامل',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'الاسم مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // رقم الهاتف (إن كان مشتركاً أو متبرعاً)
                        if (widget.mode != ContributorType.inKind) ...[
                          _buildLabel('رقم الهاتف', textColor),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              color: textColor,
                            ),
                            decoration: _inputDecoration(
                              hint: '07700000000 (اختياري)',
                              icon: Icons.phone_outlined,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // للمشترك: تحديد نوع الاشتراك أولاً
                        if (widget.mode == ContributorType.subscriber) ...[
                          _buildLabel('اختر نوع الاشتراك أولاً', textColor),
                          Row(
                            children: [
                              _buildChoiceChip(
                                label: 'شهري',
                                selected: _selectedSubscriptionType ==
                                    SubscriptionType.monthly,
                                onTap: () => setState(() =>
                                    _selectedSubscriptionType =
                                        SubscriptionType.monthly),
                              ),
                              const SizedBox(width: 8),
                              _buildChoiceChip(
                                label: 'سنوي',
                                selected: _selectedSubscriptionType ==
                                    SubscriptionType.yearly,
                                onTap: () => setState(() =>
                                    _selectedSubscriptionType =
                                        SubscriptionType.yearly),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // للمتبرع: تحديد نوع التبرع أولاً
                        if (widget.mode == ContributorType.donor) ...[
                          _buildLabel('اختر نوع التبرع أولاً', textColor),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'نقدي دفعة واحدة',
                              'تبرع مستمر',
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

                        // حقل المبلغ (د.ع) يظهر حتماً فقط بعد اختيار نوع الاشتراك أو نوع التبرع
                        if ((widget.mode == ContributorType.subscriber &&
                                _selectedSubscriptionType != null) ||
                            (widget.mode == ContributorType.donor &&
                                _selectedDonationType != null)) ...[
                          _buildLabel(
                            widget.mode == ContributorType.donor
                                ? 'مبلغ التبرع'
                                : 'مبلغ الاشتراك',
                            textColor,
                          ),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              ThousandsFormatter(),
                            ],
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDark,
                            ),
                            decoration: _inputDecoration(
                              hint: '25,000 د.ع',
                              icon: Icons.payments_outlined,
                              isDark: isDark,
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

                        // باقي تواريخ الاشتراك والدفع (للمشترك)
                        if (widget.mode == ContributorType.subscriber &&
                            _selectedSubscriptionType != null) ...[
                          _buildLabel('تاريخ الاشتراك', textColor),
                          _buildDatePickerButton(
                            date: _startDate,
                            onTap: () => _selectDate(
                              context,
                              _startDate,
                              (d) => setState(() => _startDate = d),
                            ),
                            dateFormat: dateFormat,
                            isDark: isDark,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),

                          _buildLabel('تاريخ الدفع', textColor),
                          _buildDatePickerButton(
                            date: _paymentDate,
                            onTap: () => _selectDate(
                              context,
                              _paymentDate,
                              (d) => setState(() => _paymentDate = d),
                            ),
                            dateFormat: dateFormat,
                            isDark: isDark,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // تاريخ الدفع (للمتبرع بعد اختيار نوع التبرع)
                        if (widget.mode == ContributorType.donor &&
                            _selectedDonationType != null) ...[
                          _buildLabel('تاريخ الدفع', textColor),
                          _buildDatePickerButton(
                            date: _paymentDate,
                            onTap: () => _selectDate(
                              context,
                              _paymentDate,
                              (d) => setState(() => _paymentDate = d),
                            ),
                            dateFormat: dateFormat,
                            isDark: isDark,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // نوع المساهمة وتاريخ الدعم (للداعم)
                        if (widget.mode == ContributorType.inKind) ...[
                          _buildLabel('نوع المساهمة', textColor),
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
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13.5,
                                color: textColor,
                              ),
                              decoration: _inputDecoration(
                                hint: 'اكتب نوع المساهمة يدويّاً...',
                                icon: Icons.edit_note_rounded,
                                isDark: isDark,
                              ),
                              validator: (v) => (_inKindType == 'أخرى' &&
                                      (v == null || v.trim().isEmpty))
                                  ? 'اكتب نوع المساهمة'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 12),

                          _buildLabel('تاريخ الدعم', textColor),
                          _buildDatePickerButton(
                            date: _supportDate,
                            onTap: () => _selectDate(
                              context,
                              _supportDate,
                              (d) => setState(() => _supportDate = d),
                            ),
                            dateFormat: dateFormat,
                            isDark: isDark,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // حقل تحميل الصورة مع المعاينة
                        _buildLabel('الصورة الشخصية / التوضيحية (تحميل)', textColor),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 90,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.08),
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
                                          color: mutedTextColor,
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
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: mutedTextColor,
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
                          elevation: 3,
                          shadowColor: accent.withValues(alpha: 0.4),
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
    );
  }

  Widget _buildLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        color: isDark
            ? Colors.white.withValues(alpha: 0.45)
            : const Color(0xFF8A9E90),
      ),
      prefixIcon: Icon(icon, size: 20, color: _accentColor()),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF4F7F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFD0DCD3),
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFD0DCD3),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accentColor(), width: 1.8),
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
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : accent,
        ),
      ),
      selected: selected,
      selectedColor: accent,
      backgroundColor: accent.withValues(alpha: 0.12),
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? accent : accent.withValues(alpha: 0.3),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildDatePickerButton({
    required DateTime date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
    required bool isDark,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF4F7F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFFD0DCD3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: _accentColor()),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(date),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down_rounded, color: _accentColor(), size: 24),
          ],
        ),
      ),
    );
  }

  void _showAdminOnlyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141D17) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تنبيه الصلاحيات',
                style: TextStyle(
                  fontFamily: AppTheme.displayFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصلاحية مخصصة لمدير النظام فقط.\nلا يمكنك إتمام عملية الحفظ أو الإضافة دون الحصول على إذن من إدارة الموكب.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334438),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.greenAbyss,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'فهمت ذلك',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
}

