-- جدول الصالات الرياضية (Gyms)
-- يدعم: أنواع متعددة (رجالي/سيدات/مختلط)، كفر + معرض صور، موقع/فيس، خصومات/عروض
-- وأوقات عمل أسبوعية (لكل يوم: ساعات رجال/نساء) محفوظة في jsonb

CREATE TABLE IF NOT EXISTS gyms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  whatsapp TEXT,
  geo_location TEXT,
  facebook_url TEXT,
  gym_types TEXT[],
  features TEXT[],
  is_24_hours BOOLEAN DEFAULT false,
  has_parking BOOLEAN DEFAULT false,
  price_level TEXT,
  offers TEXT,
  discounts TEXT,
  notes TEXT,
  cover_image_url TEXT,
  gallery_image_urls TEXT[],
  working_hours JSONB,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- فهارس
CREATE UNIQUE INDEX IF NOT EXISTS uq_gyms_user_id ON gyms(user_id);
CREATE INDEX IF NOT EXISTS idx_gyms_is_published ON gyms(is_published);
CREATE INDEX IF NOT EXISTS idx_gyms_name ON gyms(name);

-- RLS
ALTER TABLE gyms ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'gyms'
      AND policyname = 'Anyone can view published gyms'
  ) THEN
    CREATE POLICY "Anyone can view published gyms"
      ON gyms FOR SELECT
      USING (is_published = true);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'gyms'
      AND policyname = 'Gym owners can view their own gym'
  ) THEN
    CREATE POLICY "Gym owners can view their own gym"
      ON gyms FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'gyms'
      AND policyname = 'Gym owners can insert their own gym'
  ) THEN
    CREATE POLICY "Gym owners can insert their own gym"
      ON gyms FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'gyms'
      AND policyname = 'Gym owners can update their own gym'
  ) THEN
    CREATE POLICY "Gym owners can update their own gym"
      ON gyms FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'gyms'
      AND policyname = 'Gym owners can delete their own gym'
  ) THEN
    CREATE POLICY "Gym owners can delete their own gym"
      ON gyms FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Trigger لتحديث updated_at
CREATE OR REPLACE FUNCTION update_gyms_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'update_gyms_updated_at'
  ) THEN
    CREATE TRIGGER update_gyms_updated_at
      BEFORE UPDATE ON gyms
      FOR EACH ROW
      EXECUTE FUNCTION update_gyms_updated_at_column();
  END IF;
END $$;
