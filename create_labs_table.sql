-- جدول المعامل الطبية
CREATE TABLE labs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  whatsapp TEXT,
  email TEXT,
  working_hours TEXT,
  offers TEXT,
  contracts TEXT,
  rating REAL DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  features TEXT[], -- مصفوفة المميزات
  tests JSONB, -- التحاليل المتاحة في شكل JSON
  latitude REAL,
  longitude REAL,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء index لتحسين الأداء
CREATE INDEX idx_labs_user_id ON labs(user_id);
CREATE INDEX idx_labs_is_published ON labs(is_published);
CREATE INDEX idx_labs_name ON labs(name);

-- Row Level Security (RLS)
ALTER TABLE labs ENABLE ROW LEVEL SECURITY;

-- السماح للجميع بقراءة المعامل المنشورة
CREATE POLICY "Anyone can view published labs"
  ON labs FOR SELECT
  USING (is_published = true);

-- السماح لصاحب المعمل بقراءة وتعديل معمله
CREATE POLICY "Lab owners can view their own labs"
  ON labs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Lab owners can update their own labs"
  ON labs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Lab owners can insert their own labs"
  ON labs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Lab owners can delete their own labs"
  ON labs FOR DELETE
  USING (auth.uid() = user_id);

-- ملاحظة: إذا كنت تريد إضافة صلاحيات للمدراء، قم بإنشاء جدول admins أولاً
-- ثم قم بتفعيل الـ policies التالية:
/*
CREATE POLICY "Admins can view all labs"
  ON labs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admins WHERE admins.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update all labs"
  ON labs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admins WHERE admins.user_id = auth.uid()
    )
  );
*/

-- دالة لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_labs_updated_at
  BEFORE UPDATE ON labs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
