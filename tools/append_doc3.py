import os

doc_path = os.path.join(os.path.dirname(__file__), '..', 'CLAUDE (1).md')

text_to_append = """
4. **حل تعارض قفل ملفات المكتبات الثنائية (libflutter.so lock):**
   - تم تنظيف المجلد المؤقت `build` وإنهاء جميع العمليات الحابسة للملفات، لتجاوز خطأ `FileSystemException: The process cannot access the file because it is being used by another process`.
"""

with open(doc_path, 'a', encoding='utf-8') as f:
    f.write(text_to_append)

print("DOCUMENTATION_UPDATED_SUCCESSFULLY_3")
