-- =====================================================
-- إصلاح شامل لجدول الأسئلة والاستفسارات
-- =====================================================
-- هذا السكريبت يحذف كل شيء ويعيد إنشاءه من الصفر

BEGIN;

-- 1. حذف السياسات القديمة
DROP POLICY IF EXISTS "Anyone can ask questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Anyone can view answered questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can see all their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can update their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can delete their questions" ON public.doctor_questions;

-- 2. تعطيل RLS مؤقتاً
ALTER TABLE public.doctor_questions DISABLE ROW LEVEL SECURITY;

-- 3. إعادة تفعيل RLS
ALTER TABLE public.doctor_questions ENABLE ROW LEVEL SECURITY;

-- 4. إنشاء السياسات الجديدة المحسّنة

-- سياسة 1: أي شخص يمكنه إضافة سؤال (بدون تسجيل دخول)
CREATE POLICY "enable_insert_for_all"
  ON public.doctor_questions
  FOR INSERT
  TO public
  WITH CHECK (true);

-- سياسة 2: أي شخص يمكنه رؤية الأسئلة المُجاب عليها
CREATE POLICY "enable_select_answered_for_all"
  ON public.doctor_questions
  FOR SELECT
  TO public
  USING (is_answered = true);

-- سياسة 3: الأطباء يمكنهم رؤية جميع أسئلتهم
CREATE POLICY "enable_select_all_for_doctors"
  ON public.doctor_questions
  FOR SELECT
  TO authenticated
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- سياسة 4: الأطباء يمكنهم تحديث (الإجابة على) أسئلتهم
CREATE POLICY "enable_update_for_doctors"
  ON public.doctor_questions
  FOR UPDATE
  TO authenticated
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- سياسة 5: الأطباء يمكنهم حذف أسئلتهم
CREATE POLICY "enable_delete_for_doctors"
  ON public.doctor_questions
  FOR DELETE
  TO authenticated
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

COMMIT;

-- =====================================================
-- التحقق من السياسات الجديدة
-- =====================================================
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'doctor_questions'
ORDER BY policyname;
