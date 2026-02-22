# 🎉 DEPLOY EDGE FUNCTION dengan GEMINI (100% GRATIS!)

## ✅ Keuntungan Pakai Gemini vs OpenAI

| Feature | OpenAI | Google Gemini |
|---------|--------|---------------|
| **Free Tier** | ❌ Harus bayar | ✅ **GRATIS!** |
| **Free Quota** | $0 | **15 RPM, 1M tokens/month** |
| **Setup** | Perlu credit card | Cukup API key |
| **Harga (paid)** | $0.0015/1K tokens | $0.00015/1K (10x lebih murah!) |
| **Bahasa Indonesia** | Bagus | **Excellent!** |

---

## 🚀 STEP-BY-STEP DEPLOYMENT

### **STEP 1: Dapatkan Gemini API Key (GRATIS!)**

1. **Buka**: https://aistudio.google.com/app/apikey
2. **Login** dengan Google account Anda
3. **Klik "Get API Key"** atau **"Create API key"**
4. **Copy** API key yang muncul (format: `AIza...`)
5. **SIMPAN BAIK-BAIK!**

> 💡 **Ini GRATIS selamanya** dengan quota 1 juta tokens per bulan!

---

### **STEP 2: Set Gemini API Key di Supabase**

1. Buka https://supabase.com/dashboard
2. Pilih project Synergy Anda
3. Klik **⚙️ Settings** (sidebar kiri bawah)
4. Pilih tab **Edge Functions**
5. Klik **"Manage secrets"**
6. Tambahkan secret baru:
   - **Secret name:** `GEMINI_API_KEY`
   - **Secret value:** `AIzaxxxxxxxxxxxxxxx` (paste API key Anda)
7. Klik **"Add secret"**

✅ Done! Secret tersimpan aman.

---

### **STEP 3: Deploy Edge Function**

#### **Metode A: Via Supabase Dashboard (PALING MUDAH)**

1. Di Supabase Dashboard, klik **Edge Functions** di sidebar
2. Klik **"Create a new function"** atau **"+ New function"**
3. Isi:
   - **Function name:** `generate-motivational-quotes`
4. **Copy SELURUH isi file ini:**
   - File: `EDGE_FUNCTION_CODE_TO_COPY.ts`
   - Atau buka: `supabase/functions/generate-motivational-quotes/index.ts`
5. **Paste** ke code editor di dashboard
6. Klik **"Deploy function"**
7. Tunggu status: 🟢 **Active**

#### **Metode B: Via CLI (Alternative)**

```powershell
# Login Supabase
npx supabase@latest login

# Link project (ganti YOUR_PROJECT_REF)
npx supabase@latest link --project-ref YOUR_PROJECT_REF

# Deploy function
npx supabase@latest functions deploy generate-motivational-quotes --no-verify-jwt
```

---

### **STEP 4: Test Edge Function**

#### **Test via Dashboard:**

1. Buka **Edge Functions** → **generate-motivational-quotes**
2. Klik **"Invoke"** atau **"Test function"**
3. Di **Request Body**, pilih salah satu:

**📌 Test 1: Auto-detect (theme otomatis)**
```json
{
  "count": 3
}
```

**📌 Test 2: Theme General**
```json
{
  "count": 3,
  "theme": "general"
}
```

**📌 Test 3: Theme Tugas Akhir (TA) - FITUR BARU! 🎓**
```json
{
  "count": 3,
  "theme": "tugas-akhir",
  "context": "Mahasiswa semester 7-8 sedang mengerjakan TA"
}
```

**📌 Test 4: Theme UTS**
```json
{
  "count": 2,
  "theme": "UTS"
}
```

**📌 Test 5: Theme UAS**
```json
{
  "count": 2,
  "theme": "UAS"
}
```

4. Klik **"Send Request"**

**Expected Response:**
```json
{
  "success": true,
  "generated_count": 3,
  "inserted_count": 3,
  "context": "Semester Genap 2025/2026",
  "theme": "general",
  "quotes_preview": [
    "Quote motivasi 1...",
    "Quote motivasi 2...",
    "Quote motivasi 3..."
  ]
}
```

✅ **Jika muncul response seperti di atas = BERHASIL!**

---

#### **Quick Test via PowerShell:**

```powershell
# Set variables
$URL = "https://YOUR_PROJECT.supabase.co/functions/v1/generate-motivational-quotes"
$KEY = "YOUR_ANON_KEY"

# Test auto-detect
Invoke-RestMethod -Uri $URL -Method Post -Headers @{"Authorization"="Bearer $KEY"; "Content-Type"="application/json"} -Body '{"count":2}'

# Test theme TA (Tugas Akhir)
Invoke-RestMethod -Uri $URL -Method Post -Headers @{"Authorization"="Bearer $KEY"; "Content-Type"="application/json"} -Body '{"count":3,"theme":"tugas-akhir"}'
```

