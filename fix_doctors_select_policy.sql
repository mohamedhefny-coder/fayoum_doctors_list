-- Fix/restore SELECT policy for public.doctors under RLS.
-- Run in Supabase Dashboard -> SQL Editor.
--
-- Symptom:
-- - App shows errors like PGRST116 (0 rows) or duplicate key on doctors_pkey
--   when trying to auto-create/read the doctor profile.
-- - This often means SELECT is blocked by RLS policies.

begin;

alter table public.doctors enable row level security;

-- Drop potentially conflicting policies with the same name (safe if not exists).
drop policy if exists "Public doctors are viewable by all" on public.doctors;

-- Option A (simple): allow anyone to read doctors (matches the repo schema).
create policy "Public doctors are viewable by all"
  on public.doctors
  for select
  using (true);

commit;
