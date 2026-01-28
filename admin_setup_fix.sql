-- ============================================
-- إصلاح سياسات إضافة الأطباء
-- Fix for Doctor Insertion Policies
-- ============================================

-- المشكلة: عندما يقوم المدير بإنشاء حساب طبيب جديد،
-- يتم تسجيل دخول الطبيب تلقائياً، لكن الطبيب ليس مديراً
-- ولذلك لا يمكنه الإضافة في جدول doctors

-- الحل: إضافة سياسة تسمح للمستخدم بإضافة بياناته الخاصة

-- حذف السياسة الحالية
DROP POLICY IF EXISTS "Only admins can insert new doctors" ON public.doctors;

-- سياسة جديدة 1: المديرون يمكنهم إضافة أي طبيب
CREATE POLICY "Admins can insert any doctor"
  ON public.doctors
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- سياسة جديدة 2: المستخدم يمكنه إضافة بياناته الخاصة فقط
-- هذا يسمح للطبيب الجديد بإضافة بياناته عند التسجيل الأولي
CREATE POLICY "Users can insert their own doctor profile"
  ON public.doctors
  FOR INSERT
  WITH CHECK (
    auth.uid() = id
  );

-- ============================================
-- التحقق من السياسات
-- ============================================
-- SELECT * FROM pg_policies WHERE tablename = 'doctors';
