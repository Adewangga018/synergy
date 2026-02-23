# 🚀 REDEPLOY EDGE FUNCTION - Quick Guide

## Kenapa perlu redeploy?
1. Edge function sudah diupdate agar bisa test TANPA authentication saat `include_context = false`
2. **Model Gemini diupdate** dari `gemini-2.0-flash-exp` (tidak tersedia) ke `gemini-2.5-flash` (stable)

---

## CARA 1: Deploy via Dashboard (PALING MUDAH) ⭐

### Step-by-step:

1. **Buka file lokal:**
   - File: `supabase/functions/gemini-chat/index.ts`
   - Buka di VS Code
   - **Select All** (Ctrl+A) → **Copy** (Ctrl+C)

2. **Buka Supabase Dashboard:**
   - Edge Functions → `gemini-chat`
   - Klik **"Edit function"** atau ikon pensil

3. **Replace code:**
   - **Select all** code di editor
   - **Delete**
   - **Paste** code dari file lokal (Ctrl+V)

4. **Deploy:**
   - Klik **"Deploy"** atau **"Save"**
   - Tunggu hingga deployment selesai (~30 detik)
   - Status: **"Active"** (hijau)

---

## CARA 2: Deploy via CLI (ADVANCED)

```powershell
# Pastikan sudah login & linked
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Deploy function
supabase functions deploy gemini-chat

# Verify
supabase functions list
```

---

## TEST SETELAH DEPLOY:

1. **Invoke function:**
   - Edge Functions → `gemini-chat` → **Invoke**

2. **Request Body:**
   ```json
   {
     "message": "Halo! Perkenalkan dirimu sebagai AI assistant untuk myITS Synergy",
     "include_context": false
   }
   ```

3. **Send Request**

4. ✅ **Expected Result:**
   - Status: `200 OK`
   - Response body:
     ```json
     {
       "success": true,
       "response": "Halo! Saya adalah Synergy AI Assistant...",
       "context_used": false,
       "timestamp": "..."
     }
     ```

---

## TROUBLESHOOTING:

### ❌ Masih 401 Invalid authentication
→ **Pastikan sudah deploy ulang!** Edge function lama masih aktif
→ Refresh halaman Supabase Dashboard
→ Cek di Edge Functions → Logs untuk error detail

### ❌ GEMINI_API_KEY not found  
→ Settings → Edge Functions → Manage secrets
→ Add secret: Name = `GEMINI_API_KEY`, Value = API key Anda
→ **REDEPLOY** function setelah set secret

### ❌ Syntax error atau function error
→ Pastikan copy-paste code lengkap (tidak terpotong)
→ Check Edge Functions → Logs untuk error detail

---

## ✅ CHECKLIST:

- [ ] File `gemini-chat/index.ts` sudah terupdate (versi terbaru dari AI)
- [ ] Code sudah di-copy lengkap (Ctrl+A, Ctrl+C)
- [ ] Deploy berhasil (status "Active" hijau)
- [ ] Secret `GEMINI_API_KEY` sudah di-set
- [ ] Test invoke berhasil (200 OK)

---

**Setelah checklist semua ✅, langsung test!**
