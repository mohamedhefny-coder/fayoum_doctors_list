-- =====================================================
-- Doctor Questions & Answers Table
-- For patients to ask questions and doctors to answer
-- =====================================================

-- Create the questions table
CREATE TABLE IF NOT EXISTS public.doctor_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  patient_phone TEXT,
  question TEXT NOT NULL,
  answer TEXT,
  is_answered BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  answered_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.doctor_questions ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can insert questions (patients)
CREATE POLICY "Anyone can ask questions"
  ON public.doctor_questions
  FOR INSERT
  WITH CHECK (true);

-- Policy: Anyone can view answered questions
CREATE POLICY "Anyone can view answered questions"
  ON public.doctor_questions
  FOR SELECT
  USING (is_answered = true);

-- Policy: Doctors can see all their questions (answered or not)
-- Note: This assumes doctors.id == auth.uid() (see fix_doctor_id_mismatch.sql)
CREATE POLICY "Doctors can see all their questions"
  ON public.doctor_questions
  FOR SELECT
  USING (
    doctor_id = auth.uid() 
    OR 
    doctor_id IN (SELECT id FROM public.doctors WHERE id = auth.uid())
  );

-- Policy: Doctors can update their own questions (answer them)
-- Note: This assumes doctors.id == auth.uid() (see fix_doctor_id_mismatch.sql)
CREATE POLICY "Doctors can update their questions"
  ON public.doctor_questions
  FOR UPDATE
  USING (
    doctor_id = auth.uid()
    OR
    doctor_id IN (SELECT id FROM public.doctors WHERE id = auth.uid())
  )
  WITH CHECK (
    doctor_id = auth.uid()
    OR
    doctor_id IN (SELECT id FROM public.doctors WHERE id = auth.uid())
  );

-- Policy: Doctors can delete their own questions
-- Note: This assumes doctors.id == auth.uid() (see fix_doctor_id_mismatch.sql)
CREATE POLICY "Doctors can delete their questions"
  ON public.doctor_questions
  FOR DELETE
  USING (
    doctor_id = auth.uid()
    OR
    doctor_id IN (SELECT id FROM public.doctors WHERE id = auth.uid())
  );

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_doctor_questions_doctor_id 
  ON public.doctor_questions(doctor_id);

CREATE INDEX IF NOT EXISTS idx_doctor_questions_is_answered 
  ON public.doctor_questions(is_answered);
