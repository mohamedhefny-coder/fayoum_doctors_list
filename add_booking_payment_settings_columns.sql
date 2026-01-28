-- Booking/Payment settings for doctor profile

ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS is_cancel_booking_enabled_at_payment boolean NOT NULL DEFAULT false;

ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS payment_method text;

ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS payment_account text;

UPDATE public.doctors
SET is_cancel_booking_enabled_at_payment = false
WHERE is_cancel_booking_enabled_at_payment IS NULL;
