-- Add pay-at-booking toggle to doctors
-- Allows doctors/admin to require payment at booking time

ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS is_pay_at_booking_enabled boolean NOT NULL DEFAULT false;

UPDATE public.doctors
SET is_pay_at_booking_enabled = false
WHERE is_pay_at_booking_enabled IS NULL;
