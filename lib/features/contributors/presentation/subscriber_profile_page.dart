import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/thousands_formatter.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/auto_hiding_app_bar.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/app_date_picker_dialog.dart';

/// صفحة ملف الشخصي المستقلة للمشترك
class SubscriberProfilePage extends ConsumerStatefulWidget {
  const SubscriberProfilePage({
    super.key,
    required this.contributorId,
  });

  final String contributorId;

  @override
  ConsumerState<SubscriberProfilePage> createState() =>
      _SubscriberProfilePageState();
}

class _SubscriberProfilePageState
    extends ConsumerState<SubscriberProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  ContributorType _selectedType = ContributorType.subscriber;
  SubscriptionType _selectedSubType = SubscriptionType.monthly;
  DateTime _subscriptionDate = DateTime.now();

  XFile? _pickedImage;
  bool _isInitialized = false;
  bool _isSaving = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initFieldsOnce(ContributorModel c) {
    if (_isInitialized) return;
    _nameController.text = c.fullName;
    _phoneController.text = c.phone ?? '';
    _addressController.text = c.address ?? '';
    _amountController.text =
        c.subscriptionAmount != null ? Fmt.amount(c.subscriptionAmount!) : '';
    _notesController.text = c.notes ?? '';
    _selectedType = c.type;
    _selectedSubType = c.subscriptionType ?? SubscriptionType.monthly;
    _subscriptionDate = c.createdAt ?? DateTime.now();
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<void> _saveProfile(ContributorModel original) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final rawAmount = _amountController.text
          .replaceAll(',', '')
          .replaceAll('٬', '')
          .trim();
      final parsedAmount = num.tryParse(rawAmount);

      final updated = original.copyWith(
        fullName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : original.fullName,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        photoUrl: _pickedImage?.path ?? original.photoUrl,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        subscriptionAmount: parsedAmount ?? original.subscriptionAmount,
        subscriptionType: _selectedSubType,
        type: _selectedType,
        createdAt: _subscriptionDate,
      );

      final repo = ref.read(contributorsRepositoryProvider);
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      await repo.update(updated);

      await Future.wait([
        ref.refresh(donorsRawProvider.future),
        ref.refresh(subscribersRawProvider.future),
        ref.refresh(allContributorsRawProvider.future),
        ref.refresh(statsRawProvider.future),
      ]);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم حفظ بيانات الملف الشخصي بنجاح!'),
            backgroundColor: AppColors.greenDeep,
          ),
        );
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// التحقق مما إذا قام المستخدم بإجراء أي تعديلات غير محفوظة
  bool _hasUnsavedChanges(ContributorModel original) {
    if (!_isInitialized) return false;

    final nameText = _nameController.text.trim();
    final nameChanged = nameText.isNotEmpty && nameText != original.fullName;

    final phoneText = _phoneController.text.trim();
    final originalPhone = original.phone ?? '';
    final phoneChanged = phoneText != originalPhone;

    final addressText = _addressController.text.trim();
    final originalAddress = original.address ?? '';
    final addressChanged = addressText != originalAddress;

    final notesText = _notesController.text.trim();
    final originalNotes = original.notes ?? '';
    final notesChanged = notesText != originalNotes;

    final rawAmount = _amountController.text
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();
    final parsedAmount = num.tryParse(rawAmount);
    final originalAmount = original.subscriptionAmount;
    final amountChanged = parsedAmount != originalAmount;

    final typeChanged = _selectedType != original.type;
    final subTypeChanged =
        _selectedSubType != (original.subscriptionType ?? SubscriptionType.monthly);

    final photoChanged = _pickedImage != null;

    return nameChanged ||
        phoneChanged ||
        addressChanged ||
        notesChanged ||
        amountChanged ||
        typeChanged ||
        subTypeChanged ||
        photoChanged;
  }

  /// معالجة طلب الرجوع وإظهار نافذة التنبيه عند وجود تعديلات
  Future<bool> _handleBackPress(ContributorModel subscriber) async {
    if (!_hasUnsavedChanges(subscriber)) {
      return true;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.overdue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.overdue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تنبيه: إلغاء التعديلات؟',
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لقد قمت بإجراء تعديلات على بيانات الملف الشخصي. هل أنت تأكيد من الخروج وإلغاء التعديلات؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'متابعة التعديل',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.overdue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إلغاء التعديلات',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final subscribersAsync = ref.watch(allContributorsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allList = subscribersAsync.valueOrNull ?? [];
    final currentContrib = allList.firstWhere(
      (c) => c.id == widget.contributorId,
      orElse: () => ContributorModel(
        id: widget.contributorId,
        type: ContributorType.subscriber,
        fullName: 'المساهم',
      ),
    );
    final isSubscriber = currentContrib.type == ContributorType.subscriber;
    final isDonor = currentContrib.type == ContributorType.donor;
    final pageTitle = isSubscriber
        ? 'ملف المشترك الشخصي'
        : (isDonor ? 'ملف المتبرع الشخصي' : 'ملف الداعم الشخصي');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _handleBackPress(currentContrib);
        if (ok && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AutoHidingAppBar(
            title: Text(
              pageTitle,
              style: TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.goldBright : AppColors.goldDark,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? AppColors.goldBright : AppColors.goldDark,
                size: 20,
              ),
              tooltip: 'رجوع',
              onPressed: () async {
                final ok = await _handleBackPress(currentContrib);
                if (ok && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: subscribersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('تعذّر تحميل بيانات المشترك\n$err',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (all) {
            final subscriber = all.firstWhere(
              (c) => c.id == widget.contributorId,
              orElse: () => ContributorModel(
                id: widget.contributorId,
                type: ContributorType.subscriber,
                fullName: 'مشترك',
              ),
            );

            _initFieldsOnce(subscriber);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  // 1️⃣ القسم الأول: كارت الاسم والصورة الشخصية
                  _buildAvatarAndNameHeroCard(subscriber, isDark),
                  const SizedBox(height: 20),

                  // 2️⃣ القسم الثاني: باقي التفاصيل
                  _buildDetailsSection(subscriber, isDark),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: subscribersAsync.maybeWhen(
          data: (all) {
            final subscriber = all.firstWhere(
              (c) => c.id == widget.contributorId,
              orElse: () => ContributorModel(
                id: widget.contributorId,
                type: ContributorType.subscriber,
                fullName: 'مشترك',
              ),
            );
            return _buildBottomSaveBar(subscriber);
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    ),
  );
  }

  /// 1️⃣ كارت الاسم والصورة الشخصية الهيرو بتصميم بطاقة رسمية احترافية
  Widget _buildAvatarAndNameHeroCard(ContributorModel c, bool isDark) {
    final isDonor = _selectedType != ContributorType.subscriber;

    return GoldBorder(
      radius: AppTheme.radiusLarge,
      child: GlassCard(
        blur: true,
        radius: AppTheme.radiusLarge,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppColors.greenDeep.withValues(alpha: 0.95),
                  AppColors.greenAbyss,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFFFFDF5),
                  Color(0xFFF7F0DF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        child: Column(
          children: [
            // ── الشريط العلوي لشارة البطاقة الرقمية ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDonor ? 'بطاقة متبرع معتمد' : 'بطاقة مشترك معتمد',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.stars_rounded,
                  size: 20,
                  color: AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── الصورة الشخصية الدائرية مع التوهج الذهبي وزر الكاميرا ──
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.greenAbyss : Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : (c.photoUrl != null && c.photoUrl!.isNotEmpty
                              ? (c.photoUrl!.startsWith('http')
                                  ? NetworkImage(c.photoUrl!)
                                  : FileImage(File(c.photoUrl!))
                                      as ImageProvider)
                              : null),
                      child: (_pickedImage == null &&
                              (c.photoUrl == null || c.photoUrl!.isEmpty))
                          ? Text(
                              c.fullName.isNotEmpty ? c.fullName[0] : 'م',
                              style: const TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldBright,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldBright, AppColors.goldDark],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── الاسم الثلاثي ──
            Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : c.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.goldBright : AppColors.goldDark,
              ),
            ),
            const SizedBox(height: 6),

            // ── وسام نوع الحساب ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 15,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedType.label,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),

            // ── شريط تفاصيل التواصل السريعة ──
            if (_phoneController.text.isNotEmpty || (c.phone != null && c.phone!.isNotEmpty)) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _phoneController.text.isNotEmpty
                          ? _phoneController.text
                          : c.phone!,
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
            ],
          ],
        ),
      ),
    );
  }

  /// 2️⃣ القسم الثاني: باقي التفاصيل في كارت زجاجي مريح
  Widget _buildDetailsSection(ContributorModel c, bool isDark) {
    return GlassCard(
      blur: true,
      radius: AppTheme.radiusLarge,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.type != ContributorType.subscriber
                      ? 'التفاصيل الأساسية ومعلومات المتبرع'
                      : 'التفاصيل الأساسية ومعلومات الاشتراك',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // الاسم الثلاثي
          _buildInputField(
            controller: _nameController,
            label: 'الاسم الثلاثي',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم الثلاثي' : null,
          ),
          const SizedBox(height: 16),

          // رقم الهاتف
          _buildInputField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // العنوان / المنطقة
          _buildInputField(
            controller: _addressController,
            label: 'العنوان / المنطقة',
            icon: Icons.location_on_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // فئة الاشتراك (المبلغ)
          _buildInputField(
            controller: _amountController,
            label: 'فئة الاشتراك (المبلغ)',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
            hintText: '50,000',
            isDark: isDark,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsFormatter(),
            ],
          ),
          const SizedBox(height: 18),

          // نوع الاشتراك
          Text(
            'نوع الاشتراك:',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSelectOptionChip(
                  label: 'شهري',
                  icon: Icons.calendar_view_month_rounded,
                  selected: _selectedSubType == SubscriptionType.monthly,
                  onTap: () => setState(
                      () => _selectedSubType = SubscriptionType.monthly),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectOptionChip(
                  label: 'سنوي',
                  icon: Icons.event_repeat_rounded,
                  selected: _selectedSubType == SubscriptionType.yearly,
                  onTap: () => setState(
                      () => _selectedSubType = SubscriptionType.yearly),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // تاريخ الاشتراك
          Text(
            'تاريخ الاشتراك:',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await AppDatePickerDialog.show(
                context: context,
                initialDate: _subscriptionDate,
                firstDate: DateTime(2015),
                lastDate: DateTime(2040),
                primaryColor: AppColors.green,
              );
              if (picked != null) {
                setState(() => _subscriptionDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.18),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.gold),
                      SizedBox(width: 10),
                      Text('الموعد المسجّل:',
                          style: TextStyle(
                              fontFamily: AppTheme.fontFamily, fontSize: 13)),
                    ],
                  ),
                  Text(
                    Fmt.date(_subscriptionDate),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // نوع الحساب
          Text(
            'نوع الحساب (الفئة):',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ContributorType.subscriber,
              ContributorType.donor,
              ContributorType.inKind,
            ].map((t) {
              return _buildSelectOptionChip(
                label: t.label,
                icon: Icons.badge_outlined,
                selected: _selectedType == t,
                onTap: () => setState(() => _selectedType = t),
                isDark: isDark,
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // ملاحظات
          _buildInputField(
            controller: _notesController,
            label: 'ملاحظات إضافية',
            icon: Icons.note_alt_outlined,
            maxLines: 3,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// حقل إدخال موحّد وأنيق
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.5,
        color: isDark ? AppColors.goldBright : AppColors.goldDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13.5,
          color: isDark
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.28),
        ),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// شريحة اختيار تفاعلية مريحة
  Widget _buildSelectOptionChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.16)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.green
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15)),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.green
                  : (isDark
                      ? AppColors.textOnDarkMuted
                      : AppColors.textOnLightMuted),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? AppColors.green
                    : (isDark
                        ? AppColors.textOnDarkMuted
                        : AppColors.textOnLightMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// شريط السفلي الثابت لزر الحفظ
  Widget _buildBottomSaveBar(ContributorModel original) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : () => _saveProfile(original),
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 20, color: Colors.white),
          label: Text(
            _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
