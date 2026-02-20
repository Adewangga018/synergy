-- =====================================================
-- MIGRATION: Remove columns from course_schedules
-- =====================================================
-- Script ini menghapus kolom academic_year_id dan google_calendar_event
-- dari tabel course_schedules
-- 
-- CARA PENGGUNAAN:
-- 1. Buka Supabase Dashboard > SQL Editor
-- 2. Copy & paste seluruh file ini
-- 3. Klik "Run" untuk eksekusi
-- 
-- Created: 2026-02-18
-- =====================================================

-- =====================================================
-- 1. DROP COLUMNS
-- =====================================================

-- Hapus foreign key constraint jika ada
ALTER TABLE IF EXISTS public.course_schedules 
  DROP CONSTRAINT IF EXISTS course_schedules_academic_year_id_fkey;

-- Hapus kolom academic_year_id
ALTER TABLE IF EXISTS public.course_schedules 
  DROP COLUMN IF EXISTS academic_year_id;

-- Hapus kolom google_calendar_event
ALTER TABLE IF EXISTS public.course_schedules 
  DROP COLUMN IF EXISTS google_calendar_event;

-- =====================================================
-- 2. DROP INDEXES (jika ada)
-- =====================================================

-- Drop index untuk academic_year_id (jika ada)
DROP INDEX IF EXISTS public.idx_course_schedules_academic_year_id;

-- Drop index untuk google_calendar_event (jika ada)
DROP INDEX IF EXISTS public.idx_course_schedules_google_calendar_event;

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

-- Uncomment untuk verifikasi struktur tabel setelah perubahan:

-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'course_schedules' 
--   AND table_schema = 'public'
-- ORDER BY ordinal_position;

-- =====================================================
-- MIGRATION COMPLETE!
-- =====================================================
-- Kolom berikut telah dihapus dari tabel course_schedules:
-- ✓ academic_year_id
-- ✓ google_calendar_event
-- 
-- CATATAN:
-- - Pastikan tidak ada kode aplikasi yang masih menggunakan kolom ini
-- - Backup database sebelum menjalankan migration di production
-- =====================================================
