-- إضافة أعمدة خدمات الطوارئ والزيارة المنزلية إلى جدول الأطباء
ALTER TABLE public.doctors
  ADD COLUMN IF NOT EXISTS emergency_24h BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS emergency_phone TEXT,
  ADD COLUMN IF NOT EXISTS home_visit BOOLEAN DEFAULT FALSE;
