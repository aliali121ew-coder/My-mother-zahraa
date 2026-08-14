-- ════════════════════════════════════════════════════════════════════
--  تطبيق موكب أمنا الزهراء — مخطط قاعدة البيانات
--  Supabase / PostgreSQL
--
--  فلسفة الأمان: التطبيق **لا يُؤتمن عليه إطلاقاً**. كل صلاحية مفروضة
--  هنا على مستوى الصف (Row Level Security). لو فكّ أحدهم التطبيق واستخرج
--  مفتاح anon العلني، فلن يحصل على أكثر مما يحصل عليه أي زائر عادي.
--
--  طبقات الوصول:
--    anon (زائر بلا حساب)    → المنشورات والستوريز فقط
--    anonymous (إعجاب مجهول) → + الإعجاب على المنشورات
--    member معتمد            → + الإحصائيات المجمّعة، بلا أي أسماء
--    publisher               → + النشر ورفع الستوريز
--    finance                 → + قراءة القوائم والتقارير بالأسماء
--    admin                   → كل شيء + الموافقات والحظر والحذف
-- ════════════════════════════════════════════════════════════════════

create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────────────────────────
--  الأنواع (enums) — القيم مطابقة حرفياً لقيم enums في Dart
-- ─────────────────────────────────────────────────────────────────
do $$ begin
  create type user_role as enum ('admin', 'finance', 'publisher', 'member');
exception when duplicate_object then null; end $$;

do $$ begin
  create type user_status as enum ('pending', 'approved', 'rejected', 'banned');
exception when duplicate_object then null; end $$;

do $$ begin
  create type contributor_type as enum ('subscriber', 'donor', 'in_kind');
exception when duplicate_object then null; end $$;

do $$ begin
  create type subscription_type as enum ('monthly', 'yearly');
exception when duplicate_object then null; end $$;

do $$ begin
  create type donation_kind as enum ('cash', 'in_kind');
exception when duplicate_object then null; end $$;

-- ─────────────────────────────────────────────────────────────────
--  الجداول
-- ─────────────────────────────────────────────────────────────────

-- ملفات المستخدمين: مرتبطة بـ auth.users بنفس المعرّف
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default 'مستخدم',
  phone       text,
  avatar_url  text,
  role        user_role   not null default 'member',
  status      user_status not null default 'pending',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- المساهمون: مشتركون ومتبرعون وداعمون عينيون
