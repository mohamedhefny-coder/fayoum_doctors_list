-- ============================================
-- Supabase Storage: hospitals images bucket + RLS policies
-- Bucket id/name used in app code: hospitals-images
-- ============================================

-- Create bucket (public read)
INSERT INTO storage.buckets (id, name, public)
VALUES ('hospitals-images', 'hospitals-images', true)
ON CONFLICT (id) DO NOTHING;

-- Public read
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public can read hospitals images'
  ) THEN
    CREATE POLICY "Public can read hospitals images"
      ON storage.objects
      FOR SELECT
      USING (bucket_id = 'hospitals-images');
  END IF;
END $$;

-- Users can write only under <auth.uid()>/...
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can upload their hospitals images'
  ) THEN
    CREATE POLICY "Users can upload their hospitals images"
      ON storage.objects
      FOR INSERT
      WITH CHECK (
        bucket_id = 'hospitals-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can update their hospitals images'
  ) THEN
    CREATE POLICY "Users can update their hospitals images"
      ON storage.objects
      FOR UPDATE
      USING (
        bucket_id = 'hospitals-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      )
      WITH CHECK (
        bucket_id = 'hospitals-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can delete their hospitals images'
  ) THEN
    CREATE POLICY "Users can delete their hospitals images"
      ON storage.objects
      FOR DELETE
      USING (
        bucket_id = 'hospitals-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      );
  END IF;
END $$;
