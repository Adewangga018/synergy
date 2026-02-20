-- Tabel untuk menyimpan profil pengguna
-- Jalankan SQL ini di Supabase SQL Editor

-- 1. Buat tabel profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    nama_lengkap TEXT NOT NULL,
    nama_panggilan TEXT NOT NULL,
    nrp TEXT UNIQUE NOT NULL,
    jurusan TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    angkatan TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Buat policy untuk membaca email berdasarkan NRP (untuk login)
-- Policy ini mengizinkan siapa saja membaca email untuk keperluan login
CREATE POLICY "Anyone can read email for login"
    ON public.profiles
    FOR SELECT
    USING (true);

-- 4. Buat policy untuk membaca profil sendiri setelah login
-- (Policy ini tidak perlu karena policy #3 sudah mengizinkan semua)

-- 5. Buat policy untuk insert profil sendiri (saat registrasi)
-- Policy ini memungkinkan authenticated user insert data saat registrasi
CREATE POLICY "Allow authenticated users to insert profile"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- 5. Buat policy untuk update profil sendiri
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

-- 6. Buat function untuk auto-update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Buat trigger untuk auto-update updated_at
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 8. Buat index untuk pencarian berdasarkan NRP (untuk login)
CREATE INDEX IF NOT EXISTS idx_profiles_nrp ON public.profiles(nrp);

-- 9. Buat index untuk pencarian berdasarkan email
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
