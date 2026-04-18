-- ============================================
-- Create medical_centers table + RLS policies
-- إنشاء جدول المراكز الطبية + سياسات الحماية
--
-- Run in Supabase Dashboard -> SQL Editor.
-- ملاحظة: يعتمد على وجود جدول public.admins (admin_setup.sql)
-- ============================================

begin;

create table if not exists public.medical_centers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  name text not null,
  address text,
  phone text,
  whatsapp text,

  working_hours text,
  geo_location text,
  facebook_page text,

  cover_image_url text,
  gallery_image_urls text[] default '{}'::text[],

  available_contracts text,
  offers_and_discounts text,

  has_booking boolean not null default false,

  is_published boolean not null default false,
  publish_requested boolean not null default false,
  published_at timestamp with time zone,

  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes
create index if not exists idx_medical_centers_user_id on public.medical_centers(user_id);
create index if not exists idx_medical_centers_is_published on public.medical_centers(is_published);
create index if not exists idx_medical_centers_publish_requested on public.medical_centers(publish_requested);

-- RLS
alter table public.medical_centers enable row level security;

-- Public/owner/admin read:
-- - Public: published centers only
-- - Owner: can read own row even if unpublished
-- - Admin: can read all
drop policy if exists "Public medical centers are viewable" on public.medical_centers;
create policy "Public medical centers are viewable"
  on public.medical_centers
  for select
  using (
    is_published = true
    or auth.uid() = user_id
    or exists (select 1 from public.admins a where a.id = auth.uid())
  );

-- Owners can insert their own row
drop policy if exists "Owners can insert their medical center" on public.medical_centers;
create policy "Owners can insert their medical center"
  on public.medical_centers
  for insert
  with check (
    auth.role() = 'authenticated'
    and auth.uid() = user_id
  );

-- Owners can update their own row
drop policy if exists "Owners can update their medical center" on public.medical_centers;
create policy "Owners can update their medical center"
  on public.medical_centers
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Owners can delete their own row
drop policy if exists "Owners can delete their medical center" on public.medical_centers;
create policy "Owners can delete their medical center"
  on public.medical_centers
  for delete
  using (auth.uid() = user_id);

-- Admin can update any row
drop policy if exists "Admins can update any medical center" on public.medical_centers;
create policy "Admins can update any medical center"
  on public.medical_centers
  for update
  using (exists (select 1 from public.admins a where a.id = auth.uid()));

-- Admin can delete any row
drop policy if exists "Admins can delete any medical center" on public.medical_centers;
create policy "Admins can delete any medical center"
  on public.medical_centers
  for delete
  using (exists (select 1 from public.admins a where a.id = auth.uid()));

commit;
