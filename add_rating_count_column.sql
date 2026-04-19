-- إضافة عمود عدد التقييمات إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public'
        AND table_name = 'doctors' 
        AND column_name = 'rating'
    ) THEN
        ALTER TABLE public.doctors 
        ADD COLUMN rating REAL DEFAULT 0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public'
        AND table_name = 'doctors' 
        AND column_name = 'rating_count'
    ) THEN
        ALTER TABLE public.doctors 
        ADD COLUMN rating_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- تحديث القيم الموجودة
UPDATE public.doctors 
SET rating_count = 0 
WHERE rating_count IS NULL;

UPDATE public.doctors
SET rating = 0
WHERE rating IS NULL;
