# 🚀 QUICK START: Generate Quotes dengan Gemini (GRATIS!)

## ⚡ 3 Langkah Mudah:

### **1️⃣ Dapatkan Gemini API Key (2 menit)**
- Buka: https://aistudio.google.com/app/apikey
- Login dengan Google
- Klik "Get API Key" → Copy (format: `AIza...`)
- ✅ **100% GRATIS!**

### **2️⃣ Set di Supabase (1 menit)**
- Buka: https://supabase.com/dashboard
- Settings → Edge Functions → Manage secrets
- Add: `GEMINI_API_KEY` = `AIza...` (paste key Anda)

### **3️⃣ Deploy Edge Function (2 menit)**

**Option A: Via Dashboard (Paling Mudah):**
1. Edge Functions → Create function
2. Name: `generate-motivational-quotes`
3. Copy-paste file: `EDGE_FUNCTION_CODE_TO_COPY.ts`
4. Deploy!

**Option B: Via File:**
- File sudah ada di: `supabase/functions/generate-motivational-quotes/index.ts`
- Copy-paste ke Supabase Dashboard

---

## ✅ Test Langsung:

Setelah deploy, test di Supabase Dashboard:

**Invoke with:**
```json
{
  "count": 3,
  "theme": "general"
}
```

**Expected result:**
```json
{
  "success": true,
  "generated_count": 3,
  "quotes_preview": ["Quote 1", "Quote 2", "Quote 3"]
}
```

---

## 🎯 Akses di Flutter App:

1. Run app: `flutter run`
2. Login
3. Account → **"Admin - Generate Quotes"**
4. Set jumlah & theme
5. Klik **"Generate Quotes"**
6. ✅ Done!

---

## 💰 Gratis Selamanya?

**Ya!** Gemini free tier:
- ✅ **1,000,000 tokens/month** (FREE!)
- ✅ **15 requests/minute**
- ✅ Cukup untuk **ribuan quotes per bulan**
- ✅ **Tidak perlu credit card**

---

## 📝 File Penting:

| File | Fungsi |
|------|--------|
| `DEPLOY_GEMINI_GUIDE.md` | Panduan lengkap deployment |
| `EDGE_FUNCTION_CODE_TO_COPY.ts` | Code siap copy-paste |
| `supabase_populate_quotes.sql` | Populate manual (backup) |
| `lib/pages/admin_quotes_page.dart` | UI admin |

---

## ❓ Troubleshooting Cepat:

**Error: API key not found**
→ Check secret name: harus `GEMINI_API_KEY` (uppercase)

**Error: API key not valid**  
→ Generate ulang di: https://aistudio.google.com/app/apikey

**Error: Function not found**
→ Tunggu 1-2 menit setelah deploy

---

## 🎉 Selesai!

Sekarang Anda punya AI quote generator yang:
- ✅ **GRATIS selamanya**
- ✅ **Unlimited** (1M tokens/month)
- ✅ **Kualitas bagus** untuk Bahasa Indonesia

**Happy generating! 🚀**

---

**Need help?** Baca: `DEPLOY_GEMINI_GUIDE.md`
