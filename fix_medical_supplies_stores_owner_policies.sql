-- ============================================
-- Fix: Allow Medical Supplies Store Owners to Manage Their Store
-- حل: السماح لصاحب متجر المستلزمات بإدخال/تعديل متجره
-- ============================================
--
-- Assumption:
-- - We treat `medical_supplies_stores.created_by` as the owner user id (auth.uid()).
-- - Admins keep full access via existing policies.
--
-- Execute this in Supabase Dashboard -> SQL Editor.

ALTER TABLE public.medical_supplies_stores ENABLE ROW LEVEL SECURITY;

-- Owners can read their own store (even if not published)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Owners can read their own medical supplies store'
  ) THEN
    CREATE POLICY "Owners can read their own medical supplies store"
      ON public.medical_supplies_stores
      FOR SELECT
      USING (created_by = auth.uid());
  END IF;
END $$;

-- Owners can insert their own store
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Owners can insert their own medical supplies store'
  ) THEN
    CREATE POLICY "Owners can insert their own medical supplies store"
      ON public.medical_supplies_stores
      FOR INSERT
      WITH CHECK (created_by = auth.uid());
  END IF;
END $$;

-- Owners can update their own store
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Owners can update their own medical supplies store'
  ) THEN
    CREATE POLICY "Owners can update their own medical supplies store"
      ON public.medical_supplies_stores
      FOR UPDATE
      USING (created_by = auth.uid())
      WITH CHECK (created_by = auth.uid());
  END IF;
END $$;

-- Optional: owners can delete their own store
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Owners can delete their own medical supplies store'
  ) THEN
    CREATE POLICY "Owners can delete their own medical supplies store"
      ON public.medical_supplies_stores
      FOR DELETE
      USING (created_by = auth.uid());
  END IF;
END $$;
