import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/mawkib_logo.dart';

/// شاشة الدخول وإنشاء الحساب — تصميم احترافي بشريط تبديل منزلق.
///
/// شريط «تسجيل الدخول / إنشاء حساب» يحتوي مؤشرًا منزلقًا يتحرك بحركة
/// انزلاقية ناعمة عند التبديل، وتتحرك حقول النموذج معه بانزلاق متقابل
/// (يظهر حقل الاسم عند إنشاء حساب وينزلق خارجًا عند تسجيل الدخول).
///
/// الزائر يدخل لمشاهدة المنشورات، أما باقي الصلاحيات فيحددها المدير:
/// الموافقة على الحسابات، الأدوار، والحظر.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _slide = AnimationController(
    duration: const Duration(milliseconds: 380),
    vsync: this,
  );
  late final Animation<double> _indicator = CurvedAnimation(
    parent: _slide,
    curve: Curves.fastOutSlowIn,
  );
  bool _isRegister = false;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _slide.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _setMode(bool isRegister) {
    if (_isRegister == isRegister) return;
    setState(() => _isRegister = isRegister);
    _slide.forward(from: 0).then((_) => _slide.value = 0);
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
            icon: const Icon(Icons.close_rounded, color: AppColors.goldBright),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),

                  // ── شعار الموكب والعنوان ──────────────────────────
                  const Center(
                    child: MawkibLogo(height: 118, radius: 22),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'موكب أمنا الزهراء',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFamily,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.goldBright : AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أهلاً بك في التطبيق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: isDark ? AppColors.textOnDarkMuted : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── شريط التبديل المنزلق ──────────────────────────
                  _SlidingTabBar(
                    isRegister: _isRegister,
                    onToggle: _setMode,
                  ),
                  const SizedBox(height: 20),

                  // ── البطاقة الزجاجية والنموذج المنزلق ──────────────
                  GoldBorder(
                    width: 1.4,
                    child: GlassCard(
                      blur: true,
                      radius: AppTheme.radiusLarge,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // النموذج ينزلق يمينًا/يسارًا عند تبديل الوضع
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.15, 0),
                              end: Offset.zero,
                            ).animate(_indicator),
                            child: SizeFadeTransition(
                              controller: _slide,
                              isRegister: _isRegister,
                              nameController: _name,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) =>
                                (v == null ||
                                        !v.contains('@') ||
                                        !v.contains('.'))
                                    ? 'بريد إلكتروني غير صحيح'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'كلمة المرور ٦ أحرف على الأقل'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.goldDark,
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.goldDark),
                                    )
                                  : Text(
                                      _isRegister
                                          ? 'إنشاء الحساب'
                                          : 'دخول',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.goldDark,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => _setMode(!_isRegister),
                            child: Text(
                              _isRegister
                                  ? 'لديّ حساب — تسجيل الدخول'
                                  : 'ليس لديّ حساب — إنشاء حساب',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color:
                                    isDark ? AppColors.gold : AppColors.goldDark,
                              ),
                            ),
                          ),

                          // ── فاصل ثم زر الزائر ─────────────────────
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 15,
                                  color: AppColors.gold,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/posts'),
                            icon: const Icon(Icons.visibility_outlined,
                                size: 19, color: AppColors.goldBright),
                            label: const Text(
                              'الدخول كزائر لمشاهدة المنشورات',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: AppColors.goldBright,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                side: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'باقي الصلاحيات يحددها مدير الموكب بعد الموافقة على حسابك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5,
                      color: isDark ? AppColors.textOnDarkMuted : Colors.black45,
                    ),
                  ),

                  // تجربة الأدوار قبل إعداد Supabase
                  if (!AppConfig.isConfigured) ...[
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'وضع التجربة — قاعدة البيانات غير مهيّأة بعد',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in UserRole.values)
                          ActionChip(
                            label: Text(r.label),
                            avatar:
                                const Icon(Icons.login_rounded, size: 15),
                            onPressed: () {
                              ref.read(sessionProvider.notifier).demoSignIn(r);
                              context.go('/home');
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!AppConfig.isConfigured) {
      _snack('قاعدة البيانات غير مهيّأة — استخدم أزرار وضع التجربة أدناه');
      return;
    }

    setState(() => _busy = true);
    final notifier = ref.read(sessionProvider.notifier);
    final error = _isRegister
        ? await notifier.signUp(_email.text, _password.text, _name.text)
        : await notifier.signIn(_email.text, _password.text);

    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    final session = ref.read(sessionProvider);

    if (session.isBanned) {
      _snack('حسابك محظور — راجع إدارة الموكب', isError: true);
      await notifier.signOut();
      return;
    }

    // التسجيل ينجح لكن الحساب ينتظر موافقة المدير قبل رؤية أي رقم
    if (session.isPending) {
      context.go('/pending');
      return;
    }

    if (session.isGuest) {
      // نجح الدخول لكن لم يُقرأ الملف بعد (قد يتأخّر مشغّل قاعدة البيانات)
      _snack('تم الدخول. جارٍ تحميل حسابك…');
      await notifier.refresh();
      if (!mounted) return;
    }

    context.go('/home');
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.overdue : AppColors.greenMid,
          behavior: SnackBarBehavior.floating,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════
// شريط التبديل المنزلق — مؤشر ذهبي ينزلق بين التبويبَين
// ═══════════════════════════════════════════════════════════════════════
class _SlidingTabBar extends StatelessWidget {
  const _SlidingTabBar({required this.isRegister, required this.onToggle});

  final bool isRegister;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // عرض الشريط الداخلي بلا الحشو (4+4) ليغطي كل مساحة كبسولة واحدة
        final barWidth = constraints.maxWidth - 8;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1.1,
            ),
          ),
          child: Stack(
            children: [
              // المؤشر المنزلق — عرضه نصف الكبسولة تقريبًا
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 360),
                curve: Curves.fastOutSlowIn,
                end: isRegister ? 4 : null,
                top: 4,
                bottom: 4,
                left: isRegister ? null : 4,
                width: barWidth / 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // التبويبان
              Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'تسجيل الدخول',
                      active: !isRegister,
                      onTap: () => onToggle(false),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'إنشاء حساب',
                      active: isRegister,
                      onTap: () => onToggle(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 260),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active
                  ? AppColors.goldDark
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textOnDarkMuted
                      : Colors.black54),
            ),
            child: Text(label),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════
// النموذج المنزلق: حقل الاسم يظهر/يختفي بحركة انزلاق عند التبديل
// ═══════════════════════════════════════════════════════════════════════
class SizeFadeTransition extends StatelessWidget {
  const SizeFadeTransition({
    super.key,
    required this.controller,
    required this.isRegister,
    required this.nameController,
  });

  final AnimationController controller;
  final bool isRegister;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );
    return SizeTransition(
      sizeFactor: isRegister ? animation : const AlwaysStoppedAnimation(1),
      child: FadeTransition(
        opacity: isRegister ? animation : const AlwaysStoppedAnimation(1),
        child: SlideTransition(
          position: isRegister
              ? Tween<Offset>(
                  begin: const Offset(1.1, 0),
                  end: Offset.zero,
                ).animate(animation)
              : const AlwaysStoppedAnimation<Offset>(Offset.zero),
          child: isRegister
              ? TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'اكتب اسمك الكامل'
                      : null,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