#### **Quick Test via cURL:**

```bash
# Test auto-detect
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate-motivational-quotes \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"count":2}'

# Test theme TA (Tugas Akhir)
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate-motivational-quotes \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"count":3,"theme":"tugas-akhir","context":"Mahasiswa semester 7-8 sedang mengerjakan TA"}'
```

---

### **STEP 5: Verifikasi Quotes Masuk Database**

Jalankan query ini di **SQL Editor**:

```sql
-- Lihat quotes terbaru
SELECT quote_text, theme, created_at 
FROM motivational_quotes 
WHERE is_active = true 
ORDER BY created_at DESC 
LIMIT 10;

-- Lihat statistik per theme
SELECT theme, COUNT(*) as total 
FROM motivational_quotes 
WHERE is_active = true 
GROUP BY theme 
ORDER BY total DESC;
```

---

## 🎯 CHECKLIST DEPLOYMENT

Centang semua:

- [ ] ✅ Gemini API Key didapat dari aistudio.google.com
- [ ] ✅ Secret `GEMINI_API_KEY` sudah di-set di Supabase
- [ ] ✅ Edge Function berhasil deploy (status Active)
- [ ] ✅ Test invoke berhasil (return success: true)  
- [ ] ✅ Quotes berhasil masuk database
- [ ] ✅ App Flutter bisa generate quotes

---

## ⚠️ TROUBLESHOOTING

### ❌ Error: "GEMINI_API_KEY not found"
**Solusi:**
- Pastikan secret name **persis**: `GEMINI_API_KEY` (uppercase)
- Redeploy function setelah menambah secret
- Tunggu 1-2 menit setelah set secret

### ❌ Error: "API key not valid"
**Solusi:**
- Check API key di: https://aistudio.google.com/app/apikey
- Pastikan tidak ada spasi di awal/akhir saat copy-paste
- Generate API key baru jika perlu

### ❌ Error: "Model not found" atau "gemini-pro not found"
**Solusi:**
- Pastikan menggunakan Edge Function versi terbaru
- Model yang digunakan: `gemini-1.5-flash` (gratis & cepat!)
- Redeploy function dengan code terbaru dari `EDGE_FUNCTION_CODE_TO_COPY.ts`

### ❌ Error: "Quota exceeded"
**Solusi:**
- Check usage di: https://aistudio.google.com/app/apikey
- Free tier: 15 requests/minute, 1M tokens/month
- Tunggu 1 menit, lalu coba lagi
- Atau upgrade ke paid plan (sangat murah!)

### ❌ Error: "Failed to insert quotes"
**Solusi:**
- Check tabel `motivational_quotes` sudah ada
- Jalankan SQL: `supabase_motivational_quotes_setup.sql`
- Check RLS policies

---

## 💰 ESTIMASI PENGGUNAAN & BIAYA

### **Free Tier (Recommended):**
- **Quota:** 1,000,000 tokens/month
- **Rate limit:** 15 requests/minute
- **Cost:** **$0 (GRATIS!)**

**Generate 10 quotes ≈ 500 tokens**

Dengan free tier, Anda bisa generate:
- **2,000 batch** (10 quotes/batch per bulan)
- **20,000 quotes per bulan**
- **Lebih dari cukup!**

### **Paid Plan (Jika butuh lebih):**
- **Harga:** $0.00015 per 1K tokens
- **Generate 1000 quotes:** ~$0.075 (Rp 1,000!)
- **Jauh lebih murah dari OpenAI!**

---

## 📊 MONITORING

### **Check Usage:**
1. Buka https://aistudio.google.com/app/apikey
2. Lihat usage statistics
3. Monitor quota remaining

### **Check Logs di Supabase:**
- **Dashboard** → **Edge Functions** → **Logs**
- Atau via CLI:
  ```powershell
  npx supabase@latest functions logs generate-motivational-quotes
  ```

---

## 🎉 SELESAI!

Sekarang Anda punya sistem generate quotes dengan AI yang:
- ✅ **100% GRATIS** (dengan Gemini free tier)
- ✅ **Unlimited** untuk use case normal
- ✅ **Kualitas excellent** untuk bahasa Indonesia
- ✅ **Mudah di-maintain**

**Next: Test di Flutter app Anda!** 🚀

---

## 📚 Resources

- Gemini API: https://ai.google.dev/
- Get API Key: https://aistudio.google.com/app/apikey
- Pricing: https://ai.google.dev/pricing
- Documentation: https://ai.google.dev/docs

**Happy Generating! 🎊**
