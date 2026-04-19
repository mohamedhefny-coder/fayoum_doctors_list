-- ============================================================
-- RPC: Submit a medical center review + update rating/rating_count
-- دالة: إرسال تقييم مركز طبي وتحديث متوسط التقييم وعدد التقييمات
-- Run in Supabase SQL Editor.
-- ============================================================

CREATE OR REPLACE FUNCTION public.submit_medical_center_review(
  center_id uuid,
  reviewer_name text,
  rating_value numeric,
  reviewer_phone text DEFAULT NULL,
  review_text text DEFAULT NULL
)
RETURNS TABLE (
  rating real,
  rating_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_value numeric := GREATEST(1, LEAST(5, rating_value));
  v_review_text text := NULLIF(BTRIM(review_text), '');
BEGIN
  -- Insert approved review
  INSERT INTO public.medical_center_reviews(
    center_id,
    reviewer_name,
    reviewer_phone,
    rating,
    review_text,
    status,
    approved_at
  ) VALUES (
    center_id,
    BTRIM(reviewer_name),
    NULLIF(BTRIM(reviewer_phone), ''),
    v_value,
    v_review_text,
    'approved',
    NOW()
  );

  -- Update rolling average (only for published centers)
  UPDATE public.medical_centers
  SET
    rating_count = COALESCE(rating_count, 0) + 1,
    rating = CASE
      WHEN COALESCE(rating_count, 0) = 0 THEN v_value::real
      ELSE (
        (COALESCE(rating, 0) * COALESCE(rating_count, 0)) + v_value
      )::real / (COALESCE(rating_count, 0) + 1)
    END,
    updated_at = NOW()
  WHERE id = center_id
    AND is_published = true
  RETURNING public.medical_centers.rating,
            public.medical_centers.rating_count
  INTO rating, rating_count;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Medical center not found or not published';
  END IF;

  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_medical_center_review(uuid, text, numeric, text, text)
  TO anon, authenticated;
