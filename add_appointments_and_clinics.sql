-- =====================================================
-- Appointments + Clinics tables for Supabase
-- - Creates `public.appointments` and `public.clinics`
-- - Enables RLS and adds policies
-- - Blocks appointment creation when doctor disabled booking
-- =====================================================

-- Ensure booking toggle column exists on doctors
ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS is_booking_enabled boolean NOT NULL DEFAULT true;

-- ===============
-- Appointments
-- ===============
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  patient_phone TEXT NOT NULL,
  appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
  appointment_time TIME NOT NULL,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Doctor can see their own appointments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'appointments'
      AND policyname = 'Doctors can see their appointments'
  ) THEN
    EXECUTE 'CREATE POLICY "Doctors can see their appointments" ON public.appointments FOR SELECT USING (doctor_id = auth.uid())';
  END IF;
END $$;

-- Anyone can create an appointment, but only if the doctor allows booking
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'appointments'
      AND policyname = 'Anyone can create an appointment when booking enabled'
  ) THEN
    EXECUTE 'CREATE POLICY "Anyone can create an appointment when booking enabled" ON public.appointments FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.doctors d WHERE d.id = doctor_id AND COALESCE(d.is_booking_enabled, true) = true))';
  END IF;
END $$;

-- Doctor can update their own appointments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'appointments'
      AND policyname = 'Doctors can update their appointments'
  ) THEN
    EXECUTE 'CREATE POLICY "Doctors can update their appointments" ON public.appointments FOR UPDATE USING (doctor_id = auth.uid()) WITH CHECK (doctor_id = auth.uid())';
  END IF;
END $$;

-- Optional: doctor can delete their own appointments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'appointments'
      AND policyname = 'Doctors can delete their appointments'
  ) THEN
    EXECUTE 'CREATE POLICY "Doctors can delete their appointments" ON public.appointments FOR DELETE USING (doctor_id = auth.uid())';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id
  ON public.appointments(doctor_id);

CREATE INDEX IF NOT EXISTS idx_appointments_date
  ON public.appointments(appointment_date);


-- ===============
-- Clinics
-- ===============
CREATE TABLE IF NOT EXISTS public.clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  clinic_name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;

-- Public can read clinics
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'clinics'
      AND policyname = 'Public clinics are viewable by all'
  ) THEN
    EXECUTE 'CREATE POLICY "Public clinics are viewable by all" ON public.clinics FOR SELECT USING (true)';
  END IF;
END $$;

-- Doctor can manage (insert/update/delete) their clinics
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'clinics'
      AND policyname = 'Doctors can manage their clinics'
  ) THEN
    EXECUTE 'CREATE POLICY "Doctors can manage their clinics" ON public.clinics FOR ALL USING (doctor_id = auth.uid()) WITH CHECK (doctor_id = auth.uid())';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_clinics_doctor_id
  ON public.clinics(doctor_id);


-- ===============
-- Doctor working hours (required by app)
-- ===============
-- day_of_week: 0=Saturday, 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday
CREATE TABLE IF NOT EXISTS public.doctor_working_hours (
  doctor_id uuid NOT NULL REFERENCES public.doctors (id) ON DELETE CASCADE,
  day_of_week smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  is_enabled boolean NOT NULL DEFAULT false,
  start_time time,
  end_time time,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (doctor_id, day_of_week)
);

-- Notes are stored once per doctor (not per day)
ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS working_hours_notes text;

-- If an older version created per-day notes, remove it
ALTER TABLE public.doctor_working_hours
DROP COLUMN IF EXISTS notes;

ALTER TABLE public.doctor_working_hours ENABLE ROW LEVEL SECURITY;

-- Public can read working hours only for published doctors
DROP POLICY IF EXISTS "Public can view published doctors working hours" ON public.doctor_working_hours;
CREATE POLICY "Public can view published doctors working hours"
  ON public.doctor_working_hours
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.doctors d
      WHERE d.id = doctor_working_hours.doctor_id
        AND d.is_published = true
    )
  );

-- Doctor can manage their own working hours
DROP POLICY IF EXISTS "Doctor can manage own working hours" ON public.doctor_working_hours;
CREATE POLICY "Doctor can manage own working hours"
  ON public.doctor_working_hours
  FOR ALL
  TO authenticated
  USING (doctor_id = auth.uid())
  WITH CHECK (doctor_id = auth.uid());

-- Ask PostgREST (Supabase API) to reload schema (helps avoid PGRST2025 schema cache errors)
NOTIFY pgrst, 'reload schema';
