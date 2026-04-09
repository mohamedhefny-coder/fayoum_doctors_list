-- ============================================
-- Fix: Allow admins to manage radiology_centers
-- إصلاح: السماح للمدير بإدارة مراكز الأشعة
-- ============================================

-- ملاحظة: هذا السكربت يفترض أن جدول admins موجود (admin_setup.sql)
-- وأن UUID المدير مُدرج في public.admins.

ALTER TABLE public.radiology_centers ENABLE ROW LEVEL SECURITY;

-- إزالة سياسات قديمة إن وجدت (لمنع التكرار)
DROP POLICY IF EXISTS "Admins can select any radiology center" ON public.radiology_centers;
DROP POLICY IF EXISTS "Admins can update any radiology center" ON public.radiology_centers;
DROP POLICY IF EXISTS "Admins can delete any radiology center" ON public.radiology_centers;

-- المدير يمكنه قراءة جميع المراكز (منشورة وغير منشورة)
CREATE POLICY "Admins can select any radiology center"
  ON public.radiology_centers
  FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- المدير يمكنه تعديل أي مركز (نشر/حجز/بيانات)
CREATE POLICY "Admins can update any radiology center"
  ON public.radiology_centers
  FOR UPDATE
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );

-- المدير يمكنه حذف أي مركز
CREATE POLICY "Admins can delete any radiology center"
  ON public.radiology_centers
  FOR DELETE
  USING (
    auth.uid() IN (SELECT id FROM public.admins)
  );
