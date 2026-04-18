-- ============================================
-- Add extra columns to public.medical_centers
-- إضافة أعمدة إضافية لجدول المراكز الطبية
--
-- Run in Supabase Dashboard -> SQL Editor.
-- ============================================

begin;

alter table if exists public.medical_centers
  add column if not exists booking_methods text[] default '{}'::text[];

alter table if exists public.medical_centers
  add column if not exists booking_url text;

alter table if exists public.medical_centers
  add column if not exists booking_notes text;

alter table if exists public.medical_centers
  add column if not exists booking_patients_per_hour integer;

alter table if exists public.medical_centers
  add column if not exists specialties text[] default '{}'::text[];

alter table if exists public.medical_centers
  add column if not exists services text[] default '{}'::text[];

alter table if exists public.medical_centers
  add column if not exists features text[] default '{}'::text[];

alter table if exists public.medical_centers
  add column if not exists doctors jsonb default '[]'::jsonb;

commit;
