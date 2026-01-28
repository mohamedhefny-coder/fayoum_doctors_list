-- Add publish workflow to doctors.
-- Run in Supabase Dashboard -> SQL Editor.
--
-- Behavior:
-- - Doctors can request publishing their page (publish_requested=true).
-- - Admin can approve (is_published=true).
-- - Public listing should show only published doctors.

begin;

alter table public.doctors
  add column if not exists is_published boolean not null default false,
  add column if not exists publish_requested boolean not null default false,
  add column if not exists published_at timestamp with time zone;

-- Optional: keep specialization not blank if you use that constraint.
alter table public.doctors
  drop constraint if exists doctors_specialization_not_blank,
  add constraint doctors_specialization_not_blank check (length(trim(specialization)) > 0);

-- Update SELECT policy to hide unpublished doctors from the public.
-- Allows:
-- - Public: published doctors only
-- - Doctor: can read own row even if unpublished
-- - Admin: can read all
alter table public.doctors enable row level security;

drop policy if exists "Public doctors are viewable by all" on public.doctors;

create policy "Public doctors are viewable by all"
  on public.doctors
  for select
  using (
    is_published = true
    or auth.uid() = id
    or exists (select 1 from public.admins a where a.id = auth.uid())
  );

commit;
