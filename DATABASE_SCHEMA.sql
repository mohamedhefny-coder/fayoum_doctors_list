-- ============================================
-- Supabase Database Schema for Doctors List App
-- ============================================

-- ============================================
-- جدول الأطباء (Doctors Table)
-- ============================================
CREATE TABLE IF NOT EXISTS public.doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  full_name TEXT,
  title TEXT,
  specialization TEXT NOT NULL,
  phone TEXT,
  license_number TEXT UNIQUE,
  bio TEXT,
  services TEXT,
  qualifications TEXT, -- المؤهلات والشهادات
  consultation_fee NUMERIC,
  gallery_image_urls TEXT[],
  article_url TEXT,
  intro_video_url TEXT,
  location TEXT, -- مهمل: استخدم geo_location بدلاً منه
  whatsapp_number TEXT,
  facebook_url TEXT,
  clinic_address TEXT,
  geo_location TEXT, -- تنسيق: "latitude,longitude"
  profile_image_url TEXT,
  rating NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- جدول التقييمات (Ratings Table)
-- ============================================
CREATE TABLE IF NOT EXISTS public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_id TEXT NOT NULL,
  rating_value NUMERIC NOT NULL CHECK (rating_value >= 1 AND rating_value <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- جدول المواعيد (Appointments Table) - اختياري
-- ============================================
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  patient_phone TEXT NOT NULL,
  appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
  appointment_time TIME NOT NULL,
  notes TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- جدول الفروع (Clinics/Branches) - اختياري
-- ============================================
CREATE TABLE IF NOT EXISTS public.clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  clinic_name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT NOT NULL,
  hours_from TEXT,
  hours_to TEXT,
  days_available TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- تفعيل Row Level Security (RLS)
-- ============================================

-- جدول الأطباء
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

-- السياسة: جميع المستخدمين يمكنهم قراءة بيانات الأطباء
CREATE POLICY "Public doctors are viewable by all"
  ON public.doctors
  FOR SELECT
  USING (true);

-- السياسة: الطبيب يمكنه تعديل بيانات حسابه فقط
CREATE POLICY "Doctors can update their own profile"
  ON public.doctors
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- السياسة: الطبيب يمكنه حذف حسابه فقط
CREATE POLICY "Doctors can delete their own profile"
  ON public.doctors
  FOR DELETE
  USING (auth.uid() = id);

-- السياسة: يمكن إدراج بيانات طبيب جديد أثناء التسجيل
CREATE POLICY "Anyone can insert a new doctor during signup"
  ON public.doctors
  FOR INSERT
  WITH CHECK (true);

-- جدول التقييمات
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- السياسة: جميع المستخدمين يمكنهم قراءة التقييمات
CREATE POLICY "Ratings are viewable by all"
  ON public.ratings
  FOR SELECT
  USING (true);

-- السياسة: أي شخص يمكنه إضافة تقييم
CREATE POLICY "Anyone can create a rating"
  ON public.ratings
  FOR INSERT
  WITH CHECK (true);

-- جدول المواعيد
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- السياسة: الطبيب يمكنه قراءة مواعيده فقط
CREATE POLICY "Doctors can see their appointments"
  ON public.appointments
  FOR SELECT
  USING (doctor_id = (SELECT id FROM public.doctors WHERE id = auth.uid()));

-- السياسة: أي شخص يمكنه إضافة موعد جديد
CREATE POLICY "Anyone can create an appointment"
  ON public.appointments
  FOR INSERT
  WITH CHECK (true);

-- السياسة: الطبيب يمكنه تحديث مواعيده
CREATE POLICY "Doctors can update their appointments"
  ON public.appointments
  FOR UPDATE
  USING (doctor_id = (SELECT id FROM public.doctors WHERE id = auth.uid()))
  WITH CHECK (doctor_id = (SELECT id FROM public.doctors WHERE id = auth.uid()));

-- جدول الفروع
ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;

-- السياسة: جميع المستخدمين يمكنهم قراءة بيانات الفروع
CREATE POLICY "Public clinics are viewable by all"
  ON public.clinics
  FOR SELECT
  USING (true);

-- السياسة: الطبيب يمكنه إدارة فروعه الخاصة
CREATE POLICY "Doctors can manage their clinics"
  ON public.clinics
  FOR ALL
  USING (doctor_id = auth.uid())
  WITH CHECK (doctor_id = auth.uid());

-- ============================================
-- الفهارس (Indexes) لتحسين الأداء
-- ============================================

CREATE INDEX IF NOT EXISTS idx_doctors_specialization ON public.doctors(specialization);
CREATE INDEX IF NOT EXISTS idx_doctors_location ON public.doctors(location);
CREATE INDEX IF NOT EXISTS idx_doctors_email ON public.doctors(email);
CREATE INDEX IF NOT EXISTS idx_ratings_doctor_id ON public.ratings(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON public.appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_clinics_doctor_id ON public.clinics(doctor_id);

-- ============================================
-- الدوال المساعدة (Helper Functions)
-- ============================================

-- دالة لتحديث معدل التقييم تلقائياً
CREATE OR REPLACE FUNCTION update_doctor_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.doctors
  SET rating = (
    SELECT AVG(rating_value) FROM public.ratings WHERE doctor_id = NEW.doctor_id
  )
  WHERE id = NEW.doctor_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تشغيل الدالة عند إضافة أو تحديث تقييم
CREATE TRIGGER trigger_update_doctor_rating
AFTER INSERT OR UPDATE ON public.ratings
FOR EACH ROW
EXECUTE FUNCTION update_doctor_rating();

-- ============================================
-- البيانات الافتراضية (Optional Sample Data)
-- ============================================

-- يمكنك إضافة بيانات تجريبية بعد إنشاء الجداول
-- INSERT INTO public.doctors (email, full_name, specialization, phone, license_number) VALUES
-- ('doctor1@example.com', 'د. أحمد محمد', 'طب عام', '+201234567890', 'LIC123456'),
-- ('doctor2@example.com', 'د. فاطمة علي', 'طب الأطفال', '+201234567891', 'LIC123457');
