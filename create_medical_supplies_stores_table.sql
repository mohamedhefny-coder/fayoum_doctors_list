-- ============================================
-- Medical Supplies Stores (Admin-managed)
-- ============================================

-- Table: medical_supplies_stores
CREATE TABLE IF NOT EXISTS public.medical_supplies_stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  whatsapp TEXT,
  working_hours TEXT,

  cover_image_url TEXT,
  available_supplies TEXT[],
  gallery_image_urls TEXT[],

  offers_and_discounts TEXT,
  has_delivery_service BOOLEAN DEFAULT false,
  available_contracts TEXT,
  geo_location TEXT,
  facebook_page TEXT,

  is_published BOOLEAN DEFAULT false,
  created_by UUID,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.medical_supplies_stores ENABLE ROW LEVEL SECURITY;

-- Public read: only published stores
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Public medical supplies stores are viewable when published'
  ) THEN
    CREATE POLICY "Public medical supplies stores are viewable when published"
      ON public.medical_supplies_stores
      FOR SELECT
      USING (is_published = true);
  END IF;
END $$;

-- Admin full read
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Admins can read all medical supplies stores'
  ) THEN
    CREATE POLICY "Admins can read all medical supplies stores"
      ON public.medical_supplies_stores
      FOR SELECT
      USING (EXISTS (SELECT 1 FROM public.admins a WHERE a.id = auth.uid()));
  END IF;
END $$;

-- Admin insert
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Admins can insert medical supplies stores'
  ) THEN
    CREATE POLICY "Admins can insert medical supplies stores"
      ON public.medical_supplies_stores
      FOR INSERT
      WITH CHECK (EXISTS (SELECT 1 FROM public.admins a WHERE a.id = auth.uid()));
  END IF;
END $$;

-- Admin update
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Admins can update medical supplies stores'
  ) THEN
    CREATE POLICY "Admins can update medical supplies stores"
      ON public.medical_supplies_stores
      FOR UPDATE
      USING (EXISTS (SELECT 1 FROM public.admins a WHERE a.id = auth.uid()))
      WITH CHECK (EXISTS (SELECT 1 FROM public.admins a WHERE a.id = auth.uid()));
  END IF;
END $$;

-- Admin delete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'medical_supplies_stores'
      AND policyname = 'Admins can delete medical supplies stores'
  ) THEN
    CREATE POLICY "Admins can delete medical supplies stores"
      ON public.medical_supplies_stores
      FOR DELETE
      USING (EXISTS (SELECT 1 FROM public.admins a WHERE a.id = auth.uid()));
  END IF;
END $$;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_medical_supplies_stores_created_at
  ON public.medical_supplies_stores(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_medical_supplies_stores_is_published
  ON public.medical_supplies_stores(is_published);
