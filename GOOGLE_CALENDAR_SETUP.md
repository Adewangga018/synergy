# Setup Google Calendar Integration 📅

Panduan lengkap untuk mengaktifkan integrasi Google Calendar di aplikasi Synergy.

## 📋 Fitur Kalender

Aplikasi Synergy sekarang memiliki fitur kalender yang mengagregasi semua data pribadi Anda:

✅ **Jadwal Kuliah** - Event recurring berdasarkan hari
✅ **Kompetisi** - Tanggal event kompetisi  
✅ **Volunteer** - Tanggal mulai dan selesai kegiatan
✅ **Organisasi** - Periode bergabung di organisasi
✅ **Proyek** - Timeline proyek Anda
✅ **Google Calendar** - Event manual dari Google Calendar
✅ **Sinkronisasi** - Sync semua event ke Google Calendar

## 🔧 Setup Google Calendar API

### 1. Buat Project di Google Cloud Console

1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Klik **Create Project** atau pilih project existing
3. Beri nama project (misal: "Synergy App")
4. Klik **Create**

### 2. Enable Google Calendar API

1. Di Google Cloud Console, buka **APIs & Services** > **Library**
2. Cari **Google Calendar API**
3. Klik **Enable**

### 3. Setup OAuth Consent Screen

1. Buka **APIs & Services** > **OAuth consent screen**
2. Pilih **External** sebagai User Type
3. Klik **Create**
4. Isi informasi:
   - **App name**: Synergy
   - **User support email**: Email Anda
   - **Developer contact**: Email Anda
5. Klik **Save and Continue**
6. Di **Scopes**, klik **Add or Remove Scopes**
7. Tambahkan scope: `.../auth/calendar` (Google Calendar API)
8. Klik **Update** > **Save and Continue**
9. Di **Test users**, klik **Add Users**
10. Tambahkan email Anda untuk testing
11. Klik **Save and Continue** > **Back to Dashboard**

### 4. Buat OAuth 2.0 Credentials

#### Untuk Android:

1. Buka **APIs & Services** > **Credentials**
2. Klik **Create Credentials** > **OAuth client ID**
3. Pilih **Android**
4. Isi informasi:
   - **Name**: Synergy Android
   - **Package name**: `com.example.synergy` (sesuai AndroidManifest.xml)
   - **SHA-1 certificate fingerprint**: (lihat cara mendapatkan di bawah)

**Cara mendapatkan SHA-1:**

**Metode 1: Menggunakan Gradle (Paling Mudah)**

```powershell
# Di terminal PowerShell
cd e:\Karya\synergy\android
.\gradlew signingReport
```

Cari bagian "Variant: debug" dan copy SHA1 fingerprint.

**Metode 2: Jika Gradle error, gunakan keytool dengan path lengkap**

Pertama, cari lokasi Java:
```powershell
where.exe java
```

Kemudian gunakan path keytool (biasanya di folder yang sama dengan java):
```powershell
# Contoh jika Java di C:\Program Files\Java\jdk-17\bin\
& "C:\Program Files\Java\jdk-17\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Metode 3: Cara Termudah - Skip SHA-1 untuk Development**

Untuk development/testing, Anda bisa:
1. Buat OAuth Client ID untuk **Web Application** saja (tidak perlu SHA-1)
2. Gunakan Google Sign-In akan tetap bekerja di Android emulator
3. Untuk production/release, baru tambahkan SHA-1

**Metode 4: Menggunakan Android Studio (jika installed)**

1. Buka Android Studio
2. File > Project Structure > Modules > app
3. Tab "Signing"
4. Lihat SHA-1 di bagian "Debug keystore"

Copy SHA-1 fingerprint dan paste ke Google Cloud Console

5. Klik **Create**

#### Untuk iOS (Jika deploy ke iOS):

1. Klik **Create Credentials** > **OAuth client ID**
2. Pilih **iOS**
3. Isi **Bundle ID**: `com.example.synergy` (sesuai Xcode)
4. Klik **Create**

#### Untuk Web (Jika deploy ke Web):

1. Klik **Create Credentials** > **OAuth client ID**  
2. Pilih **Web application**
3. Isi **Name**: Synergy Web
4. Di **Authorized JavaScript origins**, tambahkan:
   - `http://localhost`
   - URL production Anda (jika ada)
5. Klik **Create**

### 5. Download Credentials (Opsional untuk beberapa platform)

Untuk Android, tidak perlu download file JSON. Cukup package name dan SHA-1.

## 📱 Konfigurasi di Aplikasi

### Android Configuration

File `android/app/build.gradle.kts` sudah dikonfigurasi dengan:
```kotlin
applicationId = "com.example.synergy"
```

