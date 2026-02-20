-- Script untuk memperbaiki masalah RLS Policy dan data yang tidak konsisten
-- Jalankan script ini di Supabase SQL Editor jika mengalami masalah login

-- ============================================================
-- BAGIAN 1: PERBAIKAN RLS POLICY
-- ============================================================

-- 1. Hapus policy yang mungkin conflict
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can read email for login" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated users to insert profile" ON public.profiles;

-- 2. Buat policy SELECT yang mengizinkan siapa saja membaca (untuk login dengan NRP)
-- Policy ini penting agar user bisa cari email berdasarkan NRP sebelum login
CREATE POLICY "Anyone can read profiles for login"
    ON public.profiles
    FOR SELECT
    USING (true);

-- 3. Buat ulang policy INSERT yang memungkinkan authenticated user insert data
CREATE POLICY "Allow authenticated users to insert profile"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- 4. Pastikan policy UPDATE tetap secure
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- BAGIAN 2: CEK DATA YANG TIDAK KONSISTEN
-- ============================================================

-- Cek user yang ada di auth tapi tidak ada di profiles
-- (Jalankan query ini untuk melihat masalahnya)
SELECT 
    au.id,
    au.email,
    au.created_at,
    CASE 
        WHEN p.id IS NULL THEN 'MISSING IN PROFILES'
        ELSE 'OK'
    END as status
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- ============================================================
-- BAGIAN 3: MEMBERSIHKAN DATA (OPSIONAL)
-- ============================================================

-- HATI-HATI! Script ini akan menghapus user yang tidak punya profile
-- Hanya jalankan jika Anda ingin membersihkan data yang tidak konsisten
-- Uncomment baris di bawah untuk menjalankan

/*
-- Hapus user dari auth.users yang tidak punya profile
-- User ini harus register ulang
DELETE FROM auth.users
WHERE id IN (
    SELECT au.id
    FROM auth.users au
    LEFT JOIN public.profiles p ON au.id = p.id
    WHERE p.id IS NULL
);
*/

-- ============================================================
-- BAGIAN 4: VERIFIKASI
-- ============================================================

-- Cek semua profiles
SELECT 
    p.*,
    au.email as auth_email,
    CASE 
        WHEN au.id IS NOT NULL THEN 'OK'
        ELSE 'AUTH USER MISSING'
    END as status
FROM public.profiles p
LEFT JOIN auth.users au ON p.id = au.id;

-- Cek apakah RLS sudah enabled
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- Cek semua policies yang aktif
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles';
