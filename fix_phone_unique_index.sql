-- Fix unique constraint collisions on phone when phone is empty/null.
-- Run in Supabase Dashboard -> SQL Editor.
--
-- Symptom:
--   duplicate key value violates unique constraint "idx_doctors_phone_e164"
--
-- Root cause (common):
--   Existing rows have phone='' (empty string) and there is a UNIQUE index.
--   When creating another doctor without a phone, the DB ends up with '' again,
--   causing a duplicate.
--
-- What this script does:
-- 1) Convert empty/blank phone values to NULL.
-- 2) Remove any DEFAULT that might force '' into phone.
-- 3) Recreate idx_doctors_phone_e164 as a PARTIAL unique index:
--      unique only when phone is not null and not blank.

begin;

-- 0) Quick visibility (optional): current duplicates.
-- select phone, count(*)
-- from public.doctors
-- group by phone
-- having count(*) > 1;

-- 1) Normalize blanks to NULL.
update public.doctors
set phone = null
where phone is not null and length(trim(phone)) = 0;

-- Optional: if you also have the same issue on license_number.
update public.doctors
set license_number = null
where license_number is not null and length(trim(license_number)) = 0;

-- 2) Remove defaults that can reintroduce empty strings.
alter table public.doctors alter column phone drop default;
alter table public.doctors alter column license_number drop default;

commit;

-- 3) Recreate the index safely.
-- NOTE: CREATE INDEX CONCURRENTLY cannot run inside a transaction block.
-- If this fails because of permissions, run as project owner in SQL editor.

drop index if exists public.idx_doctors_phone_e164;

create unique index if not exists idx_doctors_phone_e164
on public.doctors (phone)
where phone is not null and length(trim(phone)) > 0;
