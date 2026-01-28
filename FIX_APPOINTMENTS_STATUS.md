# إصلاح مشكلة constraint في جدول appointments

## المشكلة
قاعدة البيانات تحتوي على constraint يسمح فقط بالقيم: `'pending', 'confirmed', 'cancelled', 'completed'`
لكن التطبيق يستخدم: `'pending', 'accepted', 'rejected'`

## الحل
نفّذ الملف SQL التالي في Supabase SQL Editor:

```sql
-- Drop the old constraint
ALTER TABLE public.appointments 
DROP CONSTRAINT IF EXISTS appointments_status_check;

-- Add the new constraint with correct status values
ALTER TABLE public.appointments 
ADD CONSTRAINT appointments_status_check 
CHECK (status IN ('pending', 'accepted', 'rejected'));

-- Update any existing appointments with old status values (optional)
UPDATE public.appointments 
SET status = 'accepted' 
WHERE status = 'confirmed' OR status = 'completed';

UPDATE public.appointments 
SET status = 'rejected' 
WHERE status = 'cancelled';
```

## الخطوات
1. افتح Supabase Dashboard
2. اذهب إلى SQL Editor
3. انسخ والصق الكود أعلاه
4. اضغط Run
5. أعد تشغيل التطبيق

بعد تنفيذ هذا، ستعمل أزرار القبول والرفض بدون مشاكل.
