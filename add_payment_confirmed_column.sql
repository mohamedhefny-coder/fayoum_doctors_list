-- =====================================================
-- إضافة عمود تأكيد الدفع
-- =====================================================

BEGIN;

-- إضافة عمود payment_confirmed
ALTER TABLE public.appointments 
ADD COLUMN IF NOT EXISTS payment_confirmed BOOLEAN NOT NULL DEFAULT false;

-- إضافة عمود payment_confirmed_at
ALTER TABLE public.appointments 
ADD COLUMN IF NOT EXISTS payment_confirmed_at TIMESTAMP WITH TIME ZONE;

-- إضافة index للأداء
CREATE INDEX IF NOT EXISTS idx_appointments_payment_confirmed 
  ON public.appointments(payment_confirmed);

COMMIT;

-- التحقق
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'appointments'
AND column_name IN ('payment_confirmed', 'payment_confirmed_at');
