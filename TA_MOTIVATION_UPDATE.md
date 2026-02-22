# Update: Motivasi Tugas Akhir (TA) untuk Mahasiswa Tingkat Akhir

## 📋 Ringkasan Update

Sistem motivational quotes sekarang dapat mendeteksi mahasiswa tingkat akhir (semester 7-8) dan memberikan quotes motivasi khusus untuk mendukung penyelesaian Tugas Akhir (TA).

## 🎯 Fitur Baru

### 1. Deteksi Otomatis Mahasiswa TA
- **Kriteria**: Mahasiswa yang pernah mengambil mata kuliah di semester 7 atau 8
- **Sumber data**: Tabel `course_schedules` di database
- **Metode**: Query untuk memeriksa apakah ada record dengan `semester = 7` atau `semester = 8`

### 2. Quote Generation dengan Tema "tugas-akhir"
Ketika mahasiswa tingkat akhir terdeteksi, sistem akan:
- Menggunakan tema khusus "tugas-akhir"
- Generate quotes yang fokus pada:
  - ✅ Semangat menyelesaikan TA
  - ✅ Konsistensi dalam progress (sedikit demi sedikit)
  - ✅ Mengatasi writer's block dan rasa jenuh
  - ✅ Percaya diri menghadapi bimbingan dan revisi
  - ✅ Motivasi bahwa finish line sudah dekat
  - ✅ Work-life balance selama TA

### 3. Prompt Khusus di Gemini AI
Edge Function sekarang memiliki special handling untuk tema "tugas-akhir":
- Tone: Empati, supportive, realistic
- Acknowledge bahwa TA itu challenging tapi achievable
- Bahasa yang friendly seperti teman sebaya
- Maksimal 150 karakter untuk mudah dibaca

## 🔧 File yang Dimodifikasi

### 1. `lib/services/motivational_quote_service.dart`
**Perubahan**:
- ➕ Method `_isFinalYearStudent(String userId)` untuk deteksi mahasiswa semester 7-8
- 🔄 Update `getOrGenerateDailyQuote({String? userId})` untuk:
  - Accept parameter `userId` (optional)
  - Deteksi status mahasiswa TA
  - Pass theme "tugas-akhir" ke Edge Function jika terdeteksi

**Kode tambahan**:
```dart
/// Deteksi apakah user adalah mahasiswa tingkat akhir (semester 7-8)
Future<bool> _isFinalYearStudent(String userId) async {
  try {
    final response = await _supabase
        .from('course_schedules')
        .select('semester')
        .eq('user_id', userId)
        .or('semester.eq.7,semester.eq.8')
        .limit(1);

    return (response as List).isNotEmpty;
  } catch (e) {
    print('Error checking final year status: $e');
    return false;
  }
}
```

### 2. `lib/pages/home_page.dart`
**Perubahan**:
- 🔄 Update `_loadRandomQuote()` untuk pass `userId` ke service
- 🔄 Update `_loadUserProfile()` untuk load quote SETELAH profile tersedia
- 🔄 Update `initState()` untuk tidak langsung call `_loadRandomQuote()` (akan dipanggil otomatis setelah profile di-load)

**Flow baru**:
```
initState() → _loadUserProfile() → (setelah profile ready) → _loadRandomQuote()
```

### 3. `supabase/functions/generate-motivational-quotes/index.ts`
**Perubahan**:
- 🔄 Update prompt generation untuk mengenali tema "tugas-akhir"
- ➕ Tambah conditional special instruction untuk TA theme:
  - Fokus pada motivasi finishing thesis
  - Tone empati dan supportive
  - Acknowledge challenges mahasiswa TA

**Snippet kode**:
```typescript
${theme === 'tugas-akhir' ? `
🎓 SPECIAL THEME: MOTIVASI TUGAS AKHIR (TA) 🎓
Quote khusus untuk mahasiswa tingkat akhir (semester 7-8) yang sedang mengerjakan Tugas Akhir.

Fokus motivasi:
- Semangat menyelesaikan TA di tengah tantangan
- Konsistensi dalam progress TA
- Mengatasi rasa jenuh dan writer's block
- Percaya diri menghadapi bimbingan dan revisi
- Mengingatkan bahwa finish line sudah dekat
...
` : ''}
```

## 🚀 Cara Deploy Update

### Step 1: Update Edge Function di Supabase Dashboard

1. Buka Supabase Dashboard → Select project "Synergy"
2. Navigasi ke **Edge Functions** (ikon ⚡ di sidebar)
3. Cari function **`generate-motivational-quotes`**
4. Klik **Edit Function**
5. Copy isi file `supabase/functions/generate-motivational-quotes/index.ts`
6. Paste ke editor di dashboard
7. Klik **Save** atau **Deploy**

### Step 2: Test dengan User Semester 7-8

1. Pastikan ada user di database dengan course_schedules semester 7 atau 8:
```sql
-- Check user dengan mata kuliah semester 7-8
SELECT DISTINCT user_id, semester 
FROM course_schedules 
WHERE semester IN (7, 8)
LIMIT 5;
```

2. Login dengan user tersebut di aplikasi
3. Home page akan otomatis detect dan generate quote dengan tema TA
4. Check console log untuk melihat: `"Detected final year student - using TA motivation theme"`

### Step 3: Verify Quote Generation

