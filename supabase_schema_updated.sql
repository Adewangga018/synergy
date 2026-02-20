-- ============================================
-- UPDATED DATABASE SCHEMA
-- ============================================
-- Perubahan:
-- 1. Tabel academic_years dihapus
-- 2. Kolom academic_year_id di tabel organizations diganti dengan start_date dan end_date
-- 3. Tabel calendar_tasks dihapus (jika ada)
-- ============================================

-- ============================================
-- DROP TABLES & CONSTRAINTS (jika sudah ada)
-- ============================================

-- Drop foreign key constraint dari organizations ke academic_years
ALTER TABLE IF EXISTS public.organizations 
  DROP CONSTRAINT IF EXISTS organizations_academic_year_id_fkey;

-- Drop tabel academic_years
DROP TABLE IF EXISTS public.academic_years CASCADE;

-- Drop tabel calendar_tasks (jika ada)
DROP TABLE IF EXISTS public.calendar_tasks CASCADE;

-- Drop kolom academic_year_id dari organizations (jika ada)
ALTER TABLE IF EXISTS public.organizations 
  DROP COLUMN IF EXISTS academic_year_id;

-- Drop kolom academic_year dari organizations (jika ada)
ALTER TABLE IF EXISTS public.organizations 
  DROP COLUMN IF EXISTS academic_year;

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
-- TABLE: organizations (UPDATED)
-- ============================================

CREATE TABLE IF NOT EXISTS public.organizations (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  org_name text NOT NULL,
  scale text CHECK (scale = ANY (ARRAY['department'::text, 'faculty'::text, 'campus'::text, 'external'::text])),
  position text NOT NULL,
  start_date date,  -- CHANGED: tanggal mulai bergabung
  end_date date,    -- CHANGED: tanggal selesai (opsional jika masih aktif)
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT organizations_pkey PRIMARY KEY (id),
  CONSTRAINT organizations_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- Jika tabel organizations sudah ada, tambahkan kolom start_date dan end_date
ALTER TABLE IF EXISTS public.organizations 
  ADD COLUMN IF NOT EXISTS start_date date;
ALTER TABLE IF EXISTS public.organizations 
  ADD COLUMN IF NOT EXISTS end_date date;

-- ============================================
-- INDEXES untuk performa
-- ============================================

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
CREATE INDEX IF NOT EXISTS volunteer_activities_start_date_idx 
  ON public.volunteer_activities(start_date DESC);
CREATE INDEX IF NOT EXISTS volunteer_activities_end_date_idx 
  ON public.volunteer_activities(end_date);

-- Indexes untuk organizations
CREATE INDEX IF NOT EXISTS organizations_user_id_idx 
  ON public.organizations(user_id);
CREATE INDEX IF NOT EXISTS organizations_scale_idx 
  ON public.organizations(scale);
CREATE INDEX IF NOT EXISTS organizations_start_date_idx 
  ON public.organizations(start_date DESC);
CREATE INDEX IF NOT EXISTS organizations_end_date_idx 
  ON public.organizations(end_date);
CREATE INDEX IF NOT EXISTS organizations_created_at_idx 
  ON public.organizations(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS pada semua tabel
ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES untuk competitions
-- ============================================

-- Policy: User hanya bisa SELECT data miliknya sendiri
CREATE POLICY competitions_select_own 
  ON public.competitions FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: User hanya bisa INSERT data untuk dirinya sendiri
CREATE POLICY competitions_insert_own 
  ON public.competitions FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa UPDATE data miliknya sendiri
CREATE POLICY competitions_update_own 
  ON public.competitions FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa DELETE data miliknya sendiri
CREATE POLICY competitions_delete_own 
  ON public.competitions FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- RLS POLICIES untuk volunteer_activities
-- ============================================

-- Policy: User hanya bisa SELECT data miliknya sendiri
CREATE POLICY volunteer_activities_select_own 
  ON public.volunteer_activities FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: User hanya bisa INSERT data untuk dirinya sendiri
CREATE POLICY volunteer_activities_insert_own 
  ON public.volunteer_activities FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa UPDATE data miliknya sendiri
CREATE POLICY volunteer_activities_update_own 
  ON public.volunteer_activities FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa DELETE data miliknya sendiri
CREATE POLICY volunteer_activities_delete_own 
  ON public.volunteer_activities FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- RLS POLICIES untuk organizations
-- ============================================

-- Policy: User hanya bisa SELECT data miliknya sendiri
CREATE POLICY organizations_select_own 
  ON public.organizations FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: User hanya bisa INSERT data untuk dirinya sendiri
CREATE POLICY organizations_insert_own 
  ON public.organizations FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa UPDATE data miliknya sendiri
CREATE POLICY organizations_update_own 
  ON public.organizations FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa DELETE data miliknya sendiri
CREATE POLICY organizations_delete_own 
  ON public.organizations FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Gunakan query ini untuk verifikasi setelah setup

-- Cek struktur tabel
-- SELECT table_name, column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
--   AND table_name IN ('competitions', 'volunteer_activities', 'organizations')
-- ORDER BY table_name, ordinal_position;

-- Cek RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE tablename IN ('competitions', 'volunteer_activities', 'organizations')
-- ORDER BY tablename, policyname;

-- Cek indexes
-- SELECT indexname, tablename, indexdef
-- FROM pg_indexes
-- WHERE tablename IN ('competitions', 'volunteer_activities', 'organizations')
-- ORDER BY tablename, indexname;
