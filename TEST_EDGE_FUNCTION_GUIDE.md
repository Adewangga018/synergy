# Step-by-step Test Edge Function di Supabase Dashboard

1. Buka: Supabase Dashboard → Edge Functions → `gemini-chat`

2. Klik tombol **"Invoke"**

3. Di form yang muncul:
   - **HTTP Method:** POST (sudah default)
   - **Request Body:** Paste JSON ini:
     ```json
     {
       "message": "Halo! Perkenalkan dirimu sebagai AI assistant untuk myITS Synergy",
       "include_context": false
     }
     ```
   - **Headers:** Biarkan kosong (tidak perlu Authorization header karena include_context = false)

4. Klik **"Send Request"** atau **"Run"**

5. ✅ Expected Response (200 OK):
   ```json
   {
     "success": true,
     "response": "Halo! Saya adalah Synergy AI Assistant, asisten cerdas untuk aplikasi myITS Synergy...",
     "context_used": false,
     "timestamp": "2026-02-23T..."
   }
   ```

## Common Issues:

❌ **401 Invalid authentication**
→ Pastikan `"include_context": false` di request body
→ Jangan tambahkan Authorization header saat testing tanpa context

❌ **GEMINI_API_KEY not found**
→ Check secret di Settings → Edge Functions → Manage secrets
→ Nama secret harus PERSIS: `GEMINI_API_KEY` (case sensitive)
→ Restart edge function setelah set secret (redeploy)

❌ **Function not found**
→ Tunggu 1-2 menit setelah deployment
→ Refresh browser
→ Pastikan nama function: `gemini-chat` (tanpa spasi/typo)

❌ **500 Internal Server Error atau Gemini API error: 404**
→ Model Gemini salah atau tidak tersedia
→ **SOLUTION:** Redeploy dengan code terbaru (sudah diupdate ke `gemini-2.5-flash`)
→ Check Edge Functions → Logs untuk detail error

## Test berhasil jika:
✅ Status: 200 OK
✅ success: true
✅ Ada response dari AI yang relevan
