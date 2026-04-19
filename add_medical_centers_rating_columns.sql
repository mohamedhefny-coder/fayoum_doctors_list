-- ============================================================
-- Add rating columns to medical_centers (if missing)
-- إضافة أعمدة التقييم للمراكز الطبية (إن لم تكن موجودة)
-- Run in Supabase SQL Editor.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'medical_centers'
      AND column_name = 'rating'
  ) THEN
    ALTER TABLE public.medical_centers
      ADD COLUMN rating REAL DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'medical_centers'
      AND column_name = 'rating_count'
  ) THEN
    ALTER TABLE public.medical_centers
      ADD COLUMN rating_count INTEGER DEFAULT 0;
  END IF;
END $$;

UPDATE public.medical_centers SET rating = 0 WHERE rating IS NULL;
UPDATE public.medical_centers SET rating_count = 0 WHERE rating_count IS NULL;
