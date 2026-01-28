-- ===============================================
-- إضافة أعمدة جديدة لجدول الأطباء
-- ===============================================
-- قم بتنفيذ هذه الأوامر في Supabase SQL Editor
-- https://supabase.com/dashboard/project/_/sql

-- 1. إضافة عمود المؤهلات والشهادات
ALTER TABLE public.doctors 
ADD COLUMN IF NOT EXISTS qualifications TEXT;

-- 2. إضافة عمود صفحة الفيس بوك
ALTER TABLE public.doctors 
ADD COLUMN IF NOT EXISTS facebook_url TEXT;

-- ===============================================
-- بيانات تجريبية (اختياري)
-- ===============================================
-- يمكنك تحديث سجلات موجودة بمؤهلات وفيس بوك تجريبية:

-- UPDATE public.doctors 
-- SET qualifications = 'بكالوريوس الطب والجراحة - جامعة القاهرة
-- ماجستير في الجراحة العامة
-- زمالة من الهيئة المصرية للتخصص',
--     facebook_url = 'https://www.facebook.com/doctorpage'
-- WHERE email = 'doctor@example.com';

-- ===============================================
-- للتحقق من نجاح الإضافة
-- ===============================================
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'doctors' 
-- AND column_name IN ('qualifications', 'facebook_url');
