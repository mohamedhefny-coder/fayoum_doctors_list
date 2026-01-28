-- Creates a normalized working hours table for doctor profiles
-- Run this in Supabase SQL Editor.
--
-- day_of_week: 0=Saturday, 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday

create table if not exists public.doctor_working_hours (
	doctor_id uuid not null references public.doctors (id) on delete cascade,
	day_of_week smallint not null check (day_of_week between 0 and 6),
	is_enabled boolean not null default false,
	start_time time,
	end_time time,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	primary key (doctor_id, day_of_week)
);

-- Notes are stored once per doctor (not per day)
alter table public.doctors
add column if not exists working_hours_notes text;

-- If an older version created per-day notes, remove it (safe to run multiple times)
alter table public.doctor_working_hours
drop column if exists notes;

alter table public.doctor_working_hours enable row level security;

-- Public can read working hours only for published doctors
drop policy if exists "Public can view published doctors working hours" on public.doctor_working_hours;
create policy "Public can view published doctors working hours"
on public.doctor_working_hours
for select
to anon, authenticated
using (
	exists (
		select 1
		from public.doctors d
		where d.id = doctor_working_hours.doctor_id
			and d.is_published = true
	)
);

-- Doctor can manage their own working hours
drop policy if exists "Doctor can manage own working hours" on public.doctor_working_hours;
create policy "Doctor can manage own working hours"
on public.doctor_working_hours
for all
to authenticated
using (doctor_id = auth.uid())
with check (doctor_id = auth.uid());

-- Admin can manage all working hours (requires public.admins with user_id)
drop policy if exists "Admin can manage working hours" on public.doctor_working_hours;
create policy "Admin can manage working hours"
on public.doctor_working_hours
for all
to authenticated
using (
	exists (
		select 1
		from public.admins a
		where a.user_id = auth.uid()
	)
)
with check (
	exists (
		select 1
		from public.admins a
		where a.user_id = auth.uid()
	)
);
