-- إضافة عمود عدد التقييمات إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'doctors' 
        AND column_name = 'rating_count'
    ) THEN
        ALTER TABLE doctors 
        ADD COLUMN rating_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- تحديث القيم الموجودة
UPDATE doctors 
SET rating_count = 0 
WHERE rating_count IS NULL;
