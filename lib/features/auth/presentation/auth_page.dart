import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/enums.dart';

/// شاشة الدخول وإنشاء الحساب.
///
/// التسجيل ببريد وكلمة مرور، ثم **ينتظر موافقة المدير** قبل أن يرى
/// الإحصائيات. الزائر يستطيع تجاوز هذه الشاشة ومشاهدة المنشورات.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/logo/logo.png', height: 110)),
                  const SizedBox(height: 22),
                  Text(
                    _isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'بعد التسجيل ينتظر حسابك موافقة المدير'
                        : 'للوصول إلى الإحصائيات والقوائم',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'اكتب اسمك الكامل'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@') || !v.contains('.'))
                            ? 'بريد إلكتروني غير صحيح'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'كلمة المرور ٦ أحرف على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Text(_isRegister ? 'إنشاء الحساب' : 'دخول'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister
                        ? 'لديّ حساب — تسجيل الدخول'
                        : 'ليس لديّ حساب — إنشاء حساب'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/posts'),
                    icon: const Icon(Icons.visibility_outlined, size: 19),
                    label: const Text('الدخول كزائر لمشاهدة المنشورات'),
                  ),

                  // تجربة الأدوار قبل إعداد Supabase
                  if (!AppConfig.isConfigured) ...[
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 14),
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
                            avatar: const Icon(Icons.login_rounded, size: 15),
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
    // TODO(supabase): ربط signUp / signInWithPassword بعد تهيئة المشروع
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.greenMid,
        ),
      );
}
