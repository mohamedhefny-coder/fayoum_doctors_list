-- Add image columns for Radiology Centers
-- Run this in Supabase SQL Editor

ALTER TABLE radiology_centers
  ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

ALTER TABLE radiology_centers
  ADD COLUMN IF NOT EXISTS gallery_image_urls TEXT[];
