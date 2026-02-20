-- ============================================
-- DDL untuk Tabel DOCUMENTS
-- ============================================
-- Tabel untuk menyimpan dokumen mahasiswa
-- Mendukung upload file ke Supabase Storage
-- ============================================

-- ============================================
-- STORAGE BUCKET untuk documents
-- ============================================
-- Catatan: Bucket harus dibuat manual di Supabase Dashboard
-- Dashboard → Storage → Create Bucket
-- Bucket name: documents
-- Public bucket: true (jika ingin file bisa diakses publik)
-- File size limit: 50MB (sesuaikan kebutuhan)

-- ============================================
-- TABLE: documents
-- ============================================

CREATE TABLE IF NOT EXISTS public.documents (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  overview text,
  document_date date,
  file_url text,
  file_name text,
  file_size integer,
  category text CHECK (category = ANY (ARRAY[
    'certificate'::text, 
    'transcript'::text, 
    'id_card'::text, 
    'family_card'::text, 
    'diploma'::text, 
    'portfolio'::text, 
    'report'::text, 
    'proposal'::text, 
    'research'::text, 
    'other'::text
  ])),
  tags text[],
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT documents_pkey PRIMARY KEY (id),
  CONSTRAINT documents_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- ============================================
-- INDEXES untuk performa
-- ============================================

-- Index untuk user_id (query berdasarkan user)
CREATE INDEX IF NOT EXISTS documents_user_id_idx 
  ON public.documents(user_id);

-- Index untuk category (filter berdasarkan kategori)
CREATE INDEX IF NOT EXISTS documents_category_idx 
  ON public.documents(category);

-- Index untuk created_at (sorting terbaru)
CREATE INDEX IF NOT EXISTS documents_created_at_idx 
  ON public.documents(created_at DESC);

-- Index untuk document_date (sorting berdasarkan tanggal dokumen)
CREATE INDEX IF NOT EXISTS documents_document_date_idx 
  ON public.documents(document_date DESC);

-- Index untuk title (search by title)
CREATE INDEX IF NOT EXISTS documents_title_idx 
  ON public.documents USING gin (to_tsvector('indonesian', title));

-- Index untuk tags (search by tags)
CREATE INDEX IF NOT EXISTS documents_tags_idx 
  ON public.documents USING gin (tags);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Policy: User hanya bisa SELECT data miliknya sendiri
CREATE POLICY documents_select_own 
  ON public.documents FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: User hanya bisa INSERT data untuk dirinya sendiri
CREATE POLICY documents_insert_own 
  ON public.documents FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa UPDATE data miliknya sendiri
CREATE POLICY documents_update_own 
  ON public.documents FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: User hanya bisa DELETE data miliknya sendiri
CREATE POLICY documents_delete_own 
  ON public.documents FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- STORAGE POLICIES (untuk bucket documents)
-- ============================================
-- Catatan: Policy storage harus dibuat manual di Supabase Dashboard
-- atau menggunakan SQL berikut:

-- Policy: User bisa upload file untuk dirinya sendiri
-- CREATE POLICY "Users can upload their own documents"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   bucket_id = 'documents' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- Policy: User bisa update file miliknya sendiri
-- CREATE POLICY "Users can update their own documents"
-- ON storage.objects FOR UPDATE
-- TO authenticated
-- USING (
--   bucket_id = 'documents' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- Policy: User bisa delete file miliknya sendiri
-- CREATE POLICY "Users can delete their own documents"
-- ON storage.objects FOR DELETE
-- TO authenticated
-- USING (
--   bucket_id = 'documents' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- Policy: User bisa select/view file miliknya sendiri
-- CREATE POLICY "Users can view their own documents"
-- ON storage.objects FOR SELECT
-- TO authenticated
-- USING (
--   bucket_id = 'documents' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Cek struktur tabel
-- SELECT table_name, column_name, data_type, is_nullable, character_maximum_length
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'documents'
-- ORDER BY ordinal_position;

-- Cek RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE tablename = 'documents'
-- ORDER BY policyname;

-- Cek indexes
-- SELECT indexname, tablename, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'documents'
-- ORDER BY indexname;

-- Cek constraint
-- SELECT conname, contype, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'public.documents'::regclass;
