# 🚀 DEPLOY EDGE FUNCTION - Step by Step

## ✅ CARA TERMUDAH: Deploy via Supabase Dashboard

### **STEP 1: Buka Supabase Dashboard**

1. Buka browser, kunjungi: https://supabase.com/dashboard
2. Login dengan akun Anda
3. Pilih project Synergy Anda

### **STEP 2: Set OpenAI API Key (Secrets)**

1. Di sidebar kiri bawah, klik **⚙️ Settings**
2. Pilih tab **Edge Functions**
3. Klik tombol **"Manage secrets"** atau **"Add secret"**
4. Tambahkan secret baru:
   - **Secret name:** `OPENAI_API_KEY`
   - **Secret value:** `sk-proj-xxxxxxxxxxxxxxxxxx` (paste OpenAI API key Anda)
5. Klik **"Add secret"** atau **"Save"**

**💡 Belum punya OpenAI API Key?**
- Buka: https://platform.openai.com/api-keys
- Login/Register
- Klik "Create new secret key"
- Copy key-nya (simpan di tempat aman!)

### **STEP 3: Deploy Edge Function**

Ada 2 cara:

#### **Cara 3A: Deploy via UI (Copy-Paste)**

1. Klik **Edge Functions** di sidebar kiri
2. Klik **"Create a new function"** atau **"+ New function"**
3. Isi form:
   - **Function name:** `generate-motivational-quotes`
   - Centang **"Import from GitHub"** → pilih **NO/Skip** (kita akan copy-paste)
4. Copy seluruh isi file ini: `supabase/functions/generate-motivational-quotes/index.ts`
5. Paste ke editor function di dashboard
6. Klik **"Deploy function"** atau **"Save"**
7. Tunggu sampai status: **🟢 Active**

#### **Cara 3B: Deploy via GitHub (Otomatis)**

Jika project sudah di GitHub dan terkoneksi dengan Supabase:
1. Push code ke GitHub:
   ```bash
   git add .
   git commit -m "Add generate quotes edge function"
   git push
   ```
2. Supabase akan auto-deploy Edge Function dari folder `supabase/functions/`

### **STEP 4: Test Edge Function**

1. Di halaman Edge Functions, klik function **generate-motivational-quotes**
2. Klik tab **"Invoke"** atau tombol **"Test function"**
3. Di bagian **Request Body**, masukkan:
   ```json
   {
     "count": 3,
     "theme": "general"
   }
   ```
4. Klik **"Send Request"** atau **"Invoke"**
5. Lihat response:
   - ✅ **Success:** Muncul quotes baru dengan status `"success": true`
   - ❌ **Error:** Lihat error message dan troubleshooting di bawah

**Expected Response:**
```json
{
  "success": true,
  "generated_count": 3,
  "inserted_count": 3,
  "context": "Semester Genap 2025/2026",
  "theme": "general",
  "quotes_preview": [
    "Quote pertama...",
    "Quote kedua...",
    "Quote ketiga..."
  ]
}
```

### **STEP 5: Dapatkan Function URL**

1. Di halaman Edge Function, copy **Function URL** atau **Endpoint**
2. Format URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-motivational-quotes`
3. **SIMPAN URL ini!** Akan digunakan di Flutter (opsional, sudah auto via Supabase client)

---

## 🔧 TROUBLESHOOTING

### ❌ Error: "OPENAI_API_KEY not found"
**Solusi:**
- Pastikan secret name **persis**: `OPENAI_API_KEY` (case-sensitive)
- Re-deploy function setelah menambah secret
- Restart/redeploy function dari dashboard

### ❌ Error: "OpenAI quota exceeded" atau "insufficient_quota"
**Solusi:**
- Buka: https://platform.openai.com/account/billing
- Tambahkan payment method
- Add credits (minimum $5)
- Atau gunakan quotes yang sudah ada di database (skip generate)

### ❌ Error: "Failed to insert quotes"
**Solusi:**
- Check apakah tabel `motivational_quotes` sudah dibuat
- Jalankan SQL: `supabase_motivational_quotes_setup.sql`
- Check RLS policies di Supabase Dashboard → Database → Tables → motivational_quotes

### ❌ Error: "Function not found" di Flutter
**Solusi:**
- Tunggu 1-2 menit setelah deploy (propagation time)
- Pastikan function name **persis**: `generate-motivational-quotes`
- Refresh Supabase client di Flutter app

### ❌ Function stuck "Deploying..."
**Solusi:**
- Refresh browser
- Tunggu 2-3 menit
- Jika masih stuck, hapus dan buat ulang function

---

## ✅ CHECKLIST DEPLOY

Centang semua sebelum lanjut ke Step 3:

- [ ] ✅ OpenAI API Key didapat dari platform.openai.com
- [ ] ✅ Secret `OPENAI_API_KEY` sudah di-set di Supabase
- [ ] ✅ Edge Function berhasil di-deploy
- [ ] ✅ Function status: 🟢 Active
- [ ] ✅ Test invoke berhasil (return success: true)
- [ ] ✅ Quotes berhasil masuk ke database
- [ ] ✅ Function URL/Endpoint di-copy (opsional)

**Jika semua ✅ SELESAI, lanjut implementasi di Flutter! 🎉**

---

## 📚 Resources

- OpenAI API Keys: https://platform.openai.com/api-keys
- OpenAI Pricing: https://openai.com/pricing
- Supabase Edge Functions Docs: https://supabase.com/docs/guides/functions
- File Edge Function: `supabase/functions/generate-motivational-quotes/index.ts`
