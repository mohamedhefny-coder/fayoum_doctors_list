-- ============================================
-- Admin Setup for Fayoum Doctors List
-- إعداد نظام المدير لدليل أطباء الفيوم
-- ============================================

-- الخطوة 1: إنشاء جدول المديرين
-- ============================================
CREATE TABLE IF NOT EXISTS public.admins (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- الخطوة 2: تفعيل Row Level Security على جدول المديرين
-- ============================================
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- سياسة: فقط المديرين يمكنهم قراءة جدول المديرين
CREATE POLICY "Only admins can view admins table"
  ON public.admins
  FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- الخطوة 3: تعديل سياسات جدول الأطباء
-- ============================================

-- حذف السياسة القديمة التي تسمح لأي شخص بإضافة طبيب
DROP POLICY IF EXISTS "Anyone can insert a new doctor during signup" ON public.doctors;
DROP POLICY IF EXISTS "Only admins can insert new doctors" ON public.doctors;

-- سياسة جديدة 1: المديرون يمكنهم إضافة أي طبيب
CREATE POLICY "Admins can insert any doctor"
  ON public.doctors
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- سياسة جديدة 2: المستخدم يمكنه إضافة بياناته الخاصة فقط
-- هذا يسمح للطبيب الجديد بإضافة بياناته عند التسجيل
CREATE POLICY "Users can insert their own doctor profile"
  ON public.doctors
  FOR INSERT
  WITH CHECK (
    auth.uid() = id
  );

-- سياسة 3: المديرون يمكنهم تعديل أي حساب طبيب
CREATE POLICY "Admins can update any doctor"
  ON public.doctors
  FOR UPDATE
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- سياسة 4: المديرون يمكنهم حذف أي حساب طبيب
CREATE POLICY "Admins can delete any doctor"
  ON public.doctors
  FOR DELETE
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- الخطوة 4: إضافة أول مدير (قم بتعديل البريد الإلكتروني)
-- ============================================
-- ⚠️ هام: يجب أولاً إنشاء المستخدم في Authentication من Supabase Dashboard

-- بعد إنشاء المستخدم في Authentication، قم بنسخ الـ UUID الخاص به واستخدمه هنا
-- مثال:
-- INSERT INTO public.admins (id, email)
-- VALUES ('UUID-من-authentication-dashboard', 'admin@example.com');

-- لإضافة أول مدير، اتبع الخطوات التالية:
-- 1. اذهب إلى Supabase Dashboard → Authentication → Users
-- 2. اضغط "Add User" وأدخل:
--    - Email: admin@fayoumdoctors.com (أو أي بريد تريده)
--    - Password: كلمة مرور قوية
--    - فعّل "Auto Confirm User"
-- 3. انسخ الـ UUID الذي تم إنشاؤه للمستخدم
-- 4. نفذ الأمر التالي مع استبدال 'YOUR-ADMIN-UUID' بالـ UUID الفعلي:

-- مثال للتنفيذ بعد الحصول على UUID:
/*
INSERT INTO public.admins (id, email)
VALUES ('YOUR-ADMIN-UUID-HERE', 'admin@fayoumdoctors.com');
*/

-- ============================================
-- ملاحظات مهمة
-- ============================================
-- 1. يجب إنشاء المدير الأول يدوياً من Supabase Dashboard
-- 2. بعد ذلك يمكن للمدير إضافة أطباء جدد من التطبيق
-- 3. المديرون فقط يمكنهم:
--    - إضافة أطباء جدد
--    - حذف حسابات الأطباء
--    - إعادة تعيين كلمة المرور للأطباء

-- ============================================
-- للتحقق من أن كل شيء يعمل بشكل صحيح
-- ============================================
-- تحقق من جدول المديرين:
-- SELECT * FROM public.admins;

-- تحقق من السياسات:
-- SELECT * FROM pg_policies WHERE tablename = 'doctors' OR tablename = 'admins';

-- ============================================
-- لإضافة مدير إضافي (بعد تسجيل الدخول كمدير)
-- ============================================
-- يمكنك استخدام نفس الطريقة:
-- 1. إنشاء المستخدم في Authentication
-- 2. إضافته إلى جدول admins:
/*
INSERT INTO public.admins (id, email)
VALUES ('new-admin-uuid', 'newadmin@example.com');
*/
