-- ============================================
-- SETUP ALL ACTIVITY TRACKING TABLES
-- ============================================
-- Tables: academic_years, competitions, volunteer_activities, organizations
-- ============================================

-- ============================================
-- TABLE: academic_years
-- ============================================

CREATE TABLE IF NOT EXISTS public.academic_years (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  semester_name text NOT NULL,
  start_date date NOT NULL,
  total_active_weeks integer NOT NULL DEFAULT 16,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT academic_years_pkey PRIMARY KEY (id),
  CONSTRAINT academic_years_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- ============================================
-- TABLE: competitions
-- ============================================

CREATE TABLE IF NOT EXISTS public.competitions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  comp_name text NOT NULL,
  category text,
  achievement text,
  event_date date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT competitions_pkey PRIMARY KEY (id),
  CONSTRAINT competitions_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- ============================================
-- TABLE: volunteer_activities
-- ============================================

CREATE TABLE IF NOT EXISTS public.volunteer_activities (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  activity_name text NOT NULL,
  role text NOT NULL,
  start_date date,
  end_date date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT volunteer_activities_pkey PRIMARY KEY (id),
  CONSTRAINT volunteer_activities_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- ============================================
-- TABLE: organizations
-- ============================================

CREATE TABLE IF NOT EXISTS public.organizations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  academic_year_id uuid,
  org_name text NOT NULL,
  scale text CHECK (scale = ANY (ARRAY['department'::text, 'faculty'::text, 'campus'::text, 'external'::text])),
  position text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT organizations_pkey PRIMARY KEY (id),
  CONSTRAINT organizations_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT organizations_academic_year_id_fkey FOREIGN KEY (academic_year_id) 
    REFERENCES public.academic_years(id) ON DELETE SET NULL
);

-- ============================================
-- INDEXES untuk performa
-- ============================================

-- Indexes untuk academic_years
CREATE INDEX IF NOT EXISTS academic_years_user_id_idx 
  ON public.academic_years(user_id);
CREATE INDEX IF NOT EXISTS academic_years_start_date_idx 
  ON public.academic_years(start_date DESC);
CREATE INDEX IF NOT EXISTS academic_years_is_active_idx 
  ON public.academic_years(is_active);

-- Indexes untuk competitions
CREATE INDEX IF NOT EXISTS competitions_user_id_idx 
  ON public.competitions(user_id);
CREATE INDEX IF NOT EXISTS competitions_event_date_idx 
  ON public.competitions(event_date DESC);
CREATE INDEX IF NOT EXISTS competitions_category_idx 
  ON public.competitions(category);

-- Indexes untuk volunteer_activities
CREATE INDEX IF NOT EXISTS volunteer_activities_user_id_idx 
  ON public.volunteer_activities(user_id);
CREATE INDEX IF NOT EXISTS volunteer_activities_created_at_idx 
  ON public.volunteer_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS volunteer_activities_end_date_idx 
  ON public.volunteer_activities(end_date);

-- Indexes untuk organizations
CREATE INDEX IF NOT EXISTS organizations_user_id_idx 
  ON public.organizations(user_id);
CREATE INDEX IF NOT EXISTS organizations_scale_idx 
  ON public.organizations(scale);
CREATE INDEX IF NOT EXISTS organizations_created_at_idx 
  ON public.organizations(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) - academic_years
-- ============================================

ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT
CREATE POLICY "Users can view their own academic years"
ON public.academic_years FOR SELECT
USING (auth.uid() = user_id);

-- Policy: INSERT
CREATE POLICY "Users can insert their own academic years"
ON public.academic_years FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: UPDATE
CREATE POLICY "Users can update their own academic years"
ON public.academic_years FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: DELETE
CREATE POLICY "Users can delete their own academic years"
ON public.academic_years FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) - competitions
-- ============================================

ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT
CREATE POLICY "Users can view their own competitions"
ON public.competitions FOR SELECT
USING (auth.uid() = user_id);

-- Policy: INSERT
CREATE POLICY "Users can insert their own competitions"
ON public.competitions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: UPDATE
CREATE POLICY "Users can update their own competitions"
ON public.competitions FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: DELETE
CREATE POLICY "Users can delete their own competitions"
ON public.competitions FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) - volunteer_activities
-- ============================================

ALTER TABLE public.volunteer_activities ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT
CREATE POLICY "Users can view their own volunteer activities"
ON public.volunteer_activities FOR SELECT
USING (auth.uid() = user_id);

-- Policy: INSERT
CREATE POLICY "Users can insert their own volunteer activities"
ON public.volunteer_activities FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: UPDATE
CREATE POLICY "Users can update their own volunteer activities"
ON public.volunteer_activities FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: DELETE
CREATE POLICY "Users can delete their own volunteer activities"
ON public.volunteer_activities FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) - organizations
-- ============================================

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT
CREATE POLICY "Users can view their own organizations"
ON public.organizations FOR SELECT
USING (auth.uid() = user_id);

-- Policy: INSERT
CREATE POLICY "Users can insert their own organizations"
ON public.organizations FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: UPDATE
CREATE POLICY "Users can update their own organizations"
ON public.organizations FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: DELETE
CREATE POLICY "Users can delete their own organizations"
ON public.organizations FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- VERIFICATION
-- ============================================

-- Check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('academic_years', 'competitions', 'volunteer_activities', 'organizations')
ORDER BY table_name;

-- Check RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('academic_years', 'competitions', 'volunteer_activities', 'organizations')
ORDER BY tablename;

-- Check policies for academic_years
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'academic_years'
ORDER BY cmd;

-- Check policies for competitions
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'competitions'
ORDER BY cmd;

-- Check policies for volunteer_activities
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'volunteer_activities'
ORDER BY cmd;

-- Check policies for organizations
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'organizations'
ORDER BY cmd;

-- Sample data check
SELECT 'academic_years' as table_name, COUNT(*) as total FROM public.academic_years
UNION ALL
SELECT 'competitions' as table_name, COUNT(*) as total FROM public.competitions
UNION ALL
SELECT 'volunteer_activities' as table_name, COUNT(*) as total FROM public.volunteer_activities
UNION ALL
SELECT 'organizations' as table_name, COUNT(*) as total FROM public.organizations;