Pastikan package name di `AndroidManifest.xml` sama:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.synergy">
```

### Permissions (Sudah ditambahkan)

File `android/app/src/main/AndroidManifest.xml` harus memiliki:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 🚀 Cara Menggunakan Fitur Kalender

### 1. Buka Halaman Kalender

- Dari **Home Page**, klik menu **"Kalender"** (ikon kalender pink)
- Atau tambahkan navigasi dari fitur lain

### 2. Lihat Event

- **Calendar View**: Lihat semua event dalam bentuk kalender
- **Event Markers**: Tanggal dengan event ditandai dengan dot
- **Event List**: Klik tanggal untuk melihat detail event di tanggal tersebut

### 3. Filter Event

- Klik ikon **Filter** (filter_list) di AppBar
- Pilih/hapus centang kategori event yang ingin ditampilkan:
  - ☑️ Jadwal Kuliah
  - ☑️ Kompetisi
  - ☑️ Volunteer
  - ☑️ Organisasi
  - ☑️ Dokumen
  - ☑️ Proyek
  - ☑️ Catatan
  - ☑️ Manual (dari Google Calendar)

### 4. Sinkronisasi ke Google Calendar

**Pertama kali:**
1. Klik ikon **Cloud** di AppBar (cloud_off)
2. Pilih akun Google Anda
3. Beri izin akses Google Calendar
4. Klik **Allow**

**Sinkronisasi Event:**
1. Setelah sign in, klik ikon **Cloud** (sekarang cloud_done)
2. Konfirmasi sinkronisasi
3. Tunggu proses selesai
4. Event dari Synergy akan muncul di Google Calendar Anda

**Hasil Sinkronisasi:**
- Event akan muncul di Google Calendar dengan warna berbeda per kategori
- Event sudah ada akan di-update (bukan duplikat)
- Event manual di Google Calendar akan ditampilkan di Synergy

## 🎨 Warna Event di Kalender

| Kategori | Warna | Keterangan |
|----------|-------|------------|
| Jadwal Kuliah | Teal | Event recurring per minggu |
| Kompetisi | Pink | Event tanggal kompetisi |
| Volunteer | Orange | Start/end date kegiatan |
| Organisasi | Purple | Join/leave date organisasi |
| Dokumen | Blue | Tanggal deadline (jika ada) |
| Proyek | Green | Timeline proyek |
| Catatan | Yellow | Tanggal catatan penting |
| Manual | Grey | Event dari Google Calendar |

## 📊 Data yang Ditampilkan

### Jadwal Kuliah (Recurring Event)
- **Frekuensi**: Setiap minggu sesuai hari kuliah
- **Range**: 4 bulan ke depan dari bulan sekarang
- **Detail**: Mata kuliah, dosen, ruangan, jam

### Kompetisi (Single Event)
- **Tanggal**: Event date kompetisi
- **Detail**: Nama kompetisi, kategori, prestasi

### Volunteer (Start/End Event)
- **2 Event**: Tanggal mulai dan tanggal selesai
- **Detail**: Nama kegiatan, peran

### Organisasi (Period Event)  
- **2 Event**: Join date dan end date (jika ada)
- **Detail**: Nama organisasi, posisi, skala

### Proyek (Timeline Event)
- **2 Event**: Start date dan end date (jika ada)  
- **Detail**: Judul proyek, peran, teknologi

## 🔐 Keamanan & Privacy

- ✅ OAuth 2.0 secure authentication
- ✅ Hanya akses Google Calendar scope (tidak akses data lain)
- ✅ Token disimpan secara aman oleh Google Sign-In package
- ✅ User dapat revoke access kapan saja dari Google Account Settings
- ✅ Event source dari Synergy diberi label "Synergy App"

## ⚠️ Troubleshooting

### Error: "Sign in failed"
**Solusi:**
1. Pastikan OAuth credentials sudah dibuat dengan benar
2. Cek package name sama dengan `applicationId` di build.gradle
3. Cek SHA-1 fingerprint sudah ditambahkan
4. Coba uninstall app dan install ulang

### Error: "Not signed in to Google"
**Solusi:**
1. Klik ikon Cloud untuk sign in
2. Pastikan internet aktif
3. Pilih akun Google yang sudah ditambahkan sebagai test user

### Event tidak muncul di Google Calendar
**Solusi:**
1. Pastikan sinkronisasi berhasil (lihat snackbar message)
2. Refresh Google Calendar (pull down)
3. Cek di Google Calendar web version

### Duplicate events di Google Calendar
**Solusi:**
- Event dengan Google Calendar Event ID akan di-update, bukan dibuat baru
- Jika ada duplikat, hapus manual di Google Calendar

### Permission denied
**Solusi:**
1. Pastikan email Anda ada di Test Users (OAuth consent screen)
2. Pastikan scope `.../auth/calendar` sudah ditambahkan
3. Revoke access di Google Account lalu sign in ulang

## 📝 Catatan Penting

1. **Test Mode**: Saat OAuth consent screen dalam status "Testing", hanya test users yang bisa login
2. **Production**: Untuk publish app ke Play Store, ubah consent screen ke "In Production"
3. **Quota**: Google Calendar API memiliki quota limit (10,000 requests/day default)
4. **Offline**: Event lokal tetap bisa dilihat tanpa Google Sign In
5. **Sinkronisasi**: One-way sync dari Synergy → Google Calendar (belum two-way)

## 🔄 Update & Maintenance

**Jika mengubah package name:**
1. Update `applicationId` di build.gradle
2. Buat OAuth credentials baru dengan package name baru
3. Generate SHA-1 baru
4. Update di Google Cloud Console

**Jika mengubah signing key:**
1. Generate SHA-1 dari keystore baru
2. Tambahkan SHA-1 baru ke OAuth credentials existing

## 📚 Referensi

- [Google Calendar API Documentation](https://developers.google.com/calendar/api/guides/overview)
- [Google Sign-In Flutter Package](https://pub.dev/packages/google_sign_in)
- [googleapis Package](https://pub.dev/packages/googleapis)
- [OAuth 2.0 Setup Guide](https://support.google.com/cloud/answer/6158849)

---

**Dibuat untuk Synergy App** 🎓
Version: 1.0.0  
Last Updated: February 19, 2026
