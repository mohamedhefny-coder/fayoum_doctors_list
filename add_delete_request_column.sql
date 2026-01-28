-- إضافة حقل طلب الحذف إلى جدول الأطباء
-- نفذ هذا الملف في Supabase Dashboard -> SQL Editor

BEGIN;

-- إضافة حقل delete_requested (طلب الحذف)
ALTER TABLE doctors
  ADD COLUMN IF NOT EXISTS delete_requested BOOLEAN DEFAULT FALSE;

-- إضافة حقل delete_requested_at (تاريخ طلب الحذف)
ALTER TABLE doctors
  ADD COLUMN IF NOT EXISTS delete_requested_at TIMESTAMP WITH TIME ZONE;

-- إضافة تعليق توضيحي
COMMENT ON COLUMN doctors.delete_requested IS 'يشير إلى أن الطبيب طلب حذف حسابه ويحتاج موافقة المدير';
COMMENT ON COLUMN doctors.delete_requested_at IS 'تاريخ ووقت طلب حذف الحساب';

COMMIT;

-- ملاحظات:
-- 1. عندما يطلب الطبيب حذف حسابه، يتم تعيين delete_requested = true
-- 2. المدير يمكنه رؤية جميع الأطباء الذين طلبوا حذف حساباتهم
-- 3. المدير يمكنه الموافقة على الطلب بحذف الحساب فعلياً
-- 4. أو يمكن للمدير رفض الطلب بتعيين delete_requested = false
