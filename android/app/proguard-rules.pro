# قواعد R8 لتطبيق موكب أمنا الزهراء

# Flutter وحزم الإضافات
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# local_auth — يستخدم BiometricPrompt عبر الانعكاس
-keep class androidx.biometric.** { *; }

# flutter_secure_storage
-keep class androidx.security.crypto.** { *; }

# printing / pdf — يستخدم PrintManager
-keep class android.print.** { *; }

# إزالة كل سجلات Android في الإصدار — لا تكشف شيئاً عن البيانات
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
