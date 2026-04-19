-- ============================================================
-- نظام التقييمات والمراجعات للأطباء
-- Doctor Reviews & Ratings System
-- يجب تشغيل هذا الملف في Supabase SQL Editor
-- ============================================================

BEGIN;

-- إنشاء جدول التقييمات
CREATE TABLE IF NOT EXISTS public.doctor_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  reviewer_name TEXT NOT NULL,
  reviewer_phone TEXT,
  rating NUMERIC(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT
);

-- فهارس للأداء
CREATE INDEX IF NOT EXISTS idx_doctor_reviews_doctor_id ON public.doctor_reviews(doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_reviews_status ON public.doctor_reviews(status);
CREATE INDEX IF NOT EXISTS idx_doctor_reviews_created_at ON public.doctor_reviews(created_at DESC);

-- Row Level Security
ALTER TABLE public.doctor_reviews ENABLE ROW LEVEL SECURITY;

-- منح الصلاحيات (RLS ما يشتغلش لو مفيش GRANT)
GRANT SELECT, INSERT ON TABLE public.doctor_reviews TO anon, authenticated;
GRANT UPDATE, DELETE ON TABLE public.doctor_reviews TO authenticated;

-- تنظيف سياسات قديمة إن وجدت
DROP POLICY IF EXISTS "approved_reviews_public_read" ON public.doctor_reviews;
DROP POLICY IF EXISTS "anyone_can_insert_review" ON public.doctor_reviews;
DROP POLICY IF EXISTS "doctor_read_own_reviews" ON public.doctor_reviews;
DROP POLICY IF EXISTS "doctor_update_own_reviews" ON public.doctor_reviews;
DROP POLICY IF EXISTS "admin_full_access_reviews" ON public.doctor_reviews;

-- السماح لأي شخص بقراءة التقييمات المعتمدة
CREATE POLICY "approved_reviews_public_read"
  ON public.doctor_reviews FOR SELECT
  USING (status = 'approved');

-- السماح لأي شخص بإضافة تقييم
CREATE POLICY "anyone_can_insert_review"
  ON public.doctor_reviews FOR INSERT
  WITH CHECK (status = 'pending');

-- السماح للطبيب بقراءة تقييماته (بما فيها المعلقة)
CREATE POLICY "doctor_read_own_reviews"
  ON public.doctor_reviews FOR SELECT
  USING (doctor_id = auth.uid());

-- السماح للطبيب بتحديث تقييماته (الموافقة/الرفض)
CREATE POLICY "doctor_update_own_reviews"
  ON public.doctor_reviews FOR UPDATE
  USING (doctor_id = auth.uid())
  WITH CHECK (doctor_id = auth.uid());

-- السماح للأدمن بكل شيء
CREATE POLICY "admin_full_access_reviews"
  ON public.doctor_reviews FOR ALL
  USING (auth.uid() IN (SELECT id FROM public.admins));

COMMIT;
