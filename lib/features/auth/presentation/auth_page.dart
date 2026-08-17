import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/widgets/mawkib_logo.dart';
import '../../../shared/widgets/privacy_policy_dialog.dart';
import '../../reports/data/login_audit_service.dart';

/// شاشة تسجيل الدخول وإنشاء الحساب — تصميم ملكي مريح للعين بالأخضر الزمردي والأبيض.
///
/// تفصل بين تسجيل الدخول وإنشاء الحساب مع تبويب سفلي فاخر، وتدعم أعلى
/// معايير أمان لكلمة المرور والتحقق من التطابق والربط الحقيقي مع Supabase والتعرف التلقائي على بريد مدير النظام.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // حقول تسجيل الدخول
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // حقول إنشاء الحساب
  final _registerNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;
  bool _busy = false;

  // قوة كلمة المرور ومطابقتها
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _registerPasswordController.addListener(_calculatePasswordStrength);
    _registerConfirmPasswordController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerPhoneController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _calculatePasswordStrength() {
    final pass = _registerPasswordController.text;
    if (pass.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.transparent;
      });
      _checkPasswordMatch();
      return;
    }

    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+={}[\]:;<>,.?/|\\]').hasMatch(pass)) score++;

    double strength;
    String text;
    Color color;

    if (score <= 2) {
      strength = 0.33;
      text = 'كلمة مرور ضعيفة';
      color = Colors.redAccent;
    } else if (score <= 4) {
      strength = 0.66;
      text = 'كلمة مرور مقبولة / جيدة';
      color = Colors.amber.shade700;
    } else {
      strength = 1.0;
      text = 'كلمة مرور قوية جداً وآمنة';
      color = const Color(0xFF108A4D);
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });

    _checkPasswordMatch();
  }

  void _checkPasswordMatch() {
    final pass = _registerPasswordController.text;
    final confirm = _registerConfirmPasswordController.text;
    setState(() {
      _passwordsMatch = pass.isNotEmpty && confirm.isNotEmpty && pass == confirm;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: isDark ? AppColors.goldBright : AppColors.greenDeep,
              ),
            ),
            tooltip: 'تخطي والدخول للرئيسية',
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),

                      // ── ترويسة الشعار والعنوان الملكي ──────────────────────────
                      Center(
                        child: Hero(
                          tag: 'mawkib_logo',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greenDeep.withValues(alpha: isDark ? 0.35 : 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const MawkibLogo(height: 96, radius: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'موكب أمنا الزهراء',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tabController.index == 0
                            ? 'مرحباً بك — سجّل دخولك لمتابعة أعمال الموكب'
                            : 'انضم لخدمة موكب أمنا الزهراء وأنشئ حسابك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── المحتوى التفاعلي للتبويبين ──────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _tabController.index == 0
                            ? _buildSignInCard(isDark)
                            : _buildSignUpCard(isDark),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: TextButton.icon(
                          onPressed: () => PrivacyPolicyDialog.show(context),
                          icon: const Icon(Icons.shield_outlined, size: 15, color: AppColors.gold),
                          label: const Text(
                            'سياسة الخصوصية وحماية البيانات',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── التبويب السفلي الأبيض والأخضر الزمردي ──────────────────────────
              _buildBottomSwitcher(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. بطاقة تسجيل الدخول
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSignInCard(bool isDark) {
    return GlassCard(
      key: const ValueKey('signin_card'),
      blur: true,
      radius: 24,
      padding: const EdgeInsets.all(22),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFD4E2D8),
      gradient: isDark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F3D27).withValues(alpha: 0.65),
                const Color(0xFF092015).withValues(alpha: 0.85),
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                const Color(0xFFF4F9F6).withValues(alpha: 0.90),
              ],
            ),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.greenDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // حقل البريد الإلكتروني
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gold),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD4E2D8),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFD4E2D8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                if (!v.contains('@') || !v.contains('.')) return 'صيغة البريد الإلكتروني غير صحيحة';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // حقل كلمة المرور
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.key_outlined, color: AppColors.gold),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark ? Colors.white54 : Colors.black45,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD4E2D8),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFD4E2D8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                if (v.length < 6) return 'كلمة المرور ٦ أحرف على الأقل';
                return null;
              },
            ),

            // نسيت كلمة المرور
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // زر تسجيل الدخول الرئيسي
            _buildSubmitButton(
              label: 'تسجيل الدخول',
              icon: Icons.login_rounded,
              onPressed: _busy ? null : _handleSignIn,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // فاصل خفيف
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'أو',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              ],
            ),
            const SizedBox(height: 14),

            // الدخول كزائر
            OutlinedButton.icon(
              onPressed: () => context.go('/posts'),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.gold),
              label: const Text(
                'تصفح التطبيق كزائر (بدون حساب)',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. بطاقة إنشاء حساب جديد
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSignUpCard(bool isDark) {
    return GlassCard(
      key: const ValueKey('signup_card'),
      blur: true,
      radius: 24,
      padding: const EdgeInsets.all(22),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFD4E2D8),
      gradient: isDark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F3D27).withValues(alpha: 0.65),
                const Color(0xFF092015).withValues(alpha: 0.85),
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                const Color(0xFFF4F9F6).withValues(alpha: 0.90),
              ],
            ),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF108A4D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Color(0xFF108A4D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.greenDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // تنبيه مريح بأن الحساب يخضع لاعتماد المدير
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يتم تفعيل الحساب وتحديد رتبتك من قِبل مدير الموكب بعد إتمام التسجيل مباشرة.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.goldBright : AppColors.greenDeep,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // حقل الاسم الكامل
            TextFormField(
              controller: _registerNameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: _inputDecoration(
                labelText: 'الاسم الثلاثي الكامل',
                hintText: 'مثال: علي حسن الموسوي',
                prefixIcon: Icons.badge_outlined,
                isDark: isDark,
              ),
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return 'يرجى إدخال اسمك الثلاثي الكامل';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // حقل رقم الهاتف
            TextFormField(
              controller: _registerPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: _inputDecoration(
                labelText: 'رقم الهاتف للتواصل',
                hintText: '07XXXXXXXXX',
                prefixIcon: Icons.phone_iphone_outlined,
                isDark: isDark,
              ),
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'يرجى إدخال رقم هاتف صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // حقل البريد الإلكتروني
            TextFormField(
              controller: _registerEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: _inputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'user@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                isDark: isDark,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                if (!v.contains('@') || !v.contains('.')) return 'صيغة البريد غير صحيحة';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // حقل كلمة المرور مع مؤشر القوة
            TextFormField(
              controller: _registerPasswordController,
              obscureText: _obscureRegisterPassword,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: _inputDecoration(
                labelText: 'كلمة المرور (٨ أحرف على الأقل)',
                prefixIcon: Icons.lock_outline_rounded,
                isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegisterPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark ? Colors.white54 : Colors.black45,
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _obscureRegisterPassword = !_obscureRegisterPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'يجب أن لا تقل كلمة المرور عن ٨ خانات للأمان';
                }
                return null;
              },
            ),

            // شريط مؤشر قوة كلمة المرور
            if (_registerPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  minHeight: 4,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _passwordStrengthText,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _passwordStrengthColor,
                    ),
                  ),
                  Text(
                    'معيار الأمان: 8+ خانات وأرقام',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // حقل تأكيد كلمة المرور
            TextFormField(
              controller: _registerConfirmPasswordController,
              obscureText: _obscureRegisterConfirmPassword,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: _inputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: Icons.lock_reset_rounded,
                isDark: isDark,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_passwordsMatch)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.check_circle_rounded, color: Color(0xFF108A4D), size: 20),
                      ),
                    IconButton(
                      icon: Icon(
                        _obscureRegisterConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          _obscureRegisterConfirmPassword = !_obscureRegisterConfirmPassword),
                    ),
                  ],
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                if (v != _registerPasswordController.text) {
                  return 'كلمتا المرور غير متطابقتين';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // زر إرسال طلب إنشاء الحساب
            _buildSubmitButton(
              label: 'إرسال طلب إنشاء الحساب',
              icon: Icons.send_rounded,
              onPressed: _busy ? null : _handleSignUp,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. التبويب السفلي الفاخر (أبيض مع أخضر زمردي)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomSwitcher(bool isDark) {
    final activeIndex = _tabController.index;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF081C12).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFDCE8E0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEEF5F1),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? const Color(0xFF108A4D).withValues(alpha: 0.3)
                : const Color(0xFFD4E5DB),
          ),
        ),
        child: Row(
          children: [
            // تبويب تسجيل الدخول
            Expanded(
              child: InkWell(
                onTap: () => _tabController.animateTo(0),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: activeIndex == 0
                        ? (isDark ? const Color(0xFF0F3D27) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: activeIndex == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    border: activeIndex == 0
                        ? Border.all(
                            color: isDark
                                ? AppColors.gold.withValues(alpha: 0.5)
                                : const Color(0xFF108A4D).withValues(alpha: 0.3),
                            width: 1.2,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 17,
                        color: activeIndex == 0
                            ? (isDark ? AppColors.goldBright : const Color(0xFF0D3B25))
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          fontWeight: activeIndex == 0 ? FontWeight.w800 : FontWeight.w500,
                          color: activeIndex == 0
                              ? (isDark ? AppColors.goldBright : const Color(0xFF0D3B25))
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // تبويب إنشاء حساب
            Expanded(
              child: InkWell(
                onTap: () => _tabController.animateTo(1),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: activeIndex == 1
                        ? (isDark ? const Color(0xFF0F3D27) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: activeIndex == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    border: activeIndex == 1
                        ? Border.all(
                            color: isDark
                                ? AppColors.gold.withValues(alpha: 0.5)
                                : const Color(0xFF108A4D).withValues(alpha: 0.3),
                            width: 1.2,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 17,
                        color: activeIndex == 1
                            ? (isDark ? AppColors.goldBright : const Color(0xFF0D3B25))
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          fontWeight: activeIndex == 1 ? FontWeight.w800 : FontWeight.w500,
                          color: activeIndex == 1
                              ? (isDark ? AppColors.goldBright : const Color(0xFF0D3B25))
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. زر الإرسال الموحد
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubmitButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF135A38),
            Color(0xFF0A331E),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A331E).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.goldBright,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.goldBright, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.gold, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFD4E2D8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFD4E2D8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // معالجات العمليات (Sign In & Sign Up & Reset Password)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    if (!AppConfig.isConfigured) {
      _snack('قاعدة البيانات السحابية غير مهيأة', isError: true);
      return;
    }

    final email = _loginEmailController.text.trim();
    final isMaster = AppConfig.isMasterAdmin(email);

    setState(() => _busy = true);
    final notifier = ref.read(sessionProvider.notifier);
    final error = await notifier.signIn(
      email,
      _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    final session = ref.read(sessionProvider);

    if (session.isBanned) {
      _snack('حسابك محظور — يرجى مراجعة إدارة الموكب', isError: true);
      await notifier.signOut();
      return;
    }

    if (session.isPending && !isMaster) {
      context.go('/pending');
      return;
    }

    ref.read(loginAuditProvider.notifier).recordLogin(
          accountName: isMaster ? 'مدير النظام (البريد الأساسي)' : (session.profile?.fullName ?? 'مستخدم موثق'),
          emailOrPhone: email,
          roleName: isMaster ? 'مدير عام' : session.role.label,
          avatarUrl: session.profile?.avatarUrl,
          deviceInfo: 'تسجيل دخول موثق',
        );

    _snack(isMaster
        ? 'أهلاً بك يا مدير النظام، تم تسجيل الدخول بصلاحيات كاملة'
        : 'أهلاً بك، تم تسجيل الدخول بنجاح');
    context.go('/home');
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    if (!AppConfig.isConfigured) {
      _snack('قاعدة البيانات السحابية غير مهيأة', isError: true);
      return;
    }

    setState(() => _busy = true);
    final notifier = ref.read(sessionProvider.notifier);
    final fullName = _registerNameController.text.trim();
    final phone = _registerPhoneController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final isMaster = AppConfig.isMasterAdmin(email);

    final error = await notifier.signUp(
      email,
      password,
      fullName,
      phone: phone,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    if (!isMaster) {
      // تسجيل الطلب المعلق للمستخدمين العاديين
      final repo = ref.read(authRepositoryProvider);
      await repo.recordPendingRegistration(
        fullName: fullName,
        phone: phone,
        email: email,
      );

      ref.read(loginAuditProvider.notifier).recordLogin(
            accountName: fullName,
            emailOrPhone: phone.isNotEmpty ? phone : email,
            roleName: 'عضو (طلب جديد قيد الانتظار)',
            deviceInfo: 'طلب إنشاء حساب جديد',
          );

      if (!mounted) return;
      _snack('تم إنشاء الحساب بنجاح! طلبك قيد مراجعة المدير.');
      context.go('/pending');
    } else {
      ref.read(loginAuditProvider.notifier).recordLogin(
            accountName: fullName,
            emailOrPhone: phone.isNotEmpty ? phone : email,
            roleName: 'مدير عام (البريد الأساسي)',
            deviceInfo: 'إنشاء حساب مدير النظام الأساسي',
          );

      if (!mounted) return;
      _snack('مرحباً بك يا مدير النظام! تم تفعيل حسابك كمدير عام بنجاح.');
      context.go('/home');
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _loginEmailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.gold),
            SizedBox(width: 8),
            Text(
              'استعادة كلمة المرور',
              style: TextStyle(
                fontFamily: AppTheme.displayFamily,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً آمناً لإعادة تعيين كلمة المرور.',
              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.greenDeep),
            onPressed: () async {
              final em = emailCtrl.text.trim();
              if (em.isEmpty || !em.contains('@')) {
                _snack('يرجى كتابة بريد إلكتروني صحيح', isError: true);
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).resetPassword(em);
                _snack('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني');
              } catch (e) {
                _snack('تعذر إرسال الرابط: ${arabicError(e)}', isError: true);
              }
            },
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF108A4D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
