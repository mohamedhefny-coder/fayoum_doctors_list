-- Make most doctors fields optional; keep only specialization required.
-- Run this in Supabase Dashboard -> SQL Editor.
--
-- Why:
-- - Allow admin to create a doctor account with minimal profile.
-- - Let the doctor complete their profile later.
--
-- Notes:
-- - Keep using Supabase Auth for email/password login.
-- - To allow the doctor to edit their own profile under existing RLS policies,
--   ensure the row's `doctors.id` equals the Auth user UUID (auth.uid()).

begin;

-- 1) Drop NOT NULL constraints for fields you want to be optional.
--    Keep `specialization` as NOT NULL.
alter table public.doctors
  alter column email drop not null,
  alter column full_name drop not null,
  alter column phone drop not null,
  alter column license_number drop not null;

-- 2) (Recommended) Prevent blank specialization values like '' or '   '.
--    This keeps the UX aligned with "specialization required".
alter table public.doctors
  drop constraint if exists doctors_specialization_not_blank,
  add constraint doctors_specialization_not_blank
    check (length(trim(specialization)) > 0);

commit;

-- Optional sanity checks:
-- \d public.doctors
-- select column_name, is_nullable from information_schema.columns
-- where table_schema='public' and table_name='doctors'
-- order by ordinal_position;
