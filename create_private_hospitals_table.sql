-- جدول المستشفيات الخاصة (Private Hospitals)
-- ملاحظة: هذا السكربت ينشئ جدول + RLS policies مشابهة لجدول labs

CREATE TABLE IF NOT EXISTS private_hospitals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  whatsapp TEXT,
  geo_location TEXT,
  facebook_url TEXT,
  departments TEXT[],
  has_emergency_24 BOOLEAN DEFAULT false,
  notes TEXT,
  cover_image_url TEXT,
  gallery_image_urls TEXT[],
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- فهارس لتحسين الأداء
CREATE UNIQUE INDEX IF NOT EXISTS uq_private_hospitals_user_id ON private_hospitals(user_id);
CREATE INDEX IF NOT EXISTS idx_private_hospitals_is_published ON private_hospitals(is_published);
CREATE INDEX IF NOT EXISTS idx_private_hospitals_name ON private_hospitals(name);

-- Row Level Security (RLS)
ALTER TABLE private_hospitals ENABLE ROW LEVEL SECURITY;

-- السماح للجميع بقراءة المستشفيات المنشورة
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'private_hospitals'
      AND policyname = 'Anyone can view published private hospitals'
  ) THEN
    CREATE POLICY "Anyone can view published private hospitals"
      ON private_hospitals FOR SELECT
      USING (is_published = true);
  END IF;
END $$;

-- السماح لصاحب المستشفى بقراءة/إضافة/تعديل/حذف بياناته
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'private_hospitals'
      AND policyname = 'Hospital owners can view their own hospital'
  ) THEN
    CREATE POLICY "Hospital owners can view their own hospital"
      ON private_hospitals FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'private_hospitals'
      AND policyname = 'Hospital owners can insert their own hospital'
  ) THEN
    CREATE POLICY "Hospital owners can insert their own hospital"
      ON private_hospitals FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'private_hospitals'
      AND policyname = 'Hospital owners can update their own hospital'
  ) THEN
    CREATE POLICY "Hospital owners can update their own hospital"
      ON private_hospitals FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'private_hospitals'
      AND policyname = 'Hospital owners can delete their own hospital'
  ) THEN
    CREATE POLICY "Hospital owners can delete their own hospital"
      ON private_hospitals FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Trigger لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_private_hospitals_updated_at_column()
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
    WHERE tgname = 'update_private_hospitals_updated_at'
  ) THEN
    CREATE TRIGGER update_private_hospitals_updated_at
      BEFORE UPDATE ON private_hospitals
      FOR EACH ROW
      EXECUTE FUNCTION update_private_hospitals_updated_at_column();
  END IF;
END $$;

-- (اختياري) صلاحيات المديرين: فعّلها إذا كان لديك جدول admins
/*
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'private_hospitals'
      AND policyname = 'Admins can manage all private hospitals'
  ) THEN
    CREATE POLICY "Admins can manage all private hospitals"
      ON private_hospitals
      FOR ALL
      USING (
        EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid())
      )
      WITH CHECK (
        EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid())
      );
  END IF;
END $$;
*/
