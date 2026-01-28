-- Fix doctor profile id mismatch: make public.doctors.id match the Auth user UUID.
-- Use this ONLY if a doctor can login but profile screen shows PGRST116/0 rows.
--
-- How to use:
-- 1) Get the Auth User UUID from Supabase Dashboard -> Authentication -> Users.
-- 2) Find the current (wrong) doctor row id in public.doctors (usually by email).
-- 3) Replace OLD_DOCTOR_ID and NEW_AUTH_USER_ID below.
--
-- Warning:
-- - If there are related rows in ratings/appointments/clinics, this script updates them too.
-- - Ensure NEW_AUTH_USER_ID is not already used as a doctors.id.

begin;

-- Replace these two values:
-- OLD_DOCTOR_ID: the existing doctors.id in public.doctors
-- NEW_AUTH_USER_ID: the UUID from Authentication

-- Example:
-- do $$
-- begin
--   perform 1;
-- end $$;

-- Safety checks
-- (1) New id must not exist
-- (2) Old id must exist

do $$
declare
  -- Put the UUIDs as TEXT first so we can validate and show a clear error
  -- instead of: invalid input syntax for type uuid: "OLD_DOCTOR_ID".
  old_id_text text := 'OLD_DOCTOR_ID';
  new_id_text text := 'NEW_AUTH_USER_ID';
  old_id uuid;
  new_id uuid;
  old_exists boolean;
  new_exists boolean;
begin
  if old_id_text = 'OLD_DOCTOR_ID' or new_id_text = 'NEW_AUTH_USER_ID' then
    raise exception
      'You must replace OLD_DOCTOR_ID and NEW_AUTH_USER_ID with real UUIDs before running this script.';
  end if;

  if old_id_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception 'OLD_DOCTOR_ID is not a valid UUID: %', old_id_text;
  end if;
  if new_id_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception 'NEW_AUTH_USER_ID is not a valid UUID: %', new_id_text;
  end if;

  old_id := old_id_text::uuid;
  new_id := new_id_text::uuid;

  select exists(select 1 from public.doctors where id = old_id) into old_exists;
  select exists(select 1 from public.doctors where id = new_id) into new_exists;

  if not old_exists then
    raise exception 'Old doctor id not found in public.doctors: %', old_id;
  end if;

  if new_exists then
    raise exception 'New auth user id already exists in public.doctors: %', new_id;
  end if;

  -- Update foreign keys first (if tables exist)
  if to_regclass('public.ratings') is not null then
    update public.ratings set doctor_id = new_id where doctor_id = old_id;
  end if;
  if to_regclass('public.appointments') is not null then
    update public.appointments set doctor_id = new_id where doctor_id = old_id;
  end if;
  if to_regclass('public.clinics') is not null then
    update public.clinics set doctor_id = new_id where doctor_id = old_id;
  end if;

  -- Update primary key
  update public.doctors set id = new_id where id = old_id;
end $$;

commit;
