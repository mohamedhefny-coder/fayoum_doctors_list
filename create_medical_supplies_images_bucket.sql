-- ============================================
-- Supabase Storage: medical supplies images bucket + RLS policies
-- Bucket id/name used in app code: medical-supplies-images
-- ============================================

-- Create bucket (public read)
INSERT INTO storage.buckets (id, name, public)
VALUES ('medical-supplies-images', 'medical-supplies-images', true)
ON CONFLICT (id) DO NOTHING;

-- NOTE:
-- These policies allow:
-- - Public SELECT (since bucket is public, but policy still needed when RLS is enabled)
-- - Authenticated users to INSERT/UPDATE/DELETE only inside their own folder: <auth.uid()>/...

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public can read medical supplies images'
  ) THEN
    CREATE POLICY "Public can read medical supplies images"
      ON storage.objects
      FOR SELECT
      USING (bucket_id = 'medical-supplies-images');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can upload their medical supplies images'
  ) THEN
    CREATE POLICY "Users can upload their medical supplies images"
      ON storage.objects
      FOR INSERT
      WITH CHECK (
        bucket_id = 'medical-supplies-images'
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
      AND policyname = 'Users can update their medical supplies images'
  ) THEN
    CREATE POLICY "Users can update their medical supplies images"
      ON storage.objects
      FOR UPDATE
      USING (
        bucket_id = 'medical-supplies-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      )
      WITH CHECK (
        bucket_id = 'medical-supplies-images'
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
      AND policyname = 'Users can delete their medical supplies images'
  ) THEN
    CREATE POLICY "Users can delete their medical supplies images"
      ON storage.objects
      FOR DELETE
      USING (
        bucket_id = 'medical-supplies-images'
        AND auth.role() = 'authenticated'
        AND name LIKE (auth.uid()::text || '/%')
      );
  END IF;
END $$;
