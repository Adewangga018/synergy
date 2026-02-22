-- ==========================================
-- SETUP: User Tasks (Aktivitas/Tugas)
-- ==========================================
-- Fitur untuk menandai jadwal aktivitas yang bersifat momentual
-- User bisa membuat task/aktivitas di tanggal tertentu
-- Support: priority, completion status, due time
--
-- Cara jalankan:
-- 1. Buka Supabase Dashboard → SQL Editor
-- 2. Copy paste SEMUA script ini
-- 3. Klik "Run" atau tekan Ctrl+Enter
-- 4. Verify: Check tabel `user_tasks` muncul di Table Editor

-- ==========================================
-- 1. CREATE TABLE
-- ==========================================

CREATE TABLE IF NOT EXISTS user_tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE NOT NULL,
  due_time TIME,
  is_completed BOOLEAN DEFAULT false NOT NULL,
  priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- 2. CREATE INDEXES
-- ==========================================
-- Index untuk query performance

-- Index untuk user_id (most common query)
CREATE INDEX IF NOT EXISTS idx_user_tasks_user_id 
  ON user_tasks(user_id);

-- Index untuk due_date (untuk calendar view)
CREATE INDEX IF NOT EXISTS idx_user_tasks_due_date 
  ON user_tasks(due_date);

-- Index untuk is_completed (untuk filter completed/pending)
CREATE INDEX IF NOT EXISTS idx_user_tasks_is_completed 
  ON user_tasks(is_completed);

-- Composite index untuk common query (user + date)
CREATE INDEX IF NOT EXISTS idx_user_tasks_user_date 
  ON user_tasks(user_id, due_date);

-- ==========================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ==========================================

-- Enable RLS
ALTER TABLE user_tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own tasks
CREATE POLICY "Users can view own tasks"
  ON user_tasks
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own tasks
CREATE POLICY "Users can insert own tasks"
  ON user_tasks
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own tasks
CREATE POLICY "Users can update own tasks"
  ON user_tasks
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own tasks
CREATE POLICY "Users can delete own tasks"
  ON user_tasks
  FOR DELETE
  USING (auth.uid() = user_id);

-- ==========================================
-- 4. FUNCTION: Auto-update updated_at
-- ==========================================

CREATE OR REPLACE FUNCTION update_user_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk auto-update updated_at
DROP TRIGGER IF EXISTS trigger_update_user_tasks_updated_at ON user_tasks;

CREATE TRIGGER trigger_update_user_tasks_updated_at
  BEFORE UPDATE ON user_tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_user_tasks_updated_at();

-- ==========================================
-- 5. HELPER FUNCTIONS (Optional)
-- ==========================================

-- Function: Get pending tasks count for user
CREATE OR REPLACE FUNCTION get_pending_tasks_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM user_tasks
    WHERE user_id = p_user_id
      AND is_completed = false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get tasks for specific date
CREATE OR REPLACE FUNCTION get_tasks_for_date(p_user_id UUID, p_date DATE)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  due_time TIME,
  is_completed BOOLEAN,
  priority TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.title,
    t.description,
    t.due_time,
    t.is_completed,
    t.priority
  FROM user_tasks t
  WHERE t.user_id = p_user_id
    AND t.due_date = p_date
  ORDER BY 
    t.is_completed ASC,  -- Show pending tasks first
    t.priority DESC,      -- High priority first
    t.due_time ASC NULLS LAST;  -- Earlier tasks first
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get overdue tasks
CREATE OR REPLACE FUNCTION get_overdue_tasks(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  title TEXT,
  due_date DATE,
  priority TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.title,
    t.due_date,
    t.priority
  FROM user_tasks t
  WHERE t.user_id = p_user_id
    AND t.is_completed = false
    AND t.due_date < CURRENT_DATE
  ORDER BY t.due_date ASC, t.priority DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 6. SAMPLE DATA (Optional - for testing)
-- ==========================================
-- Uncomment untuk insert sample data

-- INSERT INTO user_tasks (user_id, title, description, due_date, due_time, priority, is_completed)
-- VALUES 
--   (auth.uid(), 'Selesaikan BAB 1 TA', 'Chapter introduction dan background', '2026-02-25', '14:00:00', 'high', false),
--   (auth.uid(), 'Bimbingan dengan Dosen', 'Konsultasi progress TA', '2026-02-26', '10:00:00', 'high', false),
--   (auth.uid(), 'Beli bahan presentasi', 'Kertas manila dan spidol', '2026-02-24', NULL, 'low', false),
--   (auth.uid(), 'Review materi UTS', 'Bab 1-5 Algoritma', '2026-02-28', NULL, 'medium', false);

-- ==========================================
-- 7. VERIFICATION QUERIES
-- ==========================================
-- Run untuk verify setup berhasil

-- Check table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'user_tasks';

-- Check indexes
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'user_tasks';

-- Check RLS policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'user_tasks';

-- Check functions
SELECT proname 
FROM pg_proc 
WHERE proname LIKE '%user_task%' OR proname LIKE '%tasks%';

-- ==========================================
-- SETUP COMPLETE! ✅
-- ==========================================
-- Next steps:
-- 1. Verify tabel `user_tasks` muncul di Table Editor
-- 2. Test insert data di SQL Editor atau via aplikasi
-- 3. Verify RLS policy bekerja (user hanya lihat task sendiri)
-- 4. Check indexes untuk query performance
