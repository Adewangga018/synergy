# Supabase Edge Function: Generate Motivational Quotes

Edge Function ini menggunakan OpenAI API untuk menggenerate kata-kata motivasi yang kontekstual dan relevan.

## Setup

### 1. Install Supabase CLI

```bash
# Windows (dengan Scoop)
scoop install supabase

# Atau download dari https://github.com/supabase/cli/releases
```

### 2. Login ke Supabase

```bash
supabase login
```

### 3. Link ke Project Supabase

```bash
# Di root directory project
supabase link --project-ref YOUR_PROJECT_REF
```

### 4. Set Environment Variable untuk OpenAI API Key

```bash
# Set secret untuk Edge Function
supabase secrets set OPENAI_API_KEY=your_openai_api_key_here
```

Untuk mendapatkan OpenAI API key:
1. Buka https://platform.openai.com/api-keys
2. Create new secret key
3. Copy dan simpan (tidak bisa dilihat lagi setelah ditutup)

### 5. Deploy Edge Function

```bash
# Deploy function
supabase functions deploy generate-motivational-quotes

# Atau deploy dengan environment variable
supabase functions deploy generate-motivational-quotes --no-verify-jwt
```

### 6. Setup Cron Job (Pg_cron)

Agar function ini berjalan otomatis setiap minggu, gunakan pg_cron di Supabase:

```sql
-- 1. Enable pg_cron extension (jika belum)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Buat cron job untuk menjalankan function setiap Minggu jam 00:00
SELECT cron.schedule(
    'generate-weekly-motivational-quotes',
    '0 0 * * 0', -- Setiap Minggu jam 00:00 (midnight)
    $$
    SELECT
      net.http_post(
          url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-motivational-quotes',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
          body:=concat('{"context": "weekly"}')::jsonb
      ) as request_id;
    $$
);

-- 3. Lihat semua cron jobs
SELECT * FROM cron.job;

-- 4. Hapus cron job (jika perlu)
-- SELECT cron.unschedule('generate-weekly-motivational-quotes');
```

**Catatan:** 
- Ganti `YOUR_PROJECT_REF` dengan referensi project Supabase Anda
- Ganti `YOUR_ANON_KEY` dengan anon key dari Supabase dashboard
- Cron expression: `0 0 * * 0` = Setiap Minggu jam 00:00
- Bisa disesuaikan, misal `0 0 * * 1` = Setiap Senin jam 00:00

### 7. Test Function Secara Manual

```bash
# Test locally
supabase functions serve generate-motivational-quotes

# Kemudian di terminal lain, test dengan curl
curl -i --location --request POST 'http://localhost:54321/functions/v1/generate-motivational-quotes' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"context":"testing"}'

# Test di production
curl -i --location --request POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-motivational-quotes' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"context":"weekly"}'
```

## Environment Variables

Edge Function ini membutuhkan environment variables berikut:

- `OPENAI_API_KEY`: API key dari OpenAI (wajib)
- `SUPABASE_URL`: URL Supabase project (auto-inject oleh Supabase)
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key (auto-inject oleh Supabase)

## Function Parameters

Function ini menerima JSON body dengan parameter optional:

```json
{
  "context": "weekly",        // Optional: konteks untuk generate quotes
  "count": 10,                // Optional: jumlah quotes yang di-generate (default: 10)
  "theme": "UTS",            // Optional: tema spesifik (default: detect otomatis)
  "replace_existing": false   // Optional: apakah menghapus quotes lama (default: false)
}
```

## Contoh Response

```json
{
  "success": true,
  "generated_count": 10,
  "context": "Minggu UTS - Semester Genap 2026",
  "quotes_added": [
    {
      "quote_text": "UTS bukan akhir dari segalanya, tapi awal dari pembuktian diri.",
      "theme": "UTS",
      "relevance_context": "Periode UTS Semester Genap 2026"
    }
  ]
}
```

## Monitoring

Untuk melihat logs function:

```bash
# Real-time logs
supabase functions logs generate-motivational-quotes --tail

# Historical logs
supabase functions logs generate-motivational-quotes
```

## Troubleshooting

### Error: "OpenAI API key not found"
- Pastikan sudah set secret: `supabase secrets set OPENAI_API_KEY=xxx`
- Verify dengan: `supabase secrets list`

### Error: "Failed to insert quotes"
- Check RLS policies di tabel `motivational_quotes`
- Pastikan menggunakan service role key, bukan anon key

### Function tidak jalan otomatis
- Verify cron job: `SELECT * FROM cron.job;`
- Check cron job logs di Supabase dashboard
- Pastikan URL dan authorization header benar

## Biaya OpenAI

Function ini menggunakan model GPT-3.5-turbo (atau GPT-4 jika diubah di code).

Estimasi biaya per minggu:
- GPT-3.5-turbo: ~$0.01 per request (10 quotes)
- GPT-4: ~$0.10 per request (10 quotes)

Per bulan (4 minggu):
- GPT-3.5-turbo: ~$0.04/bulan
- GPT-4: ~$0.40/bulan

## Customization

Untuk menyesuaikan prompt atau behavior, edit file `supabase/functions/generate-motivational-quotes/index.ts`:

- Ubah `systemPrompt` untuk mengubah style quotes
- Ubah `detectContext()` untuk mendeteksi konteks yang berbeda
- Ubah `quotesCount` di request body untuk mengubah jumlah quotes yang di-generate
