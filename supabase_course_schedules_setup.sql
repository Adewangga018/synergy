-- =====================================================
-- SUPABASE SQL SETUP: COURSE_SCHEDULES TABLE
-- =====================================================
-- Tabel ini menyimpan jadwal perkuliahan mahasiswa
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
-- 1. CREATE ENUM TYPES
-- =====================================================

-- Enum untuk hari dalam seminggu
DO $$ BEGIN
    CREATE TYPE public.day_of_week AS ENUM (
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Enum untuk tipe kelas
DO $$ BEGIN
    CREATE TYPE public.class_type AS ENUM (
        'lecture',
        'lab',
        'seminar',
        'workshop',
        'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- 2. DROP EXISTING TABLE (if exists)
-- =====================================================
DROP TABLE IF EXISTS public.course_schedules CASCADE;

-- =====================================================
-- 3. CREATE TABLE: course_schedules
-- =====================================================
CREATE TABLE public.course_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Course Information
    course_name TEXT NOT NULL,
    course_code TEXT NOT NULL,
    lecturer TEXT NOT NULL,
    
    -- Schedule Details
    day_of_week public.day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room TEXT NOT NULL,
    
    -- Academic Details
    semester INTEGER NOT NULL CHECK (semester >= 1 AND semester <= 8),
    credits INTEGER NOT NULL CHECK (credits >= 1 AND credits <= 6),
    class_type public.class_type NOT NULL DEFAULT 'lecture',
    
    -- Additional Info
    notes TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_time_range CHECK (end_time > start_time),
    CONSTRAINT course_name_not_empty CHECK (char_length(trim(course_name)) > 0),
    CONSTRAINT course_code_not_empty CHECK (char_length(trim(course_code)) > 0)
);

-- =====================================================
-- 4. CREATE INDEXES
-- =====================================================

-- Index untuk query by user_id (paling sering)
CREATE INDEX IF NOT EXISTS idx_course_schedules_user_id 
ON public.course_schedules(user_id);

-- Index untuk sorting & filtering by day
CREATE INDEX IF NOT EXISTS idx_course_schedules_day 
ON public.course_schedules(day_of_week);

-- Index untuk sorting by start_time
CREATE INDEX IF NOT EXISTS idx_course_schedules_start_time 
ON public.course_schedules(start_time);

-- Index untuk filter by semester
CREATE INDEX IF NOT EXISTS idx_course_schedules_semester 
ON public.course_schedules(semester);

-- Index untuk filter by class_type
CREATE INDEX IF NOT EXISTS idx_course_schedules_class_type 
ON public.course_schedules(class_type);

-- Composite index untuk optimasi weekly view (user + day + time)
CREATE INDEX IF NOT EXISTS idx_course_schedules_weekly_view 
ON public.course_schedules(user_id, day_of_week, start_time);

-- Composite index untuk semester filtering (user + semester)
CREATE INDEX IF NOT EXISTS idx_course_schedules_semester_view 
ON public.course_schedules(user_id, semester);

-- Index untuk full-text search
CREATE INDEX IF NOT EXISTS idx_course_schedules_search 
ON public.course_schedules USING GIN (
    to_tsvector('english', 
        COALESCE(course_name, '') || ' ' || 
        COALESCE(course_code, '') || ' ' || 
        COALESCE(lecturer, '') || ' ' ||
        COALESCE(room, '')
    )
);

-- =====================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.course_schedules ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can view their own schedules
CREATE POLICY "Users can view own schedules"
ON public.course_schedules
FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Users can insert their own schedules
CREATE POLICY "Users can insert own schedules"
ON public.course_schedules
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can update their own schedules
CREATE POLICY "Users can update own schedules"
ON public.course_schedules
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy 4: Users can delete their own schedules
CREATE POLICY "Users can delete own schedules"
ON public.course_schedules
FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- 6. TRIGGER: Auto-update updated_at
-- =====================================================

-- Function untuk update timestamp
CREATE OR REPLACE FUNCTION public.update_course_schedules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger yang memanggil function di atas
CREATE TRIGGER trigger_update_course_schedules_timestamp
    BEFORE UPDATE ON public.course_schedules
    FOR EACH ROW
    EXECUTE FUNCTION public.update_course_schedules_updated_at();

-- =====================================================
-- 7. HELPFUL VIEWS (Optional)
-- =====================================================

-- View untuk jadwal hari ini
CREATE OR REPLACE VIEW public.v_today_schedules AS
SELECT 
    cs.*,
    EXTRACT(EPOCH FROM (cs.end_time - cs.start_time))/60 AS duration_minutes
FROM public.course_schedules cs
WHERE cs.day_of_week = CASE EXTRACT(DOW FROM CURRENT_DATE)
    WHEN 0 THEN 'sunday'::public.day_of_week
    WHEN 1 THEN 'monday'::public.day_of_week
    WHEN 2 THEN 'tuesday'::public.day_of_week
    WHEN 3 THEN 'wednesday'::public.day_of_week
    WHEN 4 THEN 'thursday'::public.day_of_week
    WHEN 5 THEN 'friday'::public.day_of_week
    WHEN 6 THEN 'saturday'::public.day_of_week
END
ORDER BY cs.start_time;

-- View untuk statistik SKS per semester
CREATE OR REPLACE VIEW public.v_credits_per_semester AS
SELECT 
    user_id,
    semester,
    COUNT(*) AS total_courses,
    SUM(credits) AS total_credits
FROM public.course_schedules
GROUP BY user_id, semester
ORDER BY user_id, semester;

-- =====================================================
-- 8. HELPER FUNCTIONS
-- =====================================================

-- Function untuk cek time conflict
CREATE OR REPLACE FUNCTION public.check_schedule_conflict(
    p_user_id UUID,
    p_day_of_week public.day_of_week,
    p_start_time TIME,
    p_end_time TIME,
    p_exclude_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_conflict_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_conflict_count
    FROM public.course_schedules
    WHERE user_id = p_user_id
        AND day_of_week = p_day_of_week
        AND (id != p_exclude_id OR p_exclude_id IS NULL)
        AND (
            (start_time <= p_start_time AND end_time > p_start_time) OR
            (start_time < p_end_time AND end_time >= p_end_time) OR
            (start_time >= p_start_time AND end_time <= p_end_time)
        );
    
    RETURN v_conflict_count > 0;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. VERIFICATION QUERIES
-- =====================================================

-- Uncomment untuk verifikasi setelah setup:

-- Check table structure
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'course_schedules' AND table_schema = 'public'
-- ORDER BY ordinal_position;

-- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'course_schedules' AND schemaname = 'public';

-- Check RLS policies
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'course_schedules' AND schemaname = 'public';

-- Check enum types
-- SELECT enumlabel 
-- FROM pg_enum 
-- WHERE enumtypid = 'public.day_of_week'::regtype
-- ORDER BY enumsortorder;

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- Table 'course_schedules' berhasil dibuat dengan:
-- ✓ 2 ENUM types (day_of_week, class_type)
-- ✓ 13 kolom (id, user_id, course details, schedule, academic, notes, timestamps)
-- ✓ 8 indexes (user_id, day, time, semester, class_type, composites, search)
-- ✓ 4 RLS policies (SELECT, INSERT, UPDATE, DELETE)
-- ✓ 1 trigger (auto-update updated_at)
-- ✓ 2 helpful views (today's schedule, credits per semester)
-- ✓ 1 helper function (conflict detection)
-- 
-- CATATAN PENTING:
-- ❌ Kolom academic_year_id TIDAK DIBUAT (sesuai request)
-- ❌ Kolom google_calendar_event TIDAK DIBUAT (sesuai request)
-- 
-- NEXT STEPS:
-- 1. Verify table: SELECT * FROM course_schedules LIMIT 1;
-- 2. Test insert from Flutter app
-- 3. Optional: Implement conflict detection in app
-- 4. Monitor query performance with EXPLAIN ANALYZE
-- =====================================================
