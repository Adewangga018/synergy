-- ============================================
-- SETUP PROFILE PHOTO - SIMPLE VERSION
-- ============================================

-- STEP 1: Tambahkan kolom photo_url ke table profiles
-- ============================================
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- ============================================
-- STEP 2: Setup Storage Bucket via Dashboard
-- ============================================
-- 
-- 1. Buka Supabase Dashboard → Storage
-- 2. Create New Bucket:
--    - Name: avatars
--    - Public: YES ✅
-- 
-- 3. Set Policies (di bucket settings):
--    - Public Access: ON
--    - Allowed MIME types: image/*
-- 
-- SELESAI! Aplikasi siap digunakan.
-- 
-- ============================================

-- ============================================
-- VERIFICATION (Optional)
-- ============================================

-- Check if photo_url column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'photo_url';

-- Check existing photo URLs
SELECT id, nama_lengkap, photo_url 
FROM public.profiles 
LIMIT 10;
