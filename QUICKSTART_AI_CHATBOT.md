# 🤖 QUICK START: AI Chatbot Synergy (Student Relationship Management)

Panduan lengkap implementasi AI Chatbot dengan Gemini API yang context-aware dan adaptif terhadap data mahasiswa.

---

## 📋 LANGKAH-LANGKAH IMPLEMENTASI

### **STEP 1: Setup Tabel Database (5 menit)**

1. **Buka Supabase Dashboard** → SQL Editor
2. **Copy-paste** isi file `supabase_chat_messages_setup.sql`
3. **Run** query
4. ✅ **Verify**: Check tabel `chat_messages` sudah dibuat

**Fungsi tabel ini:**
- Menyimpan riwayat percakapan user dengan AI
- User context untuk RAG (Retrieval-Augmented Generation)
- Row-Level Security (RLS) untuk privacy

---

### **STEP 2: Setup Gemini API Key (2 menit)**

#### **Dapatkan API Key (GRATIS!):**

1. Buka: https://aistudio.google.com/app/apikey
2. Login dengan Google
3. Klik **"Get API Key"** → Copy (format: `AIza...`)
4. ✅ **100% GRATIS!**

   - 1,000,000 tokens/month
   - 15 requests/minute
   - Tidak perlu credit card

#### **Set di Supabase:**

**Option A: Via Dashboard (Paling Mudah)**
1. Supabase Dashboard → Settings → Edge Functions
2. **Manage secrets** → Add new secret
3. Name: `GEMINI_API_KEY`
4. Value: Paste API key Anda (`AIza...`)
5. Save

**Option B: Via CLI**
```bash
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

---

### **STEP 3: Deploy Edge Function (3 menit)**

#### **Option A: Via Supabase Dashboard (Recommended)**

1. **Edge Functions** → Create function
2. **Name:** `gemini-chat`
3. **Copy-paste** isi file: `supabase/functions/gemini-chat/index.ts`
4. **Deploy!**

#### **Option B: Via Supabase CLI**

```powershell
# Install Supabase CLI (jika belum)
scoop install supabase

# Login ke Supabase
supabase login

# Link project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy edge function
supabase functions deploy gemini-chat

# Verify deployment
supabase functions list
```

---

### **STEP 4: Test Edge Function (2 menit)**

#### **Test di Supabase Dashboard:**

1. Edge Functions → `gemini-chat` → **Invoke**
2. **Request Body:**
   ```json
   {
     "message": "Halo! Perkenalkan dirimu sebagai AI assistant untuk myITS Synergy",
     "include_context": false
   }
   ```
3. Klik **"Send Request"**
4. **Expected Response:**
   ```json
   {
     "success": true,
     "response": "Halo! Saya adalah Synergy AI Assistant...",
     "context_used": false,
     "timestamp": "2026-02-23T..."
   }
   ```

**💡 Note:** 
- Ketika `include_context: false`, authentication **tidak diperlukan** (untuk testing)
- Ketika `include_context: true`, **wajib** menggunakan authentication
- Untuk test dengan context, gunakan Flutter app langsung

#### **Test via PowerShell:**

```powershell
# File: test-synergy-chat.ps1

$SUPABASE_URL = "https://YOUR_PROJECT.supabase.co"
$ANON_KEY = "YOUR_ANON_KEY"

