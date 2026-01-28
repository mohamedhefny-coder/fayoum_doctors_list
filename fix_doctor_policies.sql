-- ============================================
-- إصلاح سريع لسياسات جدول الأطباء
-- Quick Fix for Doctors Table Policies
-- ============================================

-- تأكد من تفعيل RLS
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

-- الخطوة 1: حذف جميع السياسات القديمة المتعلقة بالإضافة والتعديل
DROP POLICY IF EXISTS "Only admins can insert new doctors" ON public.doctors;
DROP POLICY IF EXISTS "Admins can insert any doctor" ON public.doctors;
DROP POLICY IF EXISTS "Users can insert their own doctor profile" ON public.doctors;
DROP POLICY IF EXISTS "Doctors can update their own profile" ON public.doctors;
DROP POLICY IF EXISTS "Admins can update any doctor" ON public.doctors;
DROP POLICY IF EXISTS "Doctors can delete their own profile" ON public.doctors;
DROP POLICY IF EXISTS "Admins can delete any doctor" ON public.doctors;

-- حذف سياسات القراءة القديمة (SELECT) إن وجدت
DROP POLICY IF EXISTS "Public doctors are viewable by all" ON public.doctors;
DROP POLICY IF EXISTS "Public doctors are readable by all" ON public.doctors;

-- الخطوة 2: إنشاء السياسات الصحيحة

-- سياسة 0: السماح بقراءة بيانات الأطباء (مطلوب لعرض الملف الشخصي)
-- ملاحظة: لو تريد إخفاء الأطباء غير المنشورين عن العامة استخدم add_publish_workflow.sql
CREATE POLICY "Public doctors are viewable by all"
  ON public.doctors
  FOR SELECT
  USING (true);

-- سياسة 1: المديرون يمكنهم إضافة أي طبيب
CREATE POLICY "Admins can insert any doctor"
  ON public.doctors
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- سياسة 2: المستخدم يمكنه إضافة بياناته الخاصة فقط
-- هذا يسمح للطبيب الجديد بإضافة بياناته عند التسجيل
CREATE POLICY "Users can insert their own doctor profile"
  ON public.doctors
  FOR INSERT
  WITH CHECK (
    auth.uid() = id
  );

-- سياسة 3: الطبيب يمكنه تعديل بياناته الخاصة فقط
CREATE POLICY "Doctors can update their own profile"
  ON public.doctors
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- سياسة 4: المديرون يمكنهم تعديل أي حساب طبيب
CREATE POLICY "Admins can update any doctor"
  ON public.doctors
  FOR UPDATE
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- سياسة 5: الطبيب يمكنه حذف حسابه فقط
CREATE POLICY "Doctors can delete their own profile"
  ON public.doctors
  FOR DELETE
  USING (auth.uid() = id);

-- سياسة 6: المديرون يمكنهم حذف أي حساب طبيب
CREATE POLICY "Admins can delete any doctor"
  ON public.doctors
  FOR DELETE
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- ============================================
-- التحقق من السياسات
-- ============================================
-- يمكنك تشغيل هذا الأمر للتحقق من أن السياسات تم إنشاؤها بنجاح:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename = 'doctors';

-- ============================================
-- ملاحظات مهمة
-- ============================================
-- 1. تأكد من تعطيل "Email Confirmation" في Supabase Dashboard
--    Authentication > Settings > Enable email confirmations (OFF)
-- 
-- 2. السياسات الآن تسمح بـ:
--    - المديرون: إضافة/تعديل/حذف أي طبيب
--    - الأطباء: إضافة حسابهم الخاص، تعديل وحذف بياناتهم فقط
-- 
-- 3. عند إنشاء طبيب جديد من لوحة المدير:
--    - سيتم تسجيل خروج المدير تلقائياً
--    - يجب على المدير تسجيل الدخول مرة أخرى
--    - هذا طبيعي بسبب طريقة عمل Supabase Auth
