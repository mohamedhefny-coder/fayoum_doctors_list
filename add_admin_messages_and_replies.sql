-- Admin ↔ Doctor messaging tables (with doctor replies)
-- Run in Supabase Dashboard -> SQL Editor.
--
-- Notes:
-- - This is designed for the current app flow:
--   - Admin sends a message to a doctor (admin_messages)
--   - Doctor can reply back to the admin (admin_message_replies)
-- - Uses RLS so only the intended admin/doctor can access rows.

begin;

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------
-- 1) Messages from admin to doctor
-- ------------------------------------------------------------------
create table if not exists public.admin_messages (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  admin_id uuid not null references public.admins(id) on delete cascade,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_messages_doctor_id
  on public.admin_messages(doctor_id);
create index if not exists idx_admin_messages_admin_id
  on public.admin_messages(admin_id);
create index if not exists idx_admin_messages_created_at
  on public.admin_messages(created_at);

alter table public.admin_messages enable row level security;

-- Admins: full access to their messages
drop policy if exists "admins_select_admin_messages" on public.admin_messages;
create policy "admins_select_admin_messages"
  on public.admin_messages
  for select
  using (
    exists (select 1 from public.admins a where a.id = auth.uid())
  );

drop policy if exists "admins_insert_admin_messages" on public.admin_messages;
create policy "admins_insert_admin_messages"
  on public.admin_messages
  for insert
  with check (
    exists (select 1 from public.admins a where a.id = auth.uid())
    and admin_id = auth.uid()
  );

-- Doctors: can read messages addressed to them
drop policy if exists "doctors_select_own_admin_messages" on public.admin_messages;
create policy "doctors_select_own_admin_messages"
  on public.admin_messages
  for select
  using (doctor_id = auth.uid());

-- Doctors: can update (e.g., mark as read) their own messages
drop policy if exists "doctors_update_own_admin_messages" on public.admin_messages;
create policy "doctors_update_own_admin_messages"
  on public.admin_messages
  for update
  using (doctor_id = auth.uid())
  with check (doctor_id = auth.uid());

-- ------------------------------------------------------------------
-- 2) Replies from doctor back to admin
-- ------------------------------------------------------------------
create table if not exists public.admin_message_replies (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.admin_messages(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  admin_id uuid not null references public.admins(id) on delete cascade,
  reply text not null,
  is_read_by_admin boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_message_replies_message_id
  on public.admin_message_replies(message_id);
create index if not exists idx_admin_message_replies_doctor_id
  on public.admin_message_replies(doctor_id);
create index if not exists idx_admin_message_replies_admin_id
  on public.admin_message_replies(admin_id);
create index if not exists idx_admin_message_replies_created_at
  on public.admin_message_replies(created_at);

alter table public.admin_message_replies enable row level security;

-- Admins: can read replies sent to them
drop policy if exists "admins_select_admin_message_replies" on public.admin_message_replies;
create policy "admins_select_admin_message_replies"
  on public.admin_message_replies
  for select
  using (
    exists (select 1 from public.admins a where a.id = auth.uid())
    and admin_id = auth.uid()
  );

-- Admins: can mark replies as read
drop policy if exists "admins_update_admin_message_replies" on public.admin_message_replies;
create policy "admins_update_admin_message_replies"
  on public.admin_message_replies
  for update
  using (
    exists (select 1 from public.admins a where a.id = auth.uid())
    and admin_id = auth.uid()
  )
  with check (
    exists (select 1 from public.admins a where a.id = auth.uid())
    and admin_id = auth.uid()
  );

-- Doctors: can insert replies only for messages that belong to them
drop policy if exists "doctors_insert_admin_message_replies" on public.admin_message_replies;
create policy "doctors_insert_admin_message_replies"
  on public.admin_message_replies
  for insert
  with check (
    doctor_id = auth.uid()
    and exists (
      select 1
      from public.admin_messages m
      where m.id = message_id
        and m.doctor_id = auth.uid()
        and m.admin_id = admin_id
    )
  );

-- Doctors: can read their own replies (optional but useful)
drop policy if exists "doctors_select_own_admin_message_replies" on public.admin_message_replies;
create policy "doctors_select_own_admin_message_replies"
  on public.admin_message_replies
  for select
  using (doctor_id = auth.uid());

commit;
