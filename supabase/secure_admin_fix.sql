-- ════════════════════════════════════════════════════════════════
--  سكربت إغلاق الثغرة الأمنية: إزالة البريد المضمّن للمدير العام
--
--  طريقة التنفيذ:
--  1. افتح Supabase Dashboard → SQL Editor
--  2. الصق محتوى هذا الملف كاملاً واضغط Run
--
--  آمن للتشغيل المتكرر ولا يمس أدوار أي حساب موجود.
-- ════════════════════════════════════════════════════════════════

-- 1) النسخة الآمنة من الدالة: بلا أي استثناء لأي بريد
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if coalesce((new.raw_app_meta_data ->> 'provider') = 'anonymous', false) then
    return new;
  end if;

  insert into public.profiles (id, full_name, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'مستخدم'),
    'member'::public.user_role,
    'pending'::public.user_status
  )
  on conflict (id) do update set
    full_name = coalesce(new.raw_user_meta_data ->> 'full_name', public.profiles.full_name);

  return new;
end $$;

-- 2) التأكد من ربط المشغّل بالنسخة الجديدة
drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3) تحقق: من هم المدراء الحاليون؟
select id, full_name, email, role, status, created_at
from public.profiles
where role = 'admin' and status = 'approved'
order by created_at;

-- ════════════════════════════════════════════════════════════════
--  سطر الطوارئ (لا تنفّذه الآن — احتفظ به)
--  إذا فقدت حساب المدير مستقبلاً: سجّل حساباً جديداً بالتطبيق
--  ثم نفّذ هذا السطر مرة واحدة بعد استبدال البريد:
--
--    update public.profiles
--       set role = 'admin', status = 'approved'
--     where id = (select id from auth.users where email = 'بريدك-الجديد@هنا');
-- ════════════════════════════════════════════════════════════════
