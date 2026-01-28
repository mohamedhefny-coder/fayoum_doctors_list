-- Add payment receipt URL column to appointments table

ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_receipt_url text;

COMMENT ON COLUMN public.appointments.payment_receipt_url IS 'URL to the uploaded payment receipt image';
