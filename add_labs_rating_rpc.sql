-- RPC: Rate a lab and update its average rating + rating_count.
-- Run this in Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.rate_lab(
  lab_id uuid,
  rating_value integer
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
  v_value integer := GREATEST(1, LEAST(5, rating_value));
BEGIN
  UPDATE public.labs
  SET
    rating_count = COALESCE(rating_count, 0) + 1,
    rating = CASE
      WHEN COALESCE(rating_count, 0) = 0 THEN v_value
      ELSE (
        (COALESCE(rating, 0) * COALESCE(rating_count, 0)) + v_value
      )::real / (COALESCE(rating_count, 0) + 1)
    END
  WHERE id = lab_id
  RETURNING public.labs.rating,
            public.labs.rating_count
  INTO rating, rating_count;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lab not found';
  END IF;

  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.rate_lab(uuid, integer) TO anon, authenticated;
