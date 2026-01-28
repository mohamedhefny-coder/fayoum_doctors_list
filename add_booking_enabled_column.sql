-- Add ability to enable/disable in-app booking per doctor
-- Default: enabled

ALTER TABLE public.doctors
ADD COLUMN IF NOT EXISTS is_booking_enabled boolean NOT NULL DEFAULT true;

-- Optional: ensure existing rows are set
UPDATE public.doctors
SET is_booking_enabled = true
WHERE is_booking_enabled IS NULL;