create table if not exists public.contributors (
  id                  uuid primary key default gen_random_uuid(),
  type                contributor_type not null,
  full_name           text not null,
  phone               text,
  photo_url           text,
  notes               text,
  address             text,
  latest_donation_desc text,
  -- حقول الاشتراك: للمشتركين فقط
  subscription_amount numeric(14,0),
  subscription_type   subscription_type,
  -- تجاوز المدير اليدوي لحالة التأخير: null = اعتمد الحساب التلقائي
  is_late_override    boolean,
  -- محسوبة بمشغّلات (triggers) من جدولي الدفعات والتبرعات
  last_payment_at     timestamptz,
  total_paid          numeric(14,0) not null default 0,
  created_by          uuid references public.profiles(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  constraint subscriber_needs_plan check (
    type <> 'subscriber' or subscription_type is not null
  )
);

-- دفعات المشتركين: سجل كامل بالتواريخ + رقم وصل للطباعة
create table if not exists public.payments (
  id             uuid primary key default gen_random_uuid(),
  contributor_id uuid not null references public.contributors(id) on delete cascade,
  amount         numeric(14,0) not null check (amount > 0),
  paid_at        timestamptz not null default now(),
  receipt_number bigserial,
  note           text,
  recorded_by    uuid references public.profiles(id) on delete set null,
  created_at     timestamptz not null default now()
);

-- التبرعات: نقدية أو عينية. **العينية لا تدخل أي مجموع نقدي**
create table if not exists public.donations (
  id                 uuid primary key default gen_random_uuid(),
  contributor_id     uuid not null references public.contributors(id) on delete cascade,
  kind               donation_kind not null default 'cash',
  -- المبلغ مطلوب للنقدي وممنوع للعيني
  amount             numeric(14,0),
  in_kind_item       text,
  in_kind_quantity   text,
  -- تبرع باسم متوفّى (إهداء)
  dedication_name    text,
  donated_at         timestamptz not null default now(),
  receipt_number     bigserial,
  recorded_by        uuid references public.profiles(id) on delete set null,
  created_at         timestamptz not null default now(),
  constraint cash_needs_amount check (
    (kind = 'cash'    and amount is not null and amount > 0) or
    (kind = 'in_kind' and amount is null and in_kind_item is not null)
  )
);

-- المشتريات / المصروفات المالية
create table if not exists public.purchases (
  id            uuid primary key default gen_random_uuid(),
  item_name     text not null,
  amount        numeric(14,0) not null check (amount > 0),
  supplier_name text,
  notes         text,
  purchase_date timestamptz not null default now(),
  recorded_by   uuid references public.profiles(id) on delete set null,
  created_at    timestamptz not null default now()
);

-- المنشورات: عدة صور بتمرير أفقي + سنة للأرشيف
create table if not exists public.posts (
  id         uuid primary key default gen_random_uuid(),
  author_id  uuid references public.profiles(id) on delete set null,
  caption    text,
  year       int not null default extract(year from now()),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.post_images (
  id        uuid primary key default gen_random_uuid(),
  post_id   uuid not null references public.posts(id) on delete cascade,
  image_url text not null,
  thumb_url text,
  position  int not null default 0
);

-- الإعجاب: متاح للزائر عبر Anonymous Sign-in، مفتاح مركّب يمنع التكرار
create table if not exists public.post_likes (
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- التعليق: يتطلب حساباً حقيقياً (غير مجهول)
create table if not exists public.post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  body       text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.post_saves (
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.follows (
  follower_id  uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

-- أقسام الستوريز: ينشئها ويعدّلها المدير من داخل التطبيق
create table if not exists public.story_categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  cover_url  text,
  position   int not null default 0,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- الستوريز: للمصرّح لهم بالنشر فقط، والمدير يختار القسم
create table if not exists public.stories (
  id          uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.story_categories(id) on delete cascade,
  author_id   uuid references public.profiles(id) on delete set null,
  image_url   text not null,
  thumb_url   text,
  created_at  timestamptz not null default now(),
  -- null = تبقى دائماً في القسم (تعمل مثل Highlights لا مثل ستوري ٢٤ ساعة)
  expires_at  timestamptz
);

-- إشعارات المدير بقائمة المتأخرين وغيرها
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  body       text,
  kind       text not null default 'general',
  payload    jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────
--  الفهارس — القوائم تصل لآلاف الصفوف والبحث يجب أن يبقى فورياً
-- ─────────────────────────────────────────────────────────────────
create index if not exists idx_contributors_type
  on public.contributors(type) where deleted_at is null;
create index if not exists idx_contributors_name
  on public.contributors(full_name);
create index if not exists idx_contributors_phone
  on public.contributors(phone);
create index if not exists idx_contributors_total
  on public.contributors(total_paid desc) where deleted_at is null;
create index if not exists idx_payments_contributor
  on public.payments(contributor_id, paid_at desc);
create index if not exists idx_donations_contributor
  on public.donations(contributor_id, donated_at desc);
create index if not exists idx_donations_kind
  on public.donations(kind);
create index if not exists idx_purchases_date
  on public.purchases(purchase_date desc);
create index if not exists idx_posts_created
  on public.posts(created_at desc) where deleted_at is null;
create index if not exists idx_posts_year
  on public.posts(year, created_at desc) where deleted_at is null;
create index if not exists idx_post_images_post
  on public.post_images(post_id, position);
create index if not exists idx_comments_post
  on public.post_comments(post_id, created_at) where deleted_at is null;
create index if not exists idx_stories_category
  on public.stories(category_id, created_at desc);
create index if not exists idx_notifications_user
  on public.notifications(user_id, created_at desc) where read_at is null;

-- ─────────────────────────────────────────────────────────────────
--  دوال مساعدة
--
--  كلها SECURITY DEFINER لتتجاوز RLS عند قراءة جدول profiles، وإلا
--  لدخلنا في تكرار لا نهائي: سياسة على profiles تقرأ profiles.
-- ─────────────────────────────────────────────────────────────────

create or replace function public.my_role()
returns user_role language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_approved()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and status = 'approved'
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and status = 'approved' and role = 'admin'
  );
$$;

-- المدير أو المسؤول المالي: من يحق له قراءة الأسماء والتقارير
create or replace function public.can_read_names()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and status = 'approved'
      and role in ('admin', 'finance')
  );
$$;

create or replace function public.can_publish()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and status = 'approved'
      and role in ('admin', 'publisher')
  );
$$;

-- هل الجلسة الحالية مجهولة (Anonymous Sign-in)؟ تُستخدم لمنع
-- المجهولين من التعليق مع السماح لهم بالإعجاب.
create or replace function public.is_anon_session()
returns boolean language sql stable as $$
  select coalesce(
    (auth.jwt() -> 'is_anonymous')::boolean,
    false
  );
$$;

-- ─────────────────────────────────────────────────────────────────
--  مشغّلات (triggers)
-- ─────────────────────────────────────────────────────────────────

-- تحديث updated_at تلقائياً
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_profiles_touch on public.profiles;
create trigger trg_profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_contributors_touch on public.contributors;
create trigger trg_contributors_touch before update on public.contributors
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_posts_touch on public.posts;
create trigger trg_posts_touch before update on public.posts
  for each row execute function public.touch_updated_at();

-- إنشاء ملف تلقائياً عند تسجيل مستخدم جديد.
-- الحالة الافتراضية pending: **لا يرى شيئاً حتى يوافق المدير**.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- الجلسات المجهولة (للإعجاب فقط) لا تحتاج ملفاً
  if coalesce((new.raw_app_meta_data ->> 'provider') = 'anonymous', false) then
    return new;
  end if;
  insert into public.profiles (id, full_name, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'مستخدم'),
    'pending'
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- تحديث آخر دفعة والمجموع عند تسجيل دفعة
create or replace function public.sync_contributor_payments()
returns trigger language plpgsql security definer set search_path = public as $$
declare cid uuid;
begin
  cid := coalesce(new.contributor_id, old.contributor_id);
  update public.contributors c set
    last_payment_at = (
      select max(paid_at) from public.payments where contributor_id = cid
    ),
    total_paid = coalesce((
      select sum(amount) from public.payments where contributor_id = cid
    ), 0) + coalesce((
      select sum(amount) from public.donations
      where contributor_id = cid and kind = 'cash'
    ), 0),
    -- تسجيل دفعة جديدة يلغي تجاوز المدير اليدوي
    is_late_override = case when tg_op = 'INSERT' then null else c.is_late_override end
  where c.id = cid;
  return coalesce(new, old);
end $$;

drop trigger if exists trg_payments_sync on public.payments;
create trigger trg_payments_sync after insert or update or delete on public.payments
  for each row execute function public.sync_contributor_payments();

-- التبرع النقدي يُحدّث المجموع أيضاً؛ العيني لا يمسّه إطلاقاً
create or replace function public.sync_contributor_donations()
returns trigger language plpgsql security definer set search_path = public as $$
declare cid uuid;
begin
  cid := coalesce(new.contributor_id, old.contributor_id);
  update public.contributors set
    total_paid = coalesce((
      select sum(amount) from public.payments where contributor_id = cid
    ), 0) + coalesce((
      select sum(amount) from public.donations
      where contributor_id = cid and kind = 'cash'
    ), 0),
    last_payment_at = greatest(
      (select max(paid_at) from public.payments where contributor_id = cid),
      (select max(donated_at) from public.donations
       where contributor_id = cid and kind = 'cash')
    )
  where id = cid;
  return coalesce(new, old);
end $$;

drop trigger if exists trg_donations_sync on public.donations;
create trigger trg_donations_sync after insert or update or delete on public.donations
  for each row execute function public.sync_contributor_donations();

-- ─────────────────────────────────────────────────────────────────
--  دالة الإحصائيات المجمّعة
--
--  هذه هي الحيلة التي تسمح للعضو برؤية **الأرقام دون الأسماء**:
--  SECURITY DEFINER تتجاوز RLS داخلياً وتعيد مجاميع فقط، فلا يستطيع
--  العضو الوصول لأي صف باسم. التبرعات العينية تُعَدّ ولا تُجمَع.
-- ─────────────────────────────────────────────────────────────────
create or replace function public.get_stats()
returns json language plpgsql stable security definer set search_path = public as $$
declare result json;
begin
  if not public.is_approved() then
    raise exception 'غير مصرّح: الحساب غير معتمد';
  end if;

  select json_build_object(
    'subscriptions_total', coalesce((
      select sum(p.amount) from public.payments p
      join public.contributors c on c.id = p.contributor_id
      where c.deleted_at is null
    ), 0),
    'donations_total', coalesce((
      select sum(d.amount) from public.donations d
      join public.contributors c on c.id = d.contributor_id
      where d.kind = 'cash' and c.deleted_at is null
    ), 0),
    'expenses_total', coalesce((
      select sum(amount) from public.purchases
    ), 0),
    'subscribers_count', (
      select count(*) from public.contributors
      where type = 'subscriber' and deleted_at is null
    ),
    'donors_count', (
      select count(*) from public.contributors
      where type = 'donor' and deleted_at is null
    ),
    'in_kind_count', (
      select count(*) from public.donations d
      join public.contributors c on c.id = d.contributor_id
      where d.kind = 'in_kind' and c.deleted_at is null
    ),
    'overdue_count', (
      select count(*) from public.contributors
      where type = 'subscriber' and deleted_at is null and (
        case
          when is_late_override is not null then is_late_override
          when last_payment_at is null then true
          else now() - last_payment_at >
               (case subscription_type when 'monthly' then interval '30 days'
                                       else interval '365 days' end)
        end
      )
    ),
    'updated_at', now()
  ) into result;

  return result;
end $$;

revoke all on function public.get_stats() from public, anon;
grant execute on function public.get_stats() to authenticated;

-- ─────────────────────────────────────────────────────────────────
--  تفعيل RLS على كل الجداول
-- ─────────────────────────────────────────────────────────────────
alter table public.profiles         enable row level security;
alter table public.contributors     enable row level security;
alter table public.payments         enable row level security;
alter table public.donations        enable row level security;
alter table public.purchases        enable row level security;
alter table public.posts            enable row level security;
alter table public.post_images      enable row level security;
alter table public.post_likes       enable row level security;
alter table public.post_comments    enable row level security;
alter table public.post_saves       enable row level security;
alter table public.follows          enable row level security;
alter table public.story_categories enable row level security;
alter table public.stories          enable row level security;
alter table public.notifications    enable row level security;

-- ─────────────────────────────────────────────────────────────────
--  سياسات: profiles
-- ─────────────────────────────────────────────────────────────────
drop policy if exists profiles_read_self on public.profiles;
create policy profiles_read_self on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = auth.uid())
  -- المستخدم يعدّل بياناته لكن **لا يرفع دوره ولا يعتمد نفسه**
  with check (
    id = auth.uid()
    and role = (select role from public.profiles where id = auth.uid())
    and status = (select status from public.profiles where id = auth.uid())
  );

drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ─────────────────────────────────────────────────────────────────
--  سياسات: contributors / payments / donations / purchases
--  القراءة للمدير والمالي فقط. العضو يرى الأرقام عبر get_stats() لا هنا.
-- ─────────────────────────────────────────────────────────────────
drop policy if exists contributors_read on public.contributors;
create policy contributors_read on public.contributors
  for select to authenticated using (public.can_read_names() and deleted_at is null);

drop policy if exists contributors_write on public.contributors;
create policy contributors_write on public.contributors
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists payments_read on public.payments;
create policy payments_read on public.payments
  for select to authenticated using (public.can_read_names());

drop policy if exists payments_write on public.payments;
create policy payments_write on public.payments
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists donations_read on public.donations;
create policy donations_read on public.donations
  for select to authenticated using (public.can_read_names());

drop policy if exists donations_write on public.donations;
create policy donations_write on public.donations
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists purchases_read on public.purchases;
create policy purchases_read on public.purchases
  for select to authenticated using (public.can_read_names());

drop policy if exists purchases_write on public.purchases;
create policy purchases_write on public.purchases
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ─────────────────────────────────────────────────────────────────
--  سياسات: المنشورات — الزائر يقرأ بلا حساب
-- ─────────────────────────────────────────────────────────────────
drop policy if exists posts_read_all on public.posts;
create policy posts_read_all on public.posts
  for select to anon, authenticated using (deleted_at is null);

drop policy if exists posts_write on public.posts;
create policy posts_write on public.posts
  for all to authenticated using (public.can_publish()) with check (public.can_publish());

drop policy if exists post_images_read_all on public.post_images;
create policy post_images_read_all on public.post_images
  for select to anon, authenticated using (true);

drop policy if exists post_images_write on public.post_images;
create policy post_images_write on public.post_images
  for all to authenticated using (public.can_publish()) with check (public.can_publish());

-- الإعجاب: يقرأه الجميع، ويضيفه أي مستخدم مصادق **بما فيهم المجهول**
drop policy if exists likes_read_all on public.post_likes;
create policy likes_read_all on public.post_likes
  for select to anon, authenticated using (true);

drop policy if exists likes_insert_own on public.post_likes;
create policy likes_insert_own on public.post_likes
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists likes_delete_own on public.post_likes;
create policy likes_delete_own on public.post_likes
  for delete to authenticated using (user_id = auth.uid());

-- التعليق: يقرأه الجميع، ويكتبه **المسجّل غير المجهول** فقط
drop policy if exists comments_read_all on public.post_comments;
create policy comments_read_all on public.post_comments
  for select to anon, authenticated using (deleted_at is null);

drop policy if exists comments_insert on public.post_comments;
create policy comments_insert on public.post_comments
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and not public.is_anon_session()
    and public.is_approved()
  );

