# إعداد جدول الأسئلة والاستفسارات

## المشكلة الحالية
رسالة خطأ عند إرسال الأسئلة: الجدول `doctor_questions` غير موجود في قاعدة البيانات.

## الحل - خطوتين فقط ⚡

### الخطوة 1️⃣ : إنشاء الجدول
افتح **Supabase Dashboard** → **SQL Editor** → انسخ والصق هذا الكود:

```sql
-- إنشاء جدول الأسئلة
CREATE TABLE IF NOT EXISTS public.doctor_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  patient_phone TEXT,
  question TEXT NOT NULL,
  answer TEXT,
  is_answered BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  answered_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- تفعيل RLS
ALTER TABLE public.doctor_questions ENABLE ROW LEVEL SECURITY;

-- سياسة: أي شخص يمكنه إضافة سؤال
CREATE POLICY "Anyone can ask questions"
  ON public.doctor_questions
  FOR INSERT
  WITH CHECK (true);

-- سياسة: أي شخص يمكنه رؤية الأسئلة المُجاب عليها
CREATE POLICY "Anyone can view answered questions"
  ON public.doctor_questions
  FOR SELECT
  USING (is_answered = true);

-- سياسة: الأطباء يرون جميع أسئلتهم
CREATE POLICY "Doctors can see all their questions"
  ON public.doctor_questions
  FOR SELECT
  USING (
    doctor_id = auth.uid() 
    OR 
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- سياسة: الأطباء يمكنهم تحديث أسئلتهم (الإجابة)
CREATE POLICY "Doctors can update their questions"
  ON public.doctor_questions
  FOR UPDATE
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- سياسة: الأطباء يمكنهم حذف أسئلتهم
CREATE POLICY "Doctors can delete their questions"
  ON public.doctor_questions
  FOR DELETE
  USING (
    doctor_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = (SELECT email FROM auth.users WHERE id = auth.uid())
    )
  );

-- إنشاء indexes للأداء
CREATE INDEX IF NOT EXISTS idx_doctor_questions_doctor_id 
  ON public.doctor_questions(doctor_id);

CREATE INDEX IF NOT EXISTS idx_doctor_questions_is_answered 
  ON public.doctor_questions(is_answered);
```

اضغط **Run** ▶️

### الخطوة 2️⃣ : إعادة تشغيل التطبيق
```bash
flutter run
```

## ✅ اختبار الميزة

1. **كمريض:**
   - افتح صفحة طبيب
   - اضغط على بطاقة "الأسئلة والاستفسارات"
   - اضغط زر ➕ "اطرح سؤالاً"
   - أدخل اسمك، رقمك، والسؤال
   - اضغط "إرسال"
   - يجب أن تظهر رسالة نجاح ✅

2. **كطبيب:**
   - افتح الملف الشخصي
   - انتقل لقسم "الأسئلة والاستفسارات"
   - سترى الأسئلة الجديدة باللون الأصفر 🟨
   - اضغط زر "✏️" للإجابة
   - اكتب الإجابة واضغط "حفظ"
   - يجب أن تتحول للون الأخضر 🟩

3. **التحقق من العرض العام:**
   - افتح صفحة الطبيب العامة
   - اضغط "الأسئلة والاستفسارات"
   - يجب أن تظهر الأسئلة المُجاب عليها فقط ✅

## ⚠️ ملاحظات مهمة

- الأسئلة **لا تظهر** للجمهور حتى يجيب عليها الطبيب
- الطبيب يرى **جميع** الأسئلة (المُجابة وغير المُجابة)
- المرضى يمكنهم إرسال أسئلة **بدون تسجيل دخول**

## 🔍 استكشاف الأخطاء

إذا استمرت المشكلة:
1. تأكد من تنفيذ SQL بنجاح (بدون errors)
2. تحقق من وجود الجدول: **Database** → **Tables** → `doctor_questions`
3. تحقق من RLS Policies في صفحة الجدول

## 📁 الملفات ذات الصلة
- `add_doctor_questions_table.sql` - الملف الكامل (اختياري)
- `fix_doctor_questions_rls.sql` - تم تطبيقه بالفعل
