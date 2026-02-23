# Gemini Chat Edge Function

Context-aware AI chatbot untuk myITS Synergy menggunakan Google Gemini 2.5 Flash API.

## Features

✅ **Context-Aware Responses**: AI membaca data mahasiswa dari database (jadwal, tugas, organisasi, kompetisi, project)
✅ **Conversation History**: Mendukung percakapan multi-turn yang kontekstual
✅ **RAG (Retrieval-Augmented Generation)**: Mengambil data real-time dari database untuk jawaban yang akurat
✅ **Secure**: API key tersimpan aman di Supabase secrets
✅ **Row-Level Security**: Chat history tersimpan per user dengan RLS

## Setup

### 1. Set Gemini API Key (GRATIS!)

```bash
# Get free API key dari: https://aistudio.google.com/app/apikey
# Then set di Supabase:
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

### 2. Deploy Edge Function

Via Supabase Dashboard:
1. Edge Functions → Create function
2. Name: `gemini-chat`
3. Copy-paste code dari `index.ts`
4. Deploy

Via CLI:
```bash
supabase functions deploy gemini-chat
```

### 3. Test

```bash
curl -i --location --request POST 'https://YOUR_PROJECT.supabase.co/functions/v1/gemini-chat' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"message": "Halo! Gimana jadwalku minggu ini?"}'
```

## Request Format

```json
{
  "message": "User message here",
  "include_context": true,
  "conversation_history": [
    {
      "role": "user",
      "content": "Previous user message"
    },
    {
      "role": "assistant",
      "content": "Previous AI response"
    }
  ]
}
```

**Authentication:**
- `include_context: false` → Auth **optional** (for testing)
- `include_context: true` → Auth **required** (for production use)

## Response Format

```json
{
  "success": true,
  "response": "AI response here",
  "context_used": true,
  "timestamp": "2026-02-23T10:00:00Z"
}
```

## Context Retrieved

AI chatbot secara otomatis mengambil:
- 📝 User profile (nama, NPM, jurusan, angkatan, semester)
- 📚 Upcoming course schedules (7 hari ke depan)
- ✅ Upcoming tasks (14 hari ke depan, yang belum selesai)
- 🏢 Active organizations & roles
- 🏆 Recent competitions
- 💼 Projects count

## Use Cases

1. **Workload Analysis**: "Cek workload-ku minggu depan dong"
2. **Decision Making**: "Aku ada lomba hari Jumat tapi ada kuis juga, gimana?"
3. **Schedule Query**: "Kapan aja aku ada kuliah minggu ini?"
4. **Prioritization**: "Tugas mana yang harus aku kerjain duluan?"
5. **Motivation**: "Aku cape banget, kasih semangat dong"

## Free Tier Gemini API

- ✅ 1,000,000 tokens/month (FREE!)
- ✅ 15 requests/minute
- ✅ No credit card required