Quotes yang di-generate untuk mahasiswa TA akan:
- Tema: `tugas-akhir`
- Isi: Motivasi khusus tentang penyelesaian TA
- Context: Relevan untuk mahasiswa semester 7-8

## 📊 Testing Scenarios

### Scenario 1: Mahasiswa Semester 7-8 (TA Student)
- **User**: Punya course_schedules dengan semester 7 atau 8
- **Expected**: Quote dengan tema "tugas-akhir" yang menyemangati TA
- **Log**: "Detected final year student - using TA motivation theme"

### Scenario 2: Mahasiswa Non-TA (Semester 1-6)
- **User**: Tidak punya course_schedules semester 7-8
- **Expected**: Quote dengan tema normal (auto-detect: UTS, UAS, general, dll)
- **Log**: "No quote for today, generating new one..."

### Scenario 3: User Tanpa Course Schedules
- **User**: Belum input jadwal kuliah
- **Expected**: Quote dengan tema general (auto-detect context)
- **Behavior**: Graceful fallback ke quote general

## 🔍 How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  1. User buka Home Page                                      │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Load User Profile (get userId)                           │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Load Daily Quote (pass userId to service)                │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Service: Check if user is in semester 7-8                │
│     - Query course_schedules table                           │
│     - Filter: semester IN (7, 8) AND user_id = userId        │
└───────────────┬─────────────────────────────────────────────┘
                │
        ┌───────┴──────────┐
        │                  │
        ▼                  ▼
    YES (TA)           NO (Non-TA)
        │                  │
        ▼                  ▼
┌──────────────┐    ┌──────────────┐
│ theme =      │    │ theme =      │
│ "tugas-akhir"│    │ auto-detect  │
└──────┬───────┘    └──────┬───────┘
       │                   │
       └────────┬──────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Check today's quote in DB                                │
└───────────────┬─────────────────────────────────────────────┘
                │
        ┌───────┴──────────┐
        │                  │
        ▼                  ▼
    EXISTS            NOT EXISTS
        │                  │
        ▼                  ▼
┌──────────────┐    ┌──────────────────────────────────────┐
│ Return DB    │    │ Call Edge Function generateQuotes()  │
│ Quote (fast!)│    │ - Pass theme: "tugas-akhir" atau auto│
└──────────────┘    │ - Gemini generates contextual quote  │
                    └──────────────────┬───────────────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │ Save to DB & Return  │
                            └──────────────────────┘
```

## 🎓 Contoh Quotes untuk TA Theme

Berikut contoh quotes yang mungkin di-generate untuk mahasiswa TA:

1. **Konsistensi Progress**:
   - "1 paragraf sehari, dalam 30 hari jadi 1 bab. Progress TA dimulai dari langkah kecil!"
   - "Revisi itu tanda TA-mu semakin matang. Terus semangat perbaiki!"

2. **Motivasi Finishing**:
   - "TA adalah marathon terakhir sebelum wisuda. Finish line sudah terlihat, jangan berhenti!"
   - "Setiap bimbingan yang kamu jalani adalah 1 step lebih dekat ke gelar sarjana!"

3. **Mengatasi Jenuh**:
   - "Writer's block? Tulis aja dulu yang bisa, edit belakangan. Progress over perfection!"
   - "Stuck di BAB 4? Istirahat sejenak, refresh pikiran, balik lagi dengan semangat baru!"

4. **Work-Life Balance**:
   - "TA penting, tapi jaga kesehatan juga. Istirahat cukup = pikiran jernih = hasil maksimal!"
   - "Sempat-sempatkan jalan keliling kampus, TA tetap jalan, mental tetap sehat!"

## 🐛 Troubleshooting

### Issue: Quote tidak sesuai dengan status mahasiswa
**Solusi**:
1. Check console log untuk melihat detection result
2. Verify data di `course_schedules` table:
```sql
SELECT * FROM course_schedules WHERE user_id = 'USER_ID_HERE';
```
3. Pastikan ada course dengan semester 7 atau 8

### Issue: Edge Function tidak update
**Solusi**:
1. Clear cache browser (Ctrl+Shift+R)
2. Re-deploy Edge Function di Supabase Dashboard
3. Check Edge Function logs untuk error

### Issue: Quote masih pakai tema lama
**Solusi**:
1. Clear today's quote dari database:
```sql
DELETE FROM motivational_quotes 
WHERE created_at::date = CURRENT_DATE;
```
2. Refresh aplikasi, akan generate quote baru dengan tema yang benar

## 📝 Notes

- **Performance**: Query course_schedules hanya dilakukan SEKALI per hari (saat generate quote baru)
- **Cache**: Quote disimpan di DB, jadi tidak perlu re-detect atau re-generate setiap page load
- **Fallback**: Jika deteksi gagal atau error, sistem fallback ke quote general (no crash!)
- **Privacy**: Detection hanya dilakukan client-side, tidak ada tracking atau analytics

## 🎉 Benefits

1. **Personalisasi**: Mahasiswa TA mendapat motivasi yang lebih relevan
2. **Empati**: Sistem acknowledge tantangan spesifik mahasiswa tingkat akhir
3. **Efisiensi**: Auto-detect, tidak perlu manual setting
4. **Scalable**: Mudah tambahkan tema baru untuk konteks lain (organisasi, kompetisi, dll)

---

**Last Updated**: 2025
**Version**: 1.0.0
**Contributors**: Synergy Team
