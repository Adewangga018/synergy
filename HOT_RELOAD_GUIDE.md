# Flutter Hot Reload & Hot Restart - Quick Guide

## 🔥 Hot Reload vs Hot Restart

### Hot Reload (r) - PALING SERING DIPAKAI
**Cara:** Tekan `r` di terminal saat aplikasi running

**Kapan digunakan:**
- ✅ Mengubah UI/Widget
- ✅ Mengubah text, warna, spacing
- ✅ Menambah/menghapus widget
- ✅ Mengubah parameter widget
- ✅ Mengubah styling (padding, margin, colors, etc)

**Kelebihan:**
- ⚡ Super cepat (< 1 detik)
- 💾 State tetap tersimpan (tidak reset data)
- 🎯 Posisi halaman tidak berubah

**Contoh perubahan yang bisa Hot Reload:**
```dart
// BEFORE
Text('Login', style: TextStyle(fontSize: 16))

// AFTER - Tekan 'r'
Text('Masuk', style: TextStyle(fontSize: 18, color: Colors.blue))
```

---

### Hot Restart (R) - HURUF BESAR
**Cara:** Tekan `R` (shift + r) di terminal saat aplikasi running

**Kapan digunakan:**
- ✅ Mengubah class/function baru
- ✅ Mengubah import
- ✅ Mengubah logic di initState()
- ✅ Mengubah global variable
- ✅ Mengubah routing
- ✅ Menambah dependency baru

**Kelebihan:**
- ⚡ Lebih cepat dari full restart (2-5 detik)
- 🔄 Reset semua state
- 🎯 Mulai dari awal (seperti aplikasi baru dibuka)

**Contoh perubahan yang butuh Hot Restart:**
```dart
// Menambah import baru
import 'package:flutter/services.dart';

// Mengubah initState
@override
void initState() {
  super.initState();
  _loadData(); // <- Perubahan ini butuh 'R'
}
```

---

### Full Restart (flutter run ulang) - JARANG DIPAKAI
**Cara:** Stop (q) lalu `flutter run` lagi

**Kapan HARUS digunakan:**
- ❌ Mengubah pubspec.yaml (menambah package)
- ❌ Mengubah native code (Android/iOS)
- ❌ Menambah assets baru (gambar, font)
- ❌ Mengubah main.dart yang signifikan
- ❌ Error build yang tidak bisa di-hot reload

---

## 🎮 Keyboard Shortcuts Saat Running

Saat aplikasi running di terminal, tekan:

| Key | Fungsi | Kecepatan | Kapan Digunakan |
|-----|--------|-----------|-----------------|
| `r` | Hot Reload | ⚡⚡⚡ Instant | Perubahan UI/Widget |
| `R` | Hot Restart | ⚡⚡ Cepat | Perubahan logic/class |
| `s` | Screenshot | - | Ambil screenshot |
| `q` | Quit/Stop | - | Berhenti running |
| `h` | Help | - | Lihat semua commands |
| `p` | Debug Paint | - | Lihat debug layout |
| `o` | Platform Override | - | Switch Android/iOS |
| `w` | Widget Inspector | - | Debug widget tree |

---

## 📝 Workflow Development yang Efisien

### 1. Start Aplikasi Sekali
```bash
flutter run
```

### 2. Edit Kode
Buka file di editor (VS Code, Android Studio, dll)

### 3. Save File (Ctrl+S / Cmd+S)
Flutter akan auto-detect perubahan

### 4. Hot Reload
- **Otomatis** (jika setting enable): Langsung reload saat save
- **Manual**: Tekan `r` di terminal

### 5. Lihat Hasil
Aplikasi di emulator/device langsung update!

---

## ⚙️ Setup Auto Hot Reload (Recommended)

### VS Code:
1. Install extension: **Flutter**
2. Settings (Ctrl+,)
3. Cari: `flutter hot reload`
4. Enable: `Flutter: Hot Reload on Save`

### Android Studio:
1. File → Settings → Languages & Frameworks → Flutter
2. Enable: `Perform hot reload on save`

Setelah diaktifkan:
- ✅ Save file (Ctrl+S) = Auto hot reload!
- ✅ Tidak perlu tekan 'r' lagi

---

## 🐛 Troubleshooting

### Hot Reload Tidak Work?
**Solusi:**
1. Coba Hot Restart: tekan `R`
2. Jika masih tidak work, stop (q) dan `flutter run` lagi

### Error Setelah Hot Reload?
**Penyebab umum:**
- Mengubah class/function yang sedang digunakan
- Mengubah constructor

**Solusi:**
1. Tekan `R` untuk hot restart
2. Jika masih error: `q` → `flutter run`

### Perubahan Tidak Muncul?
**Checklist:**
- ✅ File sudah di-save?
- ✅ Tidak ada error compile? (check terminal)
- ✅ Sudah tekan 'r' atau 'R'?
- ✅ Mengubah file yang benar? (bukan file backup/copy)

---

## 💡 Tips Pro

### 1. Gunakan Hot Reload untuk 90% Perubahan
Hampir semua perubahan UI bisa pakai `r`

### 2. Hot Restart Jika Hot Reload Aneh
Kadang hot reload bikin widget duplikat atau layout aneh
→ Tekan `R` untuk reset

### 3. Full Restart Hanya untuk:
- Update packages
- Tambah assets
- Error yang tidak bisa diperbaiki dengan R

### 4. Testing di Multiple Devices
```bash
# Device 1
flutter run -d device_id_1

# Device 2 (terminal baru)
flutter run -d device_id_2
```

Hot reload akan apply ke semua device sekaligus!

### 5. Watch Mode
Flutter sudah punya watch mode built-in saat `flutter run`
Tidak perlu tool tambahan!

---

## 🎯 Contoh Praktis: Edit Login Page

### Scenario: Mengubah Text dan Warna

1. **Start app:**
   ```bash
   flutter run
   ```

2. **Edit file:** `lib/pages/login_page.dart`
   ```dart
   Text(
     'Masuk',
     style: TextStyle(fontSize: 16), // BEFORE
   )
   ```

3. **Ubah menjadi:**
   ```dart
   Text(
     'Login Sekarang',
     style: TextStyle(fontSize: 18, color: Colors.blue), // AFTER
   ```

4. **Save** (Ctrl+S)

5. **Tekan** `r` di terminal (atau auto jika sudah setup)

6. **✅ Langsung keliatan!** Text berubah tanpa restart!

---

## 🚀 Quick Reference

| Perubahan | Hot Reload (r) | Hot Restart (R) | Full Restart |
|-----------|----------------|-----------------|--------------|
| Text/String | ✅ | ✅ | ✅ |
| Colors | ✅ | ✅ | ✅ |
| Padding/Margin | ✅ | ✅ | ✅ |
| Add Widget | ✅ | ✅ | ✅ |
| Logic di build() | ✅ | ✅ | ✅ |
| initState() | ❌ | ✅ | ✅ |
| New Class | ❌ | ✅ | ✅ |
| New Import | ❌ | ✅ | ✅ |
| pubspec.yaml | ❌ | ❌ | ✅ |
| Add Assets | ❌ | ❌ | ✅ |
| Native Code | ❌ | ❌ | ✅ |

---

## ✅ Kesimpulan

**Untuk development cepat:**
1. Run sekali: `flutter run`
2. Edit kode di editor
3. Save (Ctrl+S)
4. Tekan `r` → Lihat hasil instantly!
5. Ulangi langkah 2-4

**90% waktu development Anda cukup pakai Hot Reload (r)!**

Selamat coding dengan efisien! 🚀
