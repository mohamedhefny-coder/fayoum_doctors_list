-- =====================================================
-- إصلاح بسيط وواضح لسياسات RLS
-- =====================================================

BEGIN;

-- حذف كل السياسات القديمة
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'doctor_questions') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.doctor_questions', r.policyname);
    END LOOP;
END $$;

-- السياسة 1: أي شخص يمكنه إضافة سؤال
CREATE POLICY "allow_insert_questions"
  ON public.doctor_questions
  FOR INSERT
  WITH CHECK (true);

-- السياسة 2: أي شخص يمكنه قراءة الأسئلة المُجاب عليها فقط
CREATE POLICY "allow_read_answered_questions"
  ON public.doctor_questions
  FOR SELECT
  USING (is_answered = true);

-- السياسة 3: الأطباء المسجلين يمكنهم قراءة جميع أسئلتهم
-- الطريقة 1: إذا كان doctors.id == auth.uid()
CREATE POLICY "allow_doctors_read_own_questions_by_uid"
  ON public.doctor_questions
  FOR SELECT
  TO authenticated
  USING (doctor_id = auth.uid());

-- السياسة 4: الأطباء المسجلين يمكنهم قراءة أسئلتهم عبر البريد الإلكتروني
-- الطريقة 2: إذا كان البريد الإلكتروني متطابق
CREATE POLICY "allow_doctors_read_own_questions_by_email"
  ON public.doctor_questions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = auth.email()
    )
  );

-- السياسة 5: الأطباء يمكنهم تحديث أسئلتهم (الطريقة 1)
CREATE POLICY "allow_doctors_update_own_questions_by_uid"
  ON public.doctor_questions
  FOR UPDATE
  TO authenticated
  USING (doctor_id = auth.uid());

-- السياسة 6: الأطباء يمكنهم تحديث أسئلتهم (الطريقة 2)
CREATE POLICY "allow_doctors_update_own_questions_by_email"
  ON public.doctor_questions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = auth.email()
    )
  );

-- السياسة 7: الأطباء يمكنهم حذف أسئلتهم (الطريقة 1)
CREATE POLICY "allow_doctors_delete_own_questions_by_uid"
  ON public.doctor_questions
  FOR DELETE
  TO authenticated
  USING (doctor_id = auth.uid());

-- السياسة 8: الأطباء يمكنهم حذف أسئلتهم (الطريقة 2)
CREATE POLICY "allow_doctors_delete_own_questions_by_email"
  ON public.doctor_questions
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.doctors d
      WHERE d.id = doctor_questions.doctor_id
      AND d.email = auth.email()
    )
  );

COMMIT;

-- عرض السياسات الجديدة
SELECT 
  policyname,
  cmd,
  permissive,
  roles
FROM pg_policies
WHERE tablename = 'doctor_questions'
ORDER BY cmd, policyname;
