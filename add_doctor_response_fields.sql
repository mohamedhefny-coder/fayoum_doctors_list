-- =====================================================
-- إضافة حقول رد الطبيب على طلبات الحجز
-- =====================================================
-- هذا السكريبت يضيف الحقول التالية لجدول appointments:
-- 1. doctor_response_message: رسالة رد الطبيب (مثل: "الحجز مكتمل لهذا اليوم")
-- 2. suggested_date: التاريخ المقترح من الطبيب (إذا كان اليوم ممتلئ)
-- 3. suggested_time: الوقت المقترح من الطبيب

-- إضافة عمود رسالة رد الطبيب
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS doctor_response_message TEXT;

-- إضافة عمود التاريخ المقترح
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS suggested_date DATE;

-- إضافة عمود الوقت المقترح
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS suggested_time TIME;

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN public.appointments.doctor_response_message IS 'رسالة رد الطبيب على طلب الحجز';
COMMENT ON COLUMN public.appointments.suggested_date IS 'التاريخ المقترح من الطبيب (في حالة عدم توفر الموعد المطلوب)';
COMMENT ON COLUMN public.appointments.suggested_time IS 'الوقت المقترح من الطبيب';

-- التحقق من إضافة الأعمدة
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'appointments'
  AND column_name IN ('doctor_response_message', 'suggested_date', 'suggested_time');
