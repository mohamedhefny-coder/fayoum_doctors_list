-- =====================================================
-- Fix Doctor Questions RLS Policies
-- =====================================================
-- هذا الملف يحدّث سياسات RLS للجدول doctor_questions
-- لكي تعمل حتى لو لم يكن doctors.id == auth.uid()

BEGIN;

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Doctors can see all their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can update their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can delete their questions" ON public.doctor_questions;

-- إنشاء السياسات المحسّنة

-- سياسة: الأطباء يمكنهم رؤية جميع أسئلتهم
-- تعمل مع doctors.id == auth.uid() أو إذا كان الطبيب مسجل دخول بحساب مرتبط
CREATE POLICY "Doctors can see all their questions"
  ON public.doctor_questions
  FOR SELECT
  USING (
    -- إذا كان doctor_id يساوي auth.uid مباشرة
    doctor_id = auth.uid()
    OR
    -- أو إذا كان الطبيب موجود في جدول doctors مع نفس email المسجل به
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- سياسة: الأطباء يمكنهم تحديث (الإجابة على) أسئلتهم
CREATE POLICY "Doctors can update their questions"
  ON public.doctor_questions
  FOR UPDATE
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- سياسة: الأطباء يمكنهم حذف أسئلتهم
CREATE POLICY "Doctors can delete their questions"
  ON public.doctor_questions
  FOR DELETE
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
-- تعليمات الاستخدام:
-- =====================================================
-- 1. افتح Supabase Dashboard -> SQL Editor
-- 2. انسخ والصق هذا الملف بالكامل
-- 3. اضغط Run
-- 4. تحقق من أن كل شيء عمل بدون أخطاء
-- 
-- ملاحظة: هذه السياسات تعمل بطريقتين:
-- - إذا كان doctors.id == auth.uid() (الحالة المثالية)
-- - أو إذا كان الطبيب مسجل دخول بحساب له نفس الإيميل في جدول doctors
-- =====================================================
