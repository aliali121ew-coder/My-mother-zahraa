import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawkib_zahra/core/data/supabase_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('اختبارات ترجمة أخطاء Supabase والمصادقة (arabicError)', () {
    test('يترجم أخطاء عدم تطابق بيانات تسجيل الدخول المختلفة بشكل صحيح', () {
      expect(
        arabicError(const AuthException('Invalid login credentials', statusCode: '400')),
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );

      expect(
        arabicError(const AuthException('Invalid credentials', code: 'invalid_credentials')),
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );

      expect(
        arabicError(const AuthException('invalid grant: Invalid email or password')),
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );

      expect(
        arabicError(const AuthException('User not found', code: 'user_not_found')),
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );
    });

    test('يترجم رسالة تأكيد البريد الإلكتروني', () {
      expect(
        arabicError(const AuthException('Email not confirmed', code: 'email_not_confirmed')),
        'يجب تأكيد البريد الإلكتروني أولاً عبر الرابط المرسل لبريدك',
      );
    });

    test('يترجم رسالة البريد المسجل مسبقاً', () {
      expect(
        arabicError(const AuthException('User already registered', code: 'user_already_exists')),
        'هذا البريد الإلكتروني مسجّل مسبقاً',
      );
    });

    test('يترجم ضعف كلمة المرور فقط عند وصول استثناء ضعف كلمة المرور الفعلي', () {
      expect(
        arabicError(const AuthException('Password should be at least 6 characters', code: 'weak_password')),
        'كلمة المرور ضعيفة — ٦ أحرف على الأقل',
      );

      expect(
        arabicError(const AuthException('Signup requires a valid password')),
        'كلمة المرور ضعيفة — ٦ أحرف على الأقل',
      );
    });

    test('يترجم تجاوز حد الطلبات', () {
      expect(
        arabicError(const AuthException('Too many requests, rate limit exceeded', code: 'over_request_rate_limit')),
        'محاولات كثيرة — يرجى الانتظار قليلاً وإعادة المحاولة',
      );
    });

    test('يترجم أخطاء الشبكة وانقطاع الإنترنت', () {
      expect(
        arabicError(const SocketException('Failed host lookup: nmpcbyoehmghmietzurs.supabase.co')),
        'لا يوجد اتصال بالإنترنت أو تعذر الوصول إلى الخادم السحابي',
      );
    });

    test('يترجم أخطاء صلاحيات RLS في PostgrestException', () {
      expect(
        arabicError(const PostgrestException(
          message: 'new row violates row-level security policy for table profiles',
          code: '42501',
        )),
        'حسابك الحالي لا يملك صلاحية مدير في السيرفر (RLS) — تأكد من تفعيل دور admin في جدول profiles',
      );
    });
  });
}
