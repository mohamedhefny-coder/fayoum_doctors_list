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
  clinic_id UUID,
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

-- Ensure clinic_id exists for older installs before creating policies
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS clinic_id UUID;

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
-- (Clinic validation is added later, after clinics table exists)
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

CREATE INDEX IF NOT EXISTS idx_appointments_clinic_id
  ON public.appointments(clinic_id);


-- ===============
-- Clinics
-- ===============
CREATE TABLE IF NOT EXISTS public.clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  clinic_name TEXT NOT NULL DEFAULT 'عيادة',
  center TEXT,
  address TEXT NOT NULL,
  geo_location TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Ensure new clinic fields exist (for older installs)
ALTER TABLE public.clinics
ADD COLUMN IF NOT EXISTS center TEXT;

ALTER TABLE public.clinics
ADD COLUMN IF NOT EXISTS geo_location TEXT;

ALTER TABLE public.clinics
ALTER COLUMN clinic_name SET DEFAULT 'عيادة';

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

-- Strengthen appointment insert policy to validate clinic_id (after clinics exists)
DROP POLICY IF EXISTS "Anyone can create an appointment when booking enabled" ON public.appointments;
CREATE POLICY "Anyone can create an appointment when booking enabled"
  ON public.appointments
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.doctors d
      WHERE d.id = doctor_id
        AND COALESCE(d.is_booking_enabled, true) = true
    )
    AND (
      clinic_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.clinics c
        WHERE c.id = clinic_id
          AND c.doctor_id = doctor_id
      )
    )
  );

-- Add FK for clinic_id (safe to run multiple times)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'appointments_clinic_id_fkey'
  ) THEN
    ALTER TABLE public.appointments
      ADD CONSTRAINT appointments_clinic_id_fkey
      FOREIGN KEY (clinic_id)
      REFERENCES public.clinics(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- Notes per clinic (independent schedule notes)
ALTER TABLE public.clinics
ADD COLUMN IF NOT EXISTS working_hours_notes text;


-- ===============
-- Clinic working hours (per clinic)
-- ===============
-- day_of_week: 0=Saturday, 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday
CREATE TABLE IF NOT EXISTS public.clinic_working_hours (
  clinic_id uuid NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  day_of_week smallint NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  is_enabled boolean NOT NULL DEFAULT false,
  start_time time,
  end_time time,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (clinic_id, day_of_week)
);

ALTER TABLE public.clinic_working_hours ENABLE ROW LEVEL SECURITY;

-- Public can read clinic working hours only for published doctors
DROP POLICY IF EXISTS "Public can view published clinics working hours" ON public.clinic_working_hours;
CREATE POLICY "Public can view published clinics working hours"
  ON public.clinic_working_hours
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.clinics c
      JOIN public.doctors d ON d.id = c.doctor_id
      WHERE c.id = clinic_working_hours.clinic_id
        AND d.is_published = true
    )
  );

-- Doctor can manage working hours for their own clinics
DROP POLICY IF EXISTS "Doctor can manage own clinics working hours" ON public.clinic_working_hours;
CREATE POLICY "Doctor can manage own clinics working hours"
  ON public.clinic_working_hours
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.clinics c
      WHERE c.id = clinic_working_hours.clinic_id
        AND c.doctor_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.clinics c
      WHERE c.id = clinic_working_hours.clinic_id
        AND c.doctor_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_clinic_working_hours_clinic_id
  ON public.clinic_working_hours(clinic_id);


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
