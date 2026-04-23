-- ============================================
-- Supabase Storage: gyms images bucket + RLS policies
-- Bucket id/name used in app code: gyms-images
-- ============================================

-- Create bucket (public read)
INSERT INTO storage.buckets (id, name, public)
VALUES ('gyms-images', 'gyms-images', true)
ON CONFLICT (id) DO NOTHING;

-- Public read
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public can read gyms images'
  ) THEN
    CREATE POLICY "Public can read gyms images"
      ON storage.objects
      FOR SELECT
      USING (bucket_id = 'gyms-images');
  END IF;
END $$;

-- Users can write only under <auth.uid()>/...
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can upload their gyms images'
  ) THEN
    CREATE POLICY "Users can upload their gyms images"
      ON storage.objects
      FOR INSERT
      WITH CHECK (
        bucket_id = 'gyms-images'
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
      AND policyname = 'Users can update their gyms images'
  ) THEN
    CREATE POLICY "Users can update their gyms images"
      ON storage.objects
      FOR UPDATE
      USING (
        bucket_id = 'gyms-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      )
      WITH CHECK (
        bucket_id = 'gyms-images'
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
      AND policyname = 'Users can delete their gyms images'
  ) THEN
    CREATE POLICY "Users can delete their gyms images"
      ON storage.objects
      FOR DELETE
      USING (
        bucket_id = 'gyms-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      );
  END IF;
END $$;
