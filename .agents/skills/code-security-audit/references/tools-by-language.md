# الأدوات حسب لغة/نوع المشروع

مرجع سريع لاختيار الأداة المناسبة، مع أوامر التثبيت (pip يحتاج `--break-system-packages` في هذه البيئة).

## عام / متعدد اللغات
- **Semgrep** — التغطية الأوسع (Python, JS/TS, Java, Go, PHP, Ruby, C/C++...)
  تثبيت: `pip install semgrep --break-system-packages`
  فحص: `semgrep --config=auto .`
  ملاحظة: `--config=auto` يحتاج اتصال إنترنت لجلب قواعد OWASP Top 10 المحدّثة. إن لم يتوفر، استخدم `--config=p/security-audit` من قواعد مضمّنة محلياً إن وُجدت.

- **Gitleaks** — كشف الأسرار (API keys, tokens, passwords) في الكود وسجل Git
  تثبيت: عبر Go `go install github.com/gitleaks/gitleaks/v8@latest` أو تنزيل binary من GitHub Releases
  فحص: `gitleaks detect --source . --no-git`

- **TruffleHog** — بديل/مكمّل لـ Gitleaks، يتحقق من صلاحية الأسرار المكتشفة فعلياً (verified secrets)

## Python
- **Bandit** — ثغرات شائعة: `eval()`, `pickle.loads()`, `subprocess` بدون تعقيم, hardcoded passwords, weak crypto (MD5/SHA1)
  تثبيت: `pip install bandit --break-system-packages`
  فحص: `bandit -r . -ll` (يعرض Medium فأعلى فقط)
- **pip-audit** — ثغرات CVE في مكتبات requirements.txt
  تثبيت: `pip install pip-audit --break-system-packages`

## JavaScript / TypeScript / Node
- **npm audit** — مدمج مع npm، يفحص package-lock.json مقابل قاعدة بيانات الثغرات
- **ESLint + eslint-plugin-security** — لثغرات النمط البرمجي (unsafe regex, eval usage)
- **Semgrep** يغطي XSS, prototype pollution, SSRF بشكل جيد لـ Node/Express

## PHP
- **Semgrep** (قواعد PHP مدمجة) — SQLi, LFI/RFI, unsafe deserialization
- **PHPStan / Psalm** بمستوى صرامة عالٍ يكشف أخطاء type-safety قد تتحول لثغرات

## Java
- **Semgrep** + **SpotBugs (مع FindSecBugs plugin)** — deserialization ثغرات, XXE, SQLi عبر JDBC
- **OWASP Dependency-Check** — CVE في ملفات pom.xml / Maven dependencies

## Go
- **gosec** — `gosec ./...` يكشف command injection, weak random, hardcoded creds
- **govulncheck** (رسمي من فريق Go) — CVE في module dependencies

## Ruby
- **Brakeman** — مخصص لـ Rails، يكشف SQLi, mass assignment, XSS بدقة عالية

## Bash / Shell
- **ShellCheck** — أخطاء quoting تؤدي لـ injection, unsafe eval, race conditions

## Docker / Kubernetes / Terraform (IaC)
- **Trivy** — الأشمل: ثغرات في base images + misconfigurations + أسرار مضمّنة
- **Checkov** — بديل جيد لفحص Terraform/CloudFormation/K8s manifests
- **Hadolint** — Linting مخصص لملفات Dockerfile (best practices أمنية)

## عند عدم توفر اتصال إنترنت لتثبيت أداة
أخبر المستخدم صراحة أن الأداة غير متاحة في هذه الجلسة بدل تلفيق نتائج. يمكن الاستمرار بالأدوات المتاحة فعلاً وذكر الفجوة في التقرير النهائي تحت "Scope Limitations".