drop policy if exists comments_delete on public.post_comments;
create policy comments_delete on public.post_comments
  for delete to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists saves_own on public.post_saves;
create policy saves_own on public.post_saves
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists follows_read on public.follows;
create policy follows_read on public.follows
  for select to anon, authenticated using (true);

drop policy if exists follows_own on public.follows;
create policy follows_own on public.follows
  for all to authenticated
  using (follower_id = auth.uid()) with check (follower_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────
--  سياسات: الستوريز وأقسامها
-- ─────────────────────────────────────────────────────────────────
drop policy if exists story_cats_read_all on public.story_categories;
create policy story_cats_read_all on public.story_categories
  for select to anon, authenticated using (true);

drop policy if exists story_cats_admin on public.story_categories;
create policy story_cats_admin on public.story_categories
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists stories_read_all on public.stories;
create policy stories_read_all on public.stories
  for select to anon, authenticated
  using (expires_at is null or expires_at > now());

drop policy if exists stories_write on public.stories;
create policy stories_write on public.stories
  for all to authenticated using (public.can_publish()) with check (public.can_publish());

-- ─────────────────────────────────────────────────────────────────
--  سياسات: الإشعارات — كل مستخدم يرى إشعاراته فقط
-- ─────────────────────────────────────────────────────────────────
drop policy if exists notifications_own on public.notifications;
create policy notifications_own on public.notifications
  for select to authenticated using (user_id = auth.uid());

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists notifications_admin_insert on public.notifications;
create policy notifications_admin_insert on public.notifications
  for insert to authenticated with check (public.is_admin());

-- ─────────────────────────────────────────────────────────────────
--  التحديث الفوري (Realtime)
--  لتظهر أي إضافة أو تعديل عند الجميع بلا تحديث التطبيق
-- ─────────────────────────────────────────────────────────────────
do $$ begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.post_images;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.post_likes;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.post_comments;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.stories;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.contributors;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.purchases;
exception when duplicate_object then null; end $$;

-- ════════════════════════════════════════════════════════════════
--  ملاحظة تشغيلية مهمة — إنشاء أول مدير
--
--  أول مستخدم يسجّل سيكون status = 'pending' و role = 'member' ولن يرى
--  شيئاً. لجعله مديراً، نفّذ هذا في SQL Editor مرة واحدة بعد تسجيله:
--
--    update public.profiles
--       set role = 'admin', status = 'approved'
--     where id = (select id from auth.users where email = 'بريدك@هنا');
--
--  بعدها يستطيع هو الموافقة على بقية الحسابات من داخل التطبيق.
-- ════════════════════════════════════════════════════════════════
