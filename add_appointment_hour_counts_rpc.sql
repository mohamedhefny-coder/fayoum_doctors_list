-- =====================================================
-- RPC: get booked counts by hour (safe for public)
-- Returns only (hour, booked_count) for a doctor + date.
-- Counts statuses: pending + accepted
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_appointment_hour_counts(
  p_doctor_id uuid,
  p_date date,
  p_clinic_id uuid DEFAULT NULL
)
RETURNS TABLE (
  hour smallint,
  booked_count integer
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    EXTRACT(HOUR FROM a.appointment_time)::smallint AS hour,
    COUNT(*)::integer AS booked_count
  FROM public.appointments a
  WHERE a.doctor_id = p_doctor_id
    AND a.appointment_date::date = p_date
    AND a.status IN ('pending', 'accepted')
    AND (
      (p_clinic_id IS NULL AND a.clinic_id IS NULL)
      OR (p_clinic_id IS NOT NULL AND a.clinic_id = p_clinic_id)
    )
  GROUP BY 1
  ORDER BY 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_appointment_hour_counts(uuid, date, uuid)
TO anon, authenticated;

-- Ask PostgREST (Supabase API) to reload schema (helps avoid PGRST2025 schema cache errors)
NOTIFY pgrst, 'reload schema';
