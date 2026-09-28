-- ระบบแจ้งหยุดงานเนื่องจากอุทกภัย
-- รันไฟล์นี้ครั้งเดียวใน Supabase Dashboard > SQL Editor

-- 1) ตารางคำขอ -------------------------------------------------------------
create table if not exists public.flood_leave_requests (
  id           uuid primary key,
  ref_code     text not null unique,
  full_name    text not null,
  emp_id       text not null,
  department   text not null,
  phone        text not null,
  date_from    date not null,
  date_to      date not null,
  days         int generated always as (date_to - date_from + 1) stored,
  causes       text[] not null default '{}',
  detail       text not null,
  area         text not null,
  water_level  text not null,
  photo_paths  text[] not null default '{}',
  status       text not null default 'pending'
               check (status in ('pending', 'approved', 'rejected')),
  review_note  text,
  reviewed_at  timestamptz,
  reviewed_by  text,
  created_at   timestamptz not null default now(),
  constraint date_order check (date_to >= date_from),
  constraint photo_count check (cardinality(photo_paths) between 1 and 6)
);

create index if not exists flood_leave_requests_created_idx
  on public.flood_leave_requests (created_at desc);

-- 2) รายชื่อผู้ตรวจ (HR) ----------------------------------------------------
create table if not exists public.hr_admins (
  email text primary key
);

create or replace function public.is_hr()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.hr_admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 3) สิทธิ์ (RLS) -----------------------------------------------------------
alter table public.flood_leave_requests enable row level security;
alter table public.hr_admins enable row level security;

revoke all on public.hr_admins from anon, authenticated;
revoke all on public.flood_leave_requests from anon, authenticated;
grant insert on public.flood_leave_requests to anon, authenticated;
grant select, update on public.flood_leave_requests to authenticated;

drop policy if exists "employees submit" on public.flood_leave_requests;
create policy "employees submit" on public.flood_leave_requests
  for insert to anon, authenticated
  with check (status = 'pending' and review_note is null
              and reviewed_at is null and reviewed_by is null);

drop policy if exists "hr read" on public.flood_leave_requests;
create policy "hr read" on public.flood_leave_requests
  for select to authenticated using (public.is_hr());

drop policy if exists "hr review" on public.flood_leave_requests;
create policy "hr review" on public.flood_leave_requests
  for update to authenticated using (public.is_hr()) with check (public.is_hr());

-- 4) ให้พนักงานเช็กสถานะด้วยเลขคำขอ + รหัสพนักงาน ---------------------------
create or replace function public.check_leave_status(p_ref text, p_emp_id text)
returns table (ref_code text, date_from date, date_to date, days int,
               status text, review_note text, created_at timestamptz)
language sql stable security definer
set search_path = ''
as $$
  select r.ref_code, r.date_from, r.date_to, r.days, r.status, r.review_note, r.created_at
  from public.flood_leave_requests r
  where upper(r.ref_code) = upper(trim(p_ref))
    and lower(r.emp_id) = lower(trim(p_emp_id));
$$;

revoke all on function public.check_leave_status(text, text) from public;
grant execute on function public.check_leave_status(text, text) to anon, authenticated;
revoke all on function public.is_hr() from public;
grant execute on function public.is_hr() to anon, authenticated;

-- 5) ที่เก็บรูปหลักฐาน (private) ---------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('flood-evidence', 'flood-evidence', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "flood evidence upload" on storage.objects;
create policy "flood evidence upload" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'flood-evidence');

drop policy if exists "flood evidence hr read" on storage.objects;
create policy "flood evidence hr read" on storage.objects
  for select to authenticated
  using (bucket_id = 'flood-evidence' and public.is_hr());

-- 6) เพิ่มอีเมล HR ที่มีสิทธิ์ตรวจ (แก้เป็นอีเมลจริง แล้วรันบรรทัดนี้) ---------
-- insert into public.hr_admins (email) values ('hr@yourcompany.com');
