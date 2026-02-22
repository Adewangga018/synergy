# 🚀 Panduan Deploy Edge Function: Generate Motivational Quotes

## Cara Termudah: Deploy via Supabase Dashboard

### **STEP 1: Persiapan - Set OpenAI API Key**

1. **Dapatkan OpenAI API Key:**
   - Buka https://platform.openai.com/api-keys
   - Login/Register
   - Klik **"Create new secret key"**
   - Copy key (contoh: `sk-proj-xxxxxxxxxxxx`)
   - ⚠️ **SIMPAN BAIK-BAIK** - tidak bisa dilihat lagi setelah ditutup!

2. **Set Secret di Supabase:**
   - Buka https://supabase.com/dashboard
   - Pilih project Anda
   - Klik **Settings** (⚙️ di sidebar kiri bawah)
   - Pilih **Edge Functions**
   - Klik **"Manage secrets"**
   - Tambahkan:
     - **Name:** `OPENAI_API_KEY`
     - **Value:** `sk-proj-xxxxxxxxxxxx` (paste key Anda)
   - Klik **"Add secret"**

### **STEP 2: Deploy Edge Function**

#### **Metode A: Via Supabase CLI (Jika Sudah Install)**

```powershell
# Login (akan membuka browser)
npx supabase@latest login

# Link ke project
npx supabase@latest link --project-ref YOUR_PROJECT_REF

# Deploy function
npx supabase@latest functions deploy generate-motivational-quotes --no-verify-jwt
```

#### **Metode B: Via Dashboard (Lebih Mudah!)**

1. **Buka Supabase Dashboard:**
   - https://supabase.com/dashboard
   - Pilih project Anda

2. **Buka Edge Functions:**
   - Klik **Edge Functions** di sidebar
   - Klik **"Create a new function"** atau **"Deploy a new version"**

3. **Upload File:**
   - **Function name:** `generate-motivational-quotes`
   - Upload atau paste file `index.ts` dari folder:
     `supabase/functions/generate-motivational-quotes/index.ts`
   - Klik **"Deploy"**

4. **Verify Deployment:**
   - Tunggu sampai status menjadi **"Active"**
   - Copy URL function (akan digunakan di Flutter)

#### **Metode C: Via GitHub (Otomatis - Advanced)**

Jika Anda push ke GitHub dan connect dengan Supabase:
- Supabase akan otomatis deploy setiap kali ada perubahan di folder `supabase/functions/`

### **STEP 3: Test Edge Function**

#### **Test via Supabase Dashboard:**

1. Buka function di Dashboard
2. Klik **"Invoke"** atau **"Test"**
3. Masukkan test body:

```json
{
  "count": 3,
  "theme": "general"
}
```

4. Klik **"Run"**
5. Harusnya return response seperti:

```json
{
  "success": true,
  "generated_count": 3,
  "inserted_count": 3,
  "context": "Semester Genap 2025/2026",
  "theme": "general",
  "quotes_preview": [
    "Quote 1...",
    "Quote 2...",
    "Quote 3..."
  ]
}
```

#### **Test via Postman/Thunder Client:**

```http
POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-motivational-quotes
Headers:
  Authorization: Bearer YOUR_ANON_KEY
  Content-Type: application/json

Body:
{
  "count": 5,
  "theme": "UTS"
}
```

#### **Test via PowerShell:**

```powershell
# Ganti dengan data project Anda
$projectRef = "YOUR_PROJECT_REF"
$anonKey = "YOUR_ANON_KEY"

$headers = @{
    "Authorization" = "Bearer $anonKey"
    "Content-Type" = "application/json"
}

$body = @{
    count = 5
    theme = "general"
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "https://$projectRef.supabase.co/functions/v1/generate-motivational-quotes" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

### **STEP 4: Lihat Function URL**

Setelah deploy, Anda akan mendapatkan URL seperti:
```
https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-motivational-quotes
```

**Simpan URL ini!** Akan digunakan di Flutter service.

---

## ⚠️ Troubleshooting

### Error: "OPENAI_API_KEY not found"
- Pastikan sudah set secret di Supabase
- Secret name harus **persis** `OPENAI_API_KEY`
- Redeploy function setelah set secret

### Error: "OpenAI quota exceeded"
- API key Anda kehabisan credit
- Buka https://platform.openai.com/account/billing
- Tambahkan payment method & credit
- Atau gunakan fallback quotes dari database

### Error: "Failed to insert quotes"
- Check apakah tabel `motivational_quotes` sudah ada
- Jalankan migration: `supabase_motivational_quotes_setup.sql`
- Check permissions RLS di Supabase

### Function tidak muncul di Dashboard
- Tunggu beberapa saat (max 1-2 menit)
- Refresh halaman
- Check logs di Dashboard → Edge Functions → Logs

---

## 📊 Monitoring & Logs

### Lihat Logs:

**Via Dashboard:**
- Edge Functions → pilih function → **"Logs"**

**Via CLI:**
```powershell
npx supabase@latest functions logs generate-motivational-quotes
```

### Check Berapa Quotes di Database:

```sql
SELECT theme, COUNT(*) as total, AVG(usage_count) as avg_usage
FROM motivational_quotes
WHERE is_active = true
GROUP BY theme
ORDER BY total DESC;
```

---

## 💰 Estimasi Biaya OpenAI

- Model: `gpt-3.5-turbo`
- ~$0.0015 per 1K tokens
- Generate 10 quotes ≈ 500-800 tokens
- **Estimasi:** $0.001 per request (10 quotes)
- **Recommended:** Generate bulk (50-100 quotes) sebulan sekali
- **Alternative:** Gunakan database quotes yang sudah ada

---

## ✅ Checklist Deploy

- [ ] OpenAI API Key didapat
- [ ] Secret `OPENAI_API_KEY` di-set di Supabase
- [ ] Edge Function berhasil deploy
- [ ] Test function berhasil (generate quotes)
- [ ] Quotes masuk ke database
- [ ] Function URL disimpan

**Jika semua centang ✅, lanjut ke STEP 3!**
