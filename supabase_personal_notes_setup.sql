-- ============================================
-- SETUP PERSONAL NOTES TABLE
-- ============================================
-- Table untuk menyimpan catatan pribadi mahasiswa

CREATE TABLE IF NOT EXISTS public.personal_notes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  content text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT personal_notes_pkey PRIMARY KEY (id),
  CONSTRAINT personal_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- ============================================
-- INDEXES untuk performa query
-- ============================================

-- Index untuk query berdasarkan user_id (untuk filtering)
CREATE INDEX IF NOT EXISTS personal_notes_user_id_idx ON public.personal_notes(user_id);

-- Index untuk sorting berdasarkan updated_at
CREATE INDEX IF NOT EXISTS personal_notes_updated_at_idx ON public.personal_notes(updated_at DESC);

-- Index untuk full-text search pada title dan content
CREATE INDEX IF NOT EXISTS personal_notes_search_idx ON public.personal_notes USING gin(to_tsvector('indonesian', title || ' ' || COALESCE(content, '')));

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE public.personal_notes ENABLE ROW LEVEL SECURITY;

-- Policy: User hanya bisa melihat catatan mereka sendiri
CREATE POLICY "Users can view their own notes"
ON public.personal_notes
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: User hanya bisa insert catatan untuk diri sendiri
CREATE POLICY "Users can insert their own notes"
ON public.personal_notes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa update catatan mereka sendiri
CREATE POLICY "Users can update their own notes"
ON public.personal_notes
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa delete catatan mereka sendiri
CREATE POLICY "Users can delete their own notes"
ON public.personal_notes
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- TRIGGER untuk auto-update updated_at
-- ============================================

-- Function untuk update timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger yang akan update updated_at saat ada UPDATE
CREATE TRIGGER update_personal_notes_updated_at
BEFORE UPDATE ON public.personal_notes
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- VERIFICATION
-- ============================================

-- Check if table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'personal_notes';

-- Check columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'personal_notes'
ORDER BY ordinal_position;

-- Check policies
SELECT policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'personal_notes';
