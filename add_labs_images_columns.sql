-- ============================================
-- Add images fields to labs table
-- Adds: cover_image_url, logo_image_url, gallery_image_urls
-- ============================================

ALTER TABLE labs
  ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
  ADD COLUMN IF NOT EXISTS logo_image_url TEXT,
  ADD COLUMN IF NOT EXISTS gallery_image_urls TEXT[];