$headers = @{
    "Authorization" = "Bearer $ANON_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    message = "Halo! Gimana jadwal kuliah aku minggu ini?"
    include_context = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/gemini-chat" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

---

### **STEP 5: Run Flutter App (1 menit)**

```powershell
# Install dependencies (jika ada yang baru)
flutter pub get

# Run app
flutter run
```

**Di aplikasi:**
1. Login dengan akun Anda
2. Di **Home Page**, klik **FAB AI di kanan bawah** (ikon robot 🤖)
3. Mulai chat!

**Contoh pertanyaan:**
- "Jadwal kuliah aku minggu ini apa aja?"
- "Tugas mana yang paling urgent?"
- "Organisasi apa aja yang aku ikuti?"
- "Aku sibuk banget minggu ini, bantu analisis dong"

---

## 🎯 FITUR-FITUR YANG SUDAH DIIMPLEMENTASI

### ✅ **Context-Aware Chatbot**
AI secara otomatis membaca data dari database:
- 📝 Profile mahasiswa (nama, NPM, jurusan, semester)
- 📚 Jadwal kuliah (7 hari ke depan)
- ✅ Tugas/deadline (14 hari ke depan)
- 🏢 Organisasi & peran aktif
- 🏆 Kompetisi terbaru
- 💼 Jumlah project

### ✅ **Conversation History**
- Chat tersimpan otomatis di database
- AI mengingat konteks percakapan sebelumnya
- Multi-turn conversation yang natural

### ✅ **Smart Features**
- 🧠 **Workload Analysis**: "Cek workload-ku minggu depan"
- 🎯 **Decision Making**: "Lomba vs Kuis, gimana?"
- 📊 **Smart Suggestions**: Suggestion chips untuk pertanyaan cepat
- 📈 **Chat Statistics**: Tracking percakapan

### ✅ **UI/UX Modern**
- Material Design 3
- Chat bubbles dengan timestamp
- Typing indicator saat AI berpikir
- Empty state dengan suggestions
- Clear chat history feature

---

## 🚀 USE CASES SESUAI GEMINI RECOMMENDATION

### 1️⃣ **Workload Analysis (Burnout CRM)**
```
User: "Cak, minggu depan jadwalku seberapa padat?"

AI: "Oke aku cek ya... Minggu depan kamu punya:
     📚 5 jadwal kuliah
     ✅ 2 deadline tugas (Sistem Operasi & Basis Data)
     🏢 1 rapat BEM
     
     Agak padat ya, tapi masih manageable. Prioritaskan 
     tugas Sistem Operasi dulu karena due date lebih dekat."
```

### 2️⃣ **Decision Making**
```
User: "Aku ada lomba di Jakarta hari Jumat, tapi ada 
       kuis Kalkulus juga. Gimana menurutmu?"

AI: "Hmm, trade-off yang sulit nih. Aku liat data kamu:
     - Kalkulus: mata kuliah wajib, bobot SKS 4
     - Kuis biasanya 15-20% dari nilai akhir
     - Lomba: kompetisi tingkat nasional
     
     Saranku: Coba komunikasi sama dosen bisa reschedule 
     kuis atau ambil susulan. Lomba nasional kesempatan 
     yang jarang datang."
```

### 3️⃣ **Auto Portfolio Insight**
```
User: "Semester ini aku udah ikut kegiatan apa aja?"

AI: "Keren nih semester ini produktif banget! 
     🏢 Organisasi: BEM ITS (Staff Kominfo)
     🏆 Kompetisi: Gemastik 2026, BNCC Hackathon
     💼 2 project sedang berjalan
     
     Bisa jadi highlight bagus buat CV atau LinkedIn!"
```

### 4️⃣ **Study Planning**
```
User: "UTS 2 minggu lagi, bantu susun jadwal belajar dong"

AI: "Siap! Aku liat jadwal kuliah kamu ada 6 mata kuliah.
     
     📅 Rekomendasi study plan:
     Week 1: Fokus 3 mata kuliah terberat
       - Senin-Rabu: Sistem Operasi & Algoritma
       - Kamis-Jumat: Basis Data
     
     Week 2: Review & latihan soal
       - 3 mata kuliah lainnya
       - Mock test weekend
     
     Jangan lupa istirahat ya!"
```

---

## 📁 FILE-FILE YANG DIBUAT

| File | Fungsi |
|------|--------|
| `supabase_chat_messages_setup.sql` | Setup tabel & functions database |
| `supabase/functions/gemini-chat/index.ts` | Edge function untuk AI chatbot |
| `supabase/functions/gemini-chat/README.md` | Dokumentasi edge function |
| `lib/models/chat_message.dart` | Model untuk chat message |
| `lib/services/gemini_chat_service.dart` | Service untuk komunikasi dengan AI |
| `lib/pages/chat_page.dart` | UI halaman chat |
| `lib/pages/home_page.dart` | **Modified** - Added AI FAB button |

---

## ⚙️ CUSTOMIZATION

### **Ubah Personality AI:**

Edit file `supabase/functions/gemini-chat/index.ts`, bagian `buildSystemPrompt`:

```typescript
let prompt = `Kamu adalah asisten AI untuk myITS Synergy...

📋 IDENTITAS & KARAKTER:
- Nama: Synergy AI Assistant
- Personality: [EDIT DISINI - misal: Lebih santai, formal, humoris, dll]
- ...
```

### **Ubah Warna AI Chat Bubble:**

Edit file `lib/pages/chat_page.dart`:

```dart
// Line ~766
backgroundColor: const Color(0xFF673AB7), // Ganti warna disini
```

### **Ubah Context yang Diambil:**

Edit `supabase/functions/gemini-chat/index.ts`, function `getUserContext`:
- Tambah/kurangi data yang diambil dari database
- Sesuaikan limit query

---

## ❓ TROUBLESHOOTING

### **Error: GEMINI_API_KEY not found**
✅ **Fix:** Set secret di Supabase (lihat STEP 2)

### **Error: Gemini API error: 404 atau 500**
✅ **Fix:** Model sudah diupdate ke `gemini-2.5-flash` (sama seperti quote generator)
✅ **Action:** Redeploy edge function dengan code terbaru
✅ **Verify:** Check API key masih valid di https://aistudio.google.com/app/apikey

### **Error: Invalid authentication**
✅ **Fix saat test di Dashboard:** 
   - Pastikan `"include_context": false` di request body
   - JANGAN tambahkan Authorization header
   
✅ **Fix di Flutter app:** Logout & login ulang

### **AI response lambat**
✅ **Normal:** First request bisa 3-5 detik (cold start)  
✅ **Subsequent:** Lebih cepat (1-2 detik)

### **Chat history tidak muncul**
✅ **Fix:** Check RLS policy di tabel `chat_messages`  
✅ **Run:** Query setup SQL lagi

### **Edge Function error**
✅ **Check logs:** Supabase Dashboard → Edge Functions → Logs  
✅ **Redeploy:** Deploy ulang edge function

---

## 🎉 NEXT STEPS (Future Enhancement)

Sesuai saran Gemini, fitur yang bisa ditambahkan:

- [ ] **Voice Input**: Chat dengan suara
- [ ] **Export Chat**: Download percakapan sebagai PDF
- [ ] **Smart Reminders**: AI proaktif mengirim notifikasi
- [ ] **Study Buddy**: Matching dengan mahasiswa lain
- [ ] **Auto Portfolio Generator**: Generate CV dari data
- [ ] **Mental Health Check**: Deteksi burnout & kasih saran
- [ ] **Schedule Optimizer**: AI optimize jadwal harian

---

## 💡 TIPS PENGGUNAAN

1. **Be Specific**: Semakin detail pertanyaan, semakin akurat jawaban AI
2. **Use Context**: AI otomatis baca data kamu, jadi bisa langsung tanya "jadwalku" tanpa sebutkan nama
3. **Ask Follow-up**: AI ingat percakapan sebelumnya
4. **Explore**: Coba berbagai jenis pertanyaan (analisis, saran, motivasi)

---

## 📞 SUPPORT

Jika ada masalah:
1. Check troubleshooting section
2. Check Supabase Edge Function logs
3. Check Flutter debug console

---

**🎓 Built for ITS Students, by ITS Developer**  
**Powered by Google Gemini 2.5 Flash**
