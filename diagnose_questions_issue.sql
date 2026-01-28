-- =====================================================
-- تشخيص مشكلة الأسئلة والاستفسارات
-- =====================================================

-- 1. التحقق من وجود الجدول
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'doctor_questions'
) AS table_exists;

-- 2. التحقق من RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'doctor_questions';

-- 3. عرض جميع السياسات الموجودة
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'doctor_questions'
ORDER BY policyname;

-- 4. التحقق من عدد الأسئلة الموجودة
SELECT COUNT(*) as total_questions FROM public.doctor_questions;

-- 5. عرض آخر 5 أسئلة (إذا كان لديك صلاحية)
SELECT id, doctor_id, patient_name, question, is_answered, created_at
FROM public.doctor_questions
ORDER BY created_at DESC
LIMIT 5;

-- 6. التحقق من doctor_id في جدول doctors
SELECT id, email, full_name 
FROM public.doctors
LIMIT 3;
