-- =====================================================
-- إعادة إنشاء جدول الأسئلة من الصفر
-- =====================================================
-- هذا السكريبت يحذف الجدول القديم ويعيد إنشاءه بشكل صحيح

BEGIN;

-- 1. حذف الجدول القديم (إذا كان موجوداً)
DROP TABLE IF EXISTS public.doctor_questions CASCADE;

-- 2. إنشاء الجدول من جديد
CREATE TABLE public.doctor_questions (
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

-- 3. تفعيل RLS
ALTER TABLE public.doctor_questions ENABLE ROW LEVEL SECURITY;

-- 4. السياسة 1: أي شخص يمكنه إضافة سؤال (بدون تسجيل دخول)
CREATE POLICY "allow_anyone_insert"
  ON public.doctor_questions
  FOR INSERT
  WITH CHECK (true);

-- 5. السياسة 2: أي شخص يمكنه قراءة الأسئلة المُجاب عليها
CREATE POLICY "allow_anyone_read_answered"
  ON public.doctor_questions
  FOR SELECT
  USING (is_answered = true);

-- 6. السياسة 3: الطبيب يمكنه قراءة جميع أسئلته (بـ doctor_id)
CREATE POLICY "allow_doctor_read_all_by_id"
  ON public.doctor_questions
  FOR SELECT
  TO authenticated
  USING (doctor_id = auth.uid());

-- 7. السياسة 4: الطبيب يمكنه تحديث أسئلته (بـ doctor_id)
CREATE POLICY "allow_doctor_update_by_id"
  ON public.doctor_questions
  FOR UPDATE
  TO authenticated
  USING (doctor_id = auth.uid());

-- 8. السياسة 5: الطبيب يمكنه حذف أسئلته (بـ doctor_id)
CREATE POLICY "allow_doctor_delete_by_id"
  ON public.doctor_questions
  FOR DELETE
  TO authenticated
  USING (doctor_id = auth.uid());

-- 9. إنشاء indexes للأداء
CREATE INDEX idx_doctor_questions_doctor_id 
  ON public.doctor_questions(doctor_id);

CREATE INDEX idx_doctor_questions_is_answered 
  ON public.doctor_questions(is_answered);

CREATE INDEX idx_doctor_questions_created_at 
  ON public.doctor_questions(created_at DESC);

COMMIT;

-- =====================================================
-- التحقق
-- =====================================================

-- عرض الجدول
\d public.doctor_questions

-- عرض السياسات
SELECT 
  policyname,
  cmd,
  permissive,
  roles,
  CASE 
    WHEN qual IS NOT NULL THEN substring(qual::text, 1, 50) || '...'
    ELSE 'N/A'
  END as using_clause
FROM pg_policies
WHERE tablename = 'doctor_questions'
ORDER BY cmd, policyname;
