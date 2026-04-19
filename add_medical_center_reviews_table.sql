-- ============================================================
-- Medical Center Reviews Table + RLS
-- جدول تقييمات المراكز الطبية + سياسات الحماية
-- Run in Supabase SQL Editor.
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.medical_center_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  center_id UUID NOT NULL REFERENCES public.medical_centers(id) ON DELETE CASCADE,
  reviewer_name TEXT NOT NULL,
  reviewer_phone TEXT,
  rating NUMERIC(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  status TEXT NOT NULL DEFAULT 'approved' CHECK (status IN ('approved', 'pending', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_medical_center_reviews_center_id
  ON public.medical_center_reviews(center_id);
CREATE INDEX IF NOT EXISTS idx_medical_center_reviews_status
  ON public.medical_center_reviews(status);
CREATE INDEX IF NOT EXISTS idx_medical_center_reviews_created_at
  ON public.medical_center_reviews(created_at DESC);

ALTER TABLE public.medical_center_reviews ENABLE ROW LEVEL SECURITY;

-- Public can read approved reviews
DROP POLICY IF EXISTS "approved_center_reviews_public_read" ON public.medical_center_reviews;
CREATE POLICY "approved_center_reviews_public_read"
  ON public.medical_center_reviews
  FOR SELECT
  USING (status = 'approved');

-- Allow anyone to insert (approved only)
DROP POLICY IF EXISTS "anyone_can_insert_center_review" ON public.medical_center_reviews;
CREATE POLICY "anyone_can_insert_center_review"
  ON public.medical_center_reviews
  FOR INSERT
  WITH CHECK (status = 'approved');

COMMIT;
