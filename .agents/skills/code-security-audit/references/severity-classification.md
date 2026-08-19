# تصنيف مستوى الخطورة (Severity Classification)

معيار مبسّط مبني على CVSS + منطق التأثير العملي. استخدمه لتصنيف كل نتيجة فحص قبل إدراجها في التقرير.

## Critical (حرج)
- تنفيذ كود عن بُعد (RCE) بدون مصادقة
- SQL Injection يسمح بالوصول/تعديل كامل قاعدة البيانات
- أسرار حقيقية مسرّبة (production API keys, DB passwords) وقابلة للاستخدام فوراً
- Authentication Bypass كامل
- Deserialization غير آمن لبيانات من مصدر خارجي (pickle, yaml.load بدون safe_load)

## High (عالي)
- SSRF يسمح بالوصول لموارد داخلية (internal network, cloud metadata endpoint)
- XSS مخزّن (Stored XSS) في تطبيق يتعامل مع بيانات حساسة
- Path Traversal / LFI يسمح بقراءة ملفات نظام حساسة
- استخدام تشفير ضعيف لبيانات حساسة (MD5/SHA1 لكلمات المرور بدون salt)
- Command Injection عبر مدخلات غير معقّمة (حتى لو محدود الأثر)
- مكتبة تبعية بها CVE معروف بدرجة CVSS ≥ 7.0

## Medium (متوسط)
- XSS منعكس (Reflected XSS) يحتاج تفاعل المستخدم
- CSRF بدون حماية token في عمليات حساسة
- معلومات حساسة في رسائل الخطأ (stack traces, DB schema)
- Rate limiting غائب على endpoints حساسة (login, password reset)
- استخدام HTTP بدل HTTPS لنقل بيانات حساسة
- Hardcoded credentials في كود تطوير/اختبار (غير production)

## Low (منخفض)
- Missing security headers (CSP, X-Frame-Options, HSTS)
- Verbose logging يكشف معلومات غير حرجة
- كود ميت أو تعليقات تحتوي TODO أمنية
- ضعف بسيط في سياسة كلمات المرور (لا يوجد حد أدنى للطول)

## Info (معلوماتي)
- ملاحظات best-practice لا تشكل ثغرة فعلية (تنظيم كود، توثيق ناقص)

---

## معايير تقييم الـ False Positive
قبل تصنيف أي نتيجة، تحقق:
1. هل المدخل فعلاً قادم من مصدر غير موثوق (user input, external API)، أم من مصدر ثابت داخل الكود؟
2. هل يوجد تعقيم/validation في مكان آخر بالتدفق البرمجي (upstream) يُبطل الثغرة؟
3. هل السياق فعلي (production code) أم كود اختبار/تجريبي لا يُنشر؟

نتيجة الأداة الخام (raw tool output) ليست تقريراً نهائياً — هي مدخلات تحتاج مراجعة بشرية/منطقية قبل العرض على المستخدم.
