-- جدول مراكز الأشعة
CREATE TABLE radiology_centers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  whatsapp TEXT,
  facebook TEXT,
  location_url TEXT,
  email TEXT,
  working_hours TEXT,
  is_open_24_hours BOOLEAN DEFAULT false,
  services TEXT[],
  features TEXT,
  discounts TEXT,
  contracts TEXT,
  has_booking BOOLEAN DEFAULT false,
  doctors JSONB,
  rating REAL DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء indexes لتحسين الأداء
CREATE INDEX idx_radiology_centers_user_id ON radiology_centers(user_id);
CREATE INDEX idx_radiology_centers_is_published ON radiology_centers(is_published);
CREATE INDEX idx_radiology_centers_name ON radiology_centers(name);

-- Row Level Security (RLS)
ALTER TABLE radiology_centers ENABLE ROW LEVEL SECURITY;

-- السماح للجميع بقراءة المراكز المنشورة
CREATE POLICY "allow_read_published_centers"
  ON radiology_centers FOR SELECT
  USING (is_published = true);

-- السماح لصاحب المركز بقراءة وتعديل بياناته
CREATE POLICY "allow_owner_all"
  ON radiology_centers FOR ALL
  USING (auth.uid() = user_id);

-- السماح بالإدراج لأي مستخدم مسجل
CREATE POLICY "allow_insert_authenticated"
  ON radiology_centers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_radiology_centers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_radiology_centers_updated_at
  BEFORE UPDATE ON radiology_centers
  FOR EACH ROW
  EXECUTE FUNCTION update_radiology_centers_updated_at();
