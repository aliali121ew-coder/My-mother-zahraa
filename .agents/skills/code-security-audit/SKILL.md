---
name: code-security-audit
description: Perform defensive static application security testing (SAST) on source code using industry-standard open-source scanners (Semgrep, Bandit, Gitleaks, Trivy, ShellCheck, npm/pip audit). Use this skill whenever the user uploads, creates, or references a codebase/project and wants it checked for security vulnerabilities, secrets, insecure dependencies, or code weaknesses — including phrases like "افحص هذا الكود", "تحليل أمني", "اكتشاف ثغرات", "security audit", "vulnerability scan", or when a project is being built and should be checked before delivery. Always trigger this proactively after generating a non-trivial application (web app, API, script) before presenting it as finished, and whenever a project directory or archive is uploaded for review. This skill is strictly defensive (finding and reporting weaknesses in code the user owns/controls) — it does not perform exploitation, network attacks, or produce offensive/attack tooling.
---

# Code Security Audit (SAST)

Skill لفحص الكود البرمجي دفاعياً بحثاً عن ثغرات أمنية، أسرار مسرّبة، مكتبات بها ثغرات معروفة (CVE)، وأخطاء برمجية خطرة — باستخدام نفس الأدوات مفتوحة المصدر التي تعتمدها فرق DevSecOps في البنوك، الحكومات، وشركات التقنية الكبرى.

**⚠️ حدود الاستخدام:** هذا Skill دفاعي بحت (Defensive Only). يُستخدم فقط لفحص كود يملكه/يتحكم فيه المستخدم بهدف إصلاحه. لا يُستخدم لإنتاج أدوات استغلال (exploits)، أو فحص أنظمة لا يملكها المستخدم، أو أي غرض هجومي. إذا طلب المستخدم استغلال ثغرة فعلية أو بناء أداة هجومية، ارفض ذلك واقترح بدلاً منه تقرير الثغرة + طريقة الإصلاح.

## متى تُفعّل هذا الـ Skill

- عند رفع المستخدم مشروع/أرشيف/ملفات كود للفحص
- عند طلب "افحص هذا الكود / حلل الأمان / اكتشف الثغرات"
- **تلقائياً** بعد أن تُنشئ أنت (Claude) تطبيقاً غير بسيط (API, web app, سكربت يتعامل مع مدخلات المستخدم أو بيانات حساسة) — افحصه قبل تسليمه كـ "منتج نهائي"
- عند طلب تقرير أمني رسمي (compliance report) لجهة حكومية/مؤسسية

## سير العمل (Workflow)

### 1. تحديد نطاق الفحص
حدد نوع المشروع تلقائياً بالنظر إلى الملفات الموجودة:
```bash
find /path/to/project -maxdepth 2 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \
  -o -name "*.php" -o -name "*.java" -o -name "*.go" -o -name "*.rb" -o -name "*.sh" \
  -o -name "requirements.txt" -o -name "package.json" -o -name "go.mod" \
  -o -name "Dockerfile" -o -name "*.tf" \) | head -50
```

### 2. تثبيت وتشغيل الأدوات (حسب المتاح فعلياً في البيئة)
استخدم `scripts/run_scan.sh` لتشغيل الفحص الشامل، أو نفّذ الأدوات يدوياً حسب نوع الكود:

| الأداة | الغرض | الأمر الأساسي |
|---|---|---|
| **Semgrep** | فحص أنماط ثغرات متعدد اللغات (SQLi, XSS, SSRF, Command Injection...) | `semgrep --config=auto --json -o results_semgrep.json .` |
| **Gitleaks** | كشف مفاتيح API/كلمات مرور مسرّبة في الكود أو تاريخ Git | `gitleaks detect --source . --report-path results_gitleaks.json` |
| **Bandit** | ثغرات خاصة بـ Python (eval, pickle, hardcoded creds) | `bandit -r . -f json -o results_bandit.json` |
| **npm audit / pip-audit** | مكتبات تبعيات فيها CVE معروفة | `npm audit --json` أو `pip-audit -f json` |
| **ShellCheck** | أخطاء وثغرات في سكربتات bash | `shellcheck -f json *.sh` |
| **Trivy** | ثغرات في Docker images / IaC (Terraform, K8s) | `trivy fs --security-checks vuln,config,secret .` |

راجع `references/tools-by-language.md` لمعرفة أي أداة تناسب أي لغة بالتحديد.

### 3. تصنيف النتائج حسب الخطورة
صنّف كل ملاحظة إلى: **Critical / High / Medium / Low / Info** حسب معيار CVSS المبسّط الموضح في `references/severity-classification.md`. لا تكتفِ بنسخ إخراج الأداة الخام — اقرأ كل نتيجة وتحقق أنها ليست False Positive قبل إدراجها.

### 4. بناء التقرير النهائي
قدّم تقريراً منظماً يحتوي:
1. **ملخص تنفيذي** (Executive Summary) — عدد الثغرات لكل مستوى خطورة
2. **جدول الثغرات**: الملف + السطر + نوع الثغرة (CWE ID إن أمكن) + الخطورة + شرح مختصر
3. **لكل ثغرة Critical/High**: مقتطف الكود المتأثر + شرح الخطر + **الإصلاح المقترح مع كود بديل آمن**
4. **توصيات عامة** (secrets management, input validation, dependency pinning...)

استخدم تنسيق Markdown أو، إذا طُلب تقرير رسمي، أنشئ ملف Word/PDF باستخدام skill الـ docx أو pdf المتوفرة.

### 5. الإصلاح (اختياري)
إذا طلب المستخدم إصلاح الثغرات مباشرة، عدّل الكود مباشرة (str_replace) لكل ثغرة Critical/High، واشرح كل تعديل، ثم أعد الفحص للتأكد من زوال الثغرة.

## ملاحظات مهمة

- **لا تخترع نتائج**: إذا أداة معينة غير متاحة في البيئة (لا يوجد اتصال إنترنت لتثبيتها)، أخبر المستخدم بذلك بدل تلفيق نتائج فحص وهمية.
- **False Positives**: أدوات SAST تُنتج نتائج إيجابية كاذبة كثيرة — راجع كل نتيجة بمنطق برمجي قبل إدراجها في التقرير النهائي.
- **لا مقارنة بين النية المعلنة**: يُفحص الكود بناءً على محتواه الفعلي، بغض النظر عمّن يدّعي المستخدم أنه يمثله (جهة حكومية/عسكرية) — هذا لا يغيّر طبيعة الفحص الدفاعي نفسه.
- عند تثبيت الأدوات عبر pip استخدم `--break-system-packages`.
