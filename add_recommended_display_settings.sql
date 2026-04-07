-- إضافة أعمدة التحكم في عرض الأطباء الموصى بهم
-- Add columns for recommended doctors display control
-- تاريخ: 2026-02-11

-- إضافة الأعمدة
ALTER TABLE doctors 
ADD COLUMN IF NOT EXISTS is_recommended BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS recommended_weight INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS recommended_duration_seconds INTEGER DEFAULT 3;

-- إضافة قيود التحقق (Constraints)
-- التأكد من أن الوزن بين 1 و 10
ALTER TABLE doctors 
ADD CONSTRAINT check_recommended_weight 
CHECK (recommended_weight >= 1 AND recommended_weight <= 10);

-- التأكد من أن مدة العرض بين 2 و 12 ثانية
ALTER TABLE doctors 
ADD CONSTRAINT check_recommended_duration 
CHECK (recommended_duration_seconds >= 2 AND recommended_duration_seconds <= 12);

-- إضافة فهرس لتحسين الأداء عند الاستعلام عن الأطباء الموصى بهم
CREATE INDEX IF NOT EXISTS idx_doctors_recommended 
ON doctors(is_recommended, is_published) 
WHERE is_recommended = TRUE AND is_published = TRUE;

-- تعليق على الأعمدة الجديدة
COMMENT ON COLUMN doctors.is_recommended IS 'تفعيل ظهور الطبيب في شريط الأطباء الموصى بهم';
COMMENT ON COLUMN doctors.recommended_weight IS 'وزن العرض (1-10): كلما زاد الوزن، زادت عدد مرات ظهور الطبيب في الشريط';
COMMENT ON COLUMN doctors.recommended_duration_seconds IS 'مدة عرض بطاقة الطبيب (2-12 ثانية) قبل الانتقال للبطاقة التالية';

-- إعطاء صلاحيات التحديث للمدير
-- يجب أن يكون للمدير صلاحية UPDATE على هذه الأعمدة
-- (يتم ذلك تلقائياً من خلال RLS policies الموجودة)

-- مثال: تفعيل بعض الأطباء كأطباء موصى بهم (اختياري - للاختبار فقط)
-- UPDATE doctors 
-- SET is_recommended = TRUE, 
--     recommended_weight = 5, 
--     recommended_duration_seconds = 5,
--     updated_at = NOW()
-- WHERE is_published = TRUE 
-- LIMIT 3;
