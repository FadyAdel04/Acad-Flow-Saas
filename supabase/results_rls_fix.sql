-- ==============================================================================
-- FIX: results table – RLS INSERT policy + nullable score
-- Run this in: Supabase Dashboard → SQL Editor
-- ==============================================================================

-- 1. Make score nullable so "pending_review" exams (with writing) can insert NULL score.
ALTER TABLE public.results ALTER COLUMN score DROP NOT NULL;

-- 2. Drop ALL existing policies on results to start clean
--    (avoids conflicts between schema.sql, supabase_rls_fix.sql, exam_review_workflow.sql)
DROP POLICY IF EXISTS "results: student reads own"         ON public.results;
DROP POLICY IF EXISTS "results: student inserts own"       ON public.results;
DROP POLICY IF EXISTS "results: admin full"                ON public.results;
DROP POLICY IF EXISTS "Instructors can view results"       ON public.results;
DROP POLICY IF EXISTS "results: student updates own"       ON public.results;
DROP POLICY IF EXISTS "results: instructor reads"          ON public.results;

-- 3. Make sure RLS is enabled
ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;

-- 4. Students can read their own results
CREATE POLICY "results: student reads own"
  ON public.results FOR SELECT
  USING ( auth.uid() = student_id );

-- 5. Students can insert their OWN result row (exam submission)
--    This is the critical policy that fixes the "new row violates RLS" error.
CREATE POLICY "results: student inserts own"
  ON public.results FOR INSERT
  WITH CHECK ( auth.uid() = student_id );

-- 6. Admins have full access to all results
CREATE POLICY "results: admin full"
  ON public.results FOR ALL
  USING ( public.is_admin() )
  WITH CHECK ( public.is_admin() );

-- 7. Instructors can view results (read-only)
CREATE POLICY "results: instructor reads"
  ON public.results FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'instructor'
    )
  );

-- Done ✅
