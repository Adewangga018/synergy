-- ===================================
-- CHAT MESSAGES TABLE SETUP
-- Tabel untuk menyimpan riwayat percakapan dengan AI Chatbot
-- ===================================

-- Drop existing table if exists (untuk development)
DROP TABLE IF EXISTS public.chat_messages CASCADE;

-- Create chat_messages table
CREATE TABLE public.chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Message content
    message TEXT NOT NULL,
    is_from_user BOOLEAN NOT NULL DEFAULT true,
    
    -- Context untuk RAG (Retrieval-Augmented Generation)
    user_context JSONB, -- Data yang dikirim ke AI (jadwal, organisasi, dll)
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexing untuk performance
    CONSTRAINT chat_messages_message_length CHECK (char_length(message) > 0)
);

-- Create indexes untuk query performance
CREATE INDEX idx_chat_messages_user_id ON public.chat_messages(user_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at DESC);
CREATE INDEX idx_chat_messages_user_created ON public.chat_messages(user_id, created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Policy: User hanya bisa lihat chat mereka sendiri
CREATE POLICY "Users can view their own chat messages"
    ON public.chat_messages
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: User hanya bisa insert chat mereka sendiri
CREATE POLICY "Users can insert their own chat messages"
    ON public.chat_messages
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: User bisa delete chat mereka sendiri
CREATE POLICY "Users can delete their own chat messages"
    ON public.chat_messages
    FOR DELETE
    USING (auth.uid() = user_id);

-- Policy: User bisa update chat mereka sendiri (untuk edit/feedback)
CREATE POLICY "Users can update their own chat messages"
    ON public.chat_messages
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.chat_messages TO authenticated;
GRANT ALL ON public.chat_messages TO service_role;

-- ===================================
-- HELPER FUNCTIONS
-- ===================================

-- Function untuk mendapatkan recent chat history
CREATE OR REPLACE FUNCTION get_recent_chat_messages(
    p_user_id UUID,
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    message TEXT,
    is_from_user BOOLEAN,
    user_context JSONB,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cm.id,
        cm.message,
        cm.is_from_user,
        cm.user_context,
        cm.created_at
    FROM public.chat_messages cm
    WHERE cm.user_id = p_user_id
    ORDER BY cm.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function untuk clear chat history
CREATE OR REPLACE FUNCTION clear_chat_history(
    p_user_id UUID
)
RETURNS INT AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM public.chat_messages
    WHERE user_id = p_user_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_recent_chat_messages(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION clear_chat_history(UUID) TO authenticated;

-- ===================================
-- VERIFICATION
-- ===================================

-- Verify table creation
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_messages'
    ) THEN
        RAISE NOTICE '✅ Table chat_messages created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create chat_messages table';
    END IF;
END $$;

COMMENT ON TABLE public.chat_messages IS 'Stores chat conversation history between users and AI chatbot';
COMMENT ON COLUMN public.chat_messages.user_context IS 'JSON context data sent to AI (schedules, organizations, etc.)';
COMMENT ON FUNCTION get_recent_chat_messages(UUID, INT) IS 'Get recent chat messages for a user';
COMMENT ON FUNCTION clear_chat_history(UUID) IS 'Clear all chat history for a user';
