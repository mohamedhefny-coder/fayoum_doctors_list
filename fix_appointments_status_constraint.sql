-- =====================================================
-- Fix appointments status constraint
-- Changes status values to: 'pending', 'accepted', 'rejected'
-- =====================================================

-- Drop the old constraint
ALTER TABLE public.appointments 
DROP CONSTRAINT IF EXISTS appointments_status_check;

-- Add the new constraint with correct status values
ALTER TABLE public.appointments 
ADD CONSTRAINT appointments_status_check 
CHECK (status IN ('pending', 'accepted', 'rejected'));

-- Update any existing appointments with old status values
UPDATE public.appointments 
SET status = 'accepted' 
WHERE status = 'confirmed' OR status = 'completed';

UPDATE public.appointments 
SET status = 'rejected' 
WHERE status = 'cancelled';

-- Verify the change
SELECT DISTINCT status FROM public.appointments;
