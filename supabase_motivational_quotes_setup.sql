-- =====================================================
-- SETUP TABEL MOTIVATIONAL QUOTES
-- =====================================================
-- Tabel ini menyimpan kata-kata motivasi yang di-generate
-- oleh AI secara periodik (misalnya seminggu sekali)
-- =====================================================

-- 1. Buat tabel motivational_quotes
CREATE TABLE IF NOT EXISTS public.motivational_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_text TEXT NOT NULL,
    theme VARCHAR(100), -- Misal: "UTS", "Musim Hujan", "Awal Semester", dll
    relevance_context TEXT, -- Konteks kapan quote ini relevan
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true, -- Untuk soft delete atau menonaktifkan quote tertentu
    display_priority INTEGER DEFAULT 0, -- Untuk mengatur prioritas tampilan (0 = normal)
    usage_count INTEGER DEFAULT 0 -- Tracking berapa kali quote ditampilkan
);

-- 2. Buat index untuk performa
CREATE INDEX IF NOT EXISTS idx_motivational_quotes_active 
    ON public.motivational_quotes(is_active) 
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_motivational_quotes_theme 
    ON public.motivational_quotes(theme);

CREATE INDEX IF NOT EXISTS idx_motivational_quotes_created_at 
    ON public.motivational_quotes(created_at DESC);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.motivational_quotes ENABLE ROW LEVEL SECURITY;

-- 4. Policy: Semua user yang terautentikasi bisa membaca quotes
CREATE POLICY "Anyone can read active quotes"
    ON public.motivational_quotes
    FOR SELECT
    USING (is_active = true);

-- 5. Policy: Hanya service role yang bisa insert/update/delete
-- (Untuk Edge Function yang akan menggenerate quotes)
CREATE POLICY "Service role can manage quotes"
    ON public.motivational_quotes
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 6. Fungsi untuk update timestamp otomatis
CREATE OR REPLACE FUNCTION public.update_motivational_quotes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger untuk auto-update updated_at
DROP TRIGGER IF EXISTS trigger_update_motivational_quotes_updated_at 
    ON public.motivational_quotes;

CREATE TRIGGER trigger_update_motivational_quotes_updated_at
    BEFORE UPDATE ON public.motivational_quotes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_motivational_quotes_updated_at();

