-- =====================================================
-- إصلاح نهائي لسياسات RLS - جدول الأسئلة
-- =====================================================
-- المشكلة: permission denied for table users
-- الحل: استخدام auth.email() بدلاً من الوصول المباشر لـ auth.users

BEGIN;

-- حذف جميع السياسات القديمة
DROP POLICY IF EXISTS "Anyone can ask questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Anyone can view answered questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can see all their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can update their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can delete their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "enable_insert_for_all" ON public.doctor_questions;
DROP POLICY IF EXISTS "enable_select_answered_for_all" ON public.doctor_questions;
DROP POLICY IF EXISTS "enable_select_all_for_doctors" ON public.doctor_questions;
DROP POLICY IF EXISTS "enable_update_for_doctors" ON public.doctor_questions;
DROP POLICY IF EXISTS "enable_delete_for_doctors" ON public.doctor_questions;

-- إنشاء السياسات الصحيحة

-- 1. أي شخص يمكنه إرسال سؤال (بدون تسجيل)
CREATE POLICY "questions_insert_public"
  ON public.doctor_questions
  FOR INSERT
  WITH CHECK (true);

-- 2. أي شخص يمكنه رؤية الأسئلة المُجاب عليها
CREATE POLICY "questions_select_answered_public"
  ON public.doctor_questions
  FOR SELECT
  USING (is_answered = true);

-- 3. الأطباء يرون جميع أسئلتهم (authenticated only)
-- نستخدم auth.email() بدلاً من auth.users
CREATE POLICY "questions_select_own_authenticated"
  ON public.doctor_questions
  FOR SELECT
  TO authenticated
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = auth.email()
    )
  );

-- 4. الأطباء يمكنهم تحديث (الإجابة على) أسئلتهم
CREATE POLICY "questions_update_own_authenticated"
  ON public.doctor_questions
  FOR UPDATE
  TO authenticated
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = auth.email()
    )
  );

-- 5. الأطباء يمكنهم حذف أسئلتهم
CREATE POLICY "questions_delete_own_authenticated"
  ON public.doctor_questions
  FOR DELETE
  TO authenticated
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = auth.email()
    )
  );

COMMIT;

-- التحقق من السياسات
SELECT 
  policyname,
  cmd,
  roles,
  CASE 
    WHEN qual IS NOT NULL THEN 'USING defined'
    ELSE 'No USING'
  END as has_using,
  CASE 
    WHEN with_check IS NOT NULL THEN 'WITH CHECK defined'
    ELSE 'No WITH CHECK'
  END as has_with_check
FROM pg_policies
WHERE tablename = 'doctor_questions'
ORDER BY policyname;
