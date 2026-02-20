-- =====================================================
-- SUPABASE SQL SETUP: PROJECTS TABLE
-- =====================================================
-- Tabel ini menyimpan data project yang pernah dikerjakan mahasiswa
-- 
-- CARA PENGGUNAAN:
-- 1. Buka Supabase Dashboard > SQL Editor
-- 2. Copy & paste seluruh file ini
-- 3. Klik "Run" untuk eksekusi
-- 
-- Author: Synergy App
-- Created: 2026-02-18
-- =====================================================

-- =====================================================
-- 1. CREATE TABLE: projects
-- =====================================================
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Project Information
    title TEXT NOT NULL,
    overview TEXT,
    role TEXT NOT NULL,
    
    -- Project Timeline
    start_date DATE NOT NULL,
    end_date DATE,  -- NULL if project is ongoing
    
    -- Technical Details
    technologies TEXT[],  -- Array of technologies used
    
    -- Links
    project_url TEXT,  -- Link to demo/live project
    repository_url TEXT,  -- Link to GitHub/GitLab repository
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT title_not_empty CHECK (char_length(trim(title)) > 0),
    CONSTRAINT role_not_empty CHECK (char_length(trim(role)) > 0)
);

-- =====================================================
-- 2. CREATE INDEXES
-- =====================================================

-- Index untuk query by user_id (paling sering digunakan)
CREATE INDEX IF NOT EXISTS idx_projects_user_id 
ON public.projects(user_id);

-- Index untuk sorting by start_date
CREATE INDEX IF NOT EXISTS idx_projects_start_date 
ON public.projects(start_date DESC);

-- Index untuk sorting by end_date
CREATE INDEX IF NOT EXISTS idx_projects_end_date 
ON public.projects(end_date DESC NULLS FIRST);

-- Index untuk filter ongoing projects (end_date IS NULL)
CREATE INDEX IF NOT EXISTS idx_projects_ongoing 
ON public.projects(user_id, end_date) 
WHERE end_date IS NULL;

-- Index untuk full-text search pada title, overview, dan role
CREATE INDEX IF NOT EXISTS idx_projects_search 
ON public.projects USING GIN (
    to_tsvector('english', 
        COALESCE(title, '') || ' ' || 
        COALESCE(overview, '') || ' ' || 
        COALESCE(role, '')
    )
);

-- Index untuk search by technologies (GIN index untuk array)
CREATE INDEX IF NOT EXISTS idx_projects_technologies 
ON public.projects USING GIN (technologies);

-- Composite index untuk kombinasi user_id + start_date (optimasi listing)
CREATE INDEX IF NOT EXISTS idx_projects_user_start 
ON public.projects(user_id, start_date DESC);

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can view their own projects
CREATE POLICY "Users can view own projects"
ON public.projects
FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Users can insert their own projects
CREATE POLICY "Users can insert own projects"
ON public.projects
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can update their own projects
CREATE POLICY "Users can update own projects"
ON public.projects
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy 4: Users can delete their own projects
CREATE POLICY "Users can delete own projects"
ON public.projects
FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- 4. TRIGGER: Auto-update updated_at
-- =====================================================

-- Function untuk update timestamp
CREATE OR REPLACE FUNCTION public.update_projects_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger yang memanggil function di atas
CREATE TRIGGER trigger_update_projects_timestamp
    BEFORE UPDATE ON public.projects
    FOR EACH ROW
    EXECUTE FUNCTION public.update_projects_updated_at();

-- =====================================================
-- 5. HELPFUL VIEWS (Optional)
-- =====================================================

-- View untuk ongoing projects dengan durasi
CREATE OR REPLACE VIEW public.v_ongoing_projects AS
SELECT 
    p.*,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.start_date)) * 12 + 
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, p.start_date)) AS duration_months,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.start_date)) * 12 + 
             EXTRACT(MONTH FROM AGE(CURRENT_DATE, p.start_date)) < 1 THEN '< 1 bulan'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.start_date)) * 12 + 
             EXTRACT(MONTH FROM AGE(CURRENT_DATE, p.start_date)) < 12 THEN 
             (EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.start_date)) * 12 + 
              EXTRACT(MONTH FROM AGE(CURRENT_DATE, p.start_date)))::TEXT || ' bulan'
        ELSE 
             TRUNC(EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.start_date)) * 12 + 
                   EXTRACT(MONTH FROM AGE(CURRENT_DATE, p.start_date)) / 12)::TEXT || ' tahun'
    END AS duration_display
FROM public.projects p
WHERE p.end_date IS NULL;

-- View untuk completed projects dengan durasi
CREATE OR REPLACE VIEW public.v_completed_projects AS
SELECT 
    p.*,
    EXTRACT(YEAR FROM AGE(p.end_date, p.start_date)) * 12 + 
    EXTRACT(MONTH FROM AGE(p.end_date, p.start_date)) AS duration_months,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(p.end_date, p.start_date)) * 12 + 
             EXTRACT(MONTH FROM AGE(p.end_date, p.start_date)) < 1 THEN '< 1 bulan'
        WHEN EXTRACT(YEAR FROM AGE(p.end_date, p.start_date)) * 12 + 
             EXTRACT(MONTH FROM AGE(p.end_date, p.start_date)) < 12 THEN 
             (EXTRACT(YEAR FROM AGE(p.end_date, p.start_date)) * 12 + 
              EXTRACT(MONTH FROM AGE(p.end_date, p.start_date)))::TEXT || ' bulan'
        ELSE 
             TRUNC(EXTRACT(YEAR FROM AGE(p.end_date, p.start_date)) * 12 + 
                   EXTRACT(MONTH FROM AGE(p.end_date, p.start_date)) / 12)::TEXT || ' tahun'
    END AS duration_display
FROM public.projects p
WHERE p.end_date IS NOT NULL;

-- =====================================================
-- 6. VERIFICATION QUERIES
-- =====================================================

-- Uncomment untuk verifikasi setelah setup:

-- Check table structure
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'projects' AND table_schema = 'public'
-- ORDER BY ordinal_position;

-- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'projects' AND schemaname = 'public';

-- Check RLS policies
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'projects' AND schemaname = 'public';

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- Table 'projects' berhasil dibuat dengan:
-- ✓ 11 kolom (id, user_id, title, overview, role, start_date, end_date, 
--              technologies, project_url, repository_url, timestamps)
-- ✓ 7 indexes (user_id, dates, ongoing, search, technologies, composite)
-- ✓ 4 RLS policies (SELECT, INSERT, UPDATE, DELETE)
-- ✓ 1 trigger (auto-update updated_at)
-- ✓ 2 helpful views (ongoing & completed projects)
-- 
-- NEXT STEPS:
-- 1. Verify table: SELECT * FROM projects LIMIT 1;
-- 2. Test insert from Flutter app
-- 3. Monitor query performance with EXPLAIN ANALYZE
-- =====================================================