-- 8. Function RPC untuk mendapatkan random quote
CREATE OR REPLACE FUNCTION public.get_random_motivational_quote()
RETURNS TABLE (
    id UUID,
    quote_text TEXT,
    theme VARCHAR(100),
    relevance_context TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update usage_count untuk quote yang dipilih
    RETURN QUERY
    UPDATE public.motivational_quotes
    SET usage_count = usage_count + 1
    WHERE motivational_quotes.id = (
        SELECT motivational_quotes.id
        FROM public.motivational_quotes
        WHERE is_active = true
        ORDER BY RANDOM()
        LIMIT 1
    )
    RETURNING 
        motivational_quotes.id,
        motivational_quotes.quote_text,
        motivational_quotes.theme,
        motivational_quotes.relevance_context;
END;
$$;

-- 9. Function RPC untuk mendapatkan quote berdasarkan tema
CREATE OR REPLACE FUNCTION public.get_motivational_quote_by_theme(p_theme VARCHAR(100))
RETURNS TABLE (
    id UUID,
    quote_text TEXT,
    theme VARCHAR(100),
    relevance_context TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    UPDATE public.motivational_quotes
    SET usage_count = usage_count + 1
    WHERE motivational_quotes.id = (
        SELECT motivational_quotes.id
        FROM public.motivational_quotes
        WHERE is_active = true 
            AND (theme = p_theme OR p_theme IS NULL)
        ORDER BY RANDOM()
        LIMIT 1
    )
    RETURNING 
        motivational_quotes.id,
        motivational_quotes.quote_text,
        motivational_quotes.theme,
        motivational_quotes.relevance_context;
END;
$$;

-- 10. Insert beberapa quotes default (fallback jika AI belum generate)
INSERT INTO public.motivational_quotes (quote_text, theme, relevance_context, display_priority) VALUES
('Setiap langkah kecil adalah kemajuan menuju kesuksesan besar.', 'general', 'Quote umum yang selalu relevan', 1),
('Prestasi hari ini adalah investasi untuk masa depan cemerlang.', 'general', 'Quote umum yang selalu relevan', 1),
('Jangan takut gagal, karena kegagalan adalah guru terbaik.', 'general', 'Quote umum yang selalu relevan', 1),
('Organisasi dan volunteer bukan hanya CV builder, tapi character builder.', 'organisasi', 'Untuk mahasiswa yang aktif di organisasi', 2),
('Kompetensi + Karakter = Mahasiswa Unggul!', 'general', 'Quote umum yang selalu relevan', 1),
('Catat setiap pencapaianmu, karena progress kecil adalah kemenangan.', 'general', 'Quote umum yang selalu relevan', 1),
('Mahasiswa berprestasi bukan yang sempurna, tapi yang konsisten.', 'general', 'Quote umum yang selalu relevan', 1),
('Balance antara akademik, organisasi, dan pengembangan diri adalah kunci.', 'general', 'Quote umum yang selalu relevan', 1),
('Setiap kompetisi adalah kesempatan belajar dan berkembang.', 'kompetisi', 'Untuk periode kompetisi', 2),
('Networking hari ini adalah peluang kerja masa depan.', 'general', 'Quote umum yang selalu relevan', 1),
('Jangan membandingkan journey-mu dengan orang lain, fokus pada progresmu.', 'general', 'Quote umum yang selalu relevan', 1),
('Soft skills sama pentingnya dengan hard skills di dunia kerja.', 'general', 'Quote umum yang selalu relevan', 1),
('Dokumentasikan setiap pencapaian, sekecil apapun itu.', 'general', 'Quote umum yang selalu relevan', 1),
('Leadership bukan tentang jabatan, tapi tentang memberi dampak.', 'organisasi', 'Untuk mahasiswa yang aktif di organisasi', 2),
('Keluar dari zona nyaman adalah tempat pertumbuhan dimulai.', 'general', 'Quote umum yang selalu relevan', 1),
('Mahasiswa aktif bukan yang sibuk, tapi yang produktif dan bermakna.', 'general', 'Quote umum yang selalu relevan', 1),
('Setiap pengalaman adalah portfolio untuk masa depanmu.', 'general', 'Quote umum yang selalu relevan', 1),
('Gagal dalam kompetisi? Itu artinya kamu berani mencoba!', 'kompetisi', 'Untuk periode kompetisi', 2),
('Konsisten lebih penting dari intensitas sesaat.', 'general', 'Quote umum yang selalu relevan', 1),
('Manfaatkan masa kuliahmu untuk eksplorasi dan inovasi.', 'general', 'Quote umum yang selalu relevan', 1),
('Prestasi bukan hanya juara, tapi juga keberanian berpartisipasi.', 'kompetisi', 'Untuk periode kompetisi', 2),
('Volunteer mengajarkan empati, leadership mengajarkan tanggung jawab.', 'volunteer', 'Untuk kegiatan volunteer', 2),
('Setiap hari adalah kesempatan untuk belajar sesuatu yang baru.', 'general', 'Quote umum yang selalu relevan', 1),
('Jangan menunda, mulai dari yang kecil hari ini.', 'general', 'Quote umum yang selalu relevan', 1),
('Mahasiswa hebat adalah yang belajar dari pengalaman dan mentoring orang lain.', 'general', 'Quote umum yang selalu relevan', 1),
('Komitmen pada diri sendiri adalah investasi terbaik.', 'general', 'Quote umum yang selalu relevan', 1),
('Sukses adalah hasil dari persiapan, kerja keras, dan belajar dari kesalahan.', 'general', 'Quote umum yang selalu relevan', 1),
('Jangan hanya kuliah, tapi juga berkontribusi untuk masyarakat.', 'volunteer', 'Untuk kegiatan volunteer', 2),
('Setiap kegiatan adalah peluang untuk mengembangkan skill baru.', 'general', 'Quote umum yang selalu relevan', 1),
('Fokus pada progress, bukan perfection.', 'general', 'Quote umum yang selalu relevan', 1);

-- =====================================================
-- QUERY TESTING
-- =====================================================

-- Test 1: Get random quote
-- SELECT * FROM public.get_random_motivational_quote();

-- Test 2: Get quote by theme
-- SELECT * FROM public.get_motivational_quote_by_theme('kompetisi');

-- Test 3: View all active quotes
-- SELECT * FROM public.motivational_quotes WHERE is_active = true ORDER BY usage_count;

-- Test 4: View statistics
-- SELECT theme, COUNT(*) as total, AVG(usage_count) as avg_usage
-- FROM public.motivational_quotes
-- WHERE is_active = true
-- GROUP BY theme;
