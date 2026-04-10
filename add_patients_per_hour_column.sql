-- =====================================================
-- Add patients-per-hour booking capacity for each doctor
-- =====================================================

ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS patients_per_hour integer NOT NULL DEFAULT 1;

-- Ask PostgREST (Supabase API) to reload schema (helps avoid PGRST2025 schema cache errors)
NOTIFY pgrst, 'reload schema';
