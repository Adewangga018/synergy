# myITS Synergy - Color Palette Guide

## 🎨 Branding Colors

### 1. Warna Utama (Primary Color)
**Biru Tua ITS**
- **HEX:** `#013880`
- **RGB:** `1, 56, 128`
- **Flutter:** `Color(0xFF013880)`
- **Fungsi:** Warna utama branding myITS, digunakan untuk AppBar, tombol utama, dan elemen penting

### 2. Warna Pendukung (Secondary/Accent)
**Biru Muda ITS**
- **HEX:** `#0078C1`
- **Flutter:** `Color(0xFF0078C1)`
- **Fungsi:** Ikon fitur, teks pendukung, elemen interaktif yang lebih santai

### 3. Warna Netral (Background & Surface)

**Putih (Background)**
- **HEX:** `#FFFFFF`
- **Flutter:** `Color(0xFFFFFFFF)` atau `Colors.white`
- **Fungsi:** Latar belakang utama aplikasi

**Abu-abu Sangat Muda (Surface)**
- **HEX:** `#F4F4F4`
- **Flutter:** `Color(0xFFF4F4F4)`
- **Fungsi:** Latar belakang kartu/section untuk memberikan dimensi visual

**Teks Gelap**
- **HEX:** `#333333`
- **Flutter:** `Color(0xFF333333)`
- **Fungsi:** Warna teks untuk keterbacaan maksimal

---

## 📱 Implementasi

### Menggunakan AppColors Class
```dart
import 'package:synergy/constants/app_colors.dart';

// Primary color
Container(
  color: AppColors.primary,
)

// Secondary color
Icon(Icons.home, color: AppColors.secondary)

// Text color
Text(
  'Hello',
  style: TextStyle(color: AppColors.textDark),
)

// Gradient
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

### Theme Configuration (sudah diterapkan di main.dart)
```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF013880),
    primary: const Color(0xFF013880),
    secondary: const Color(0xFF0078C1),
    background: const Color(0xFFFFFFFF),
    surface: const Color(0xFFF4F4F4),
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  cardColor: const Color(0xFFF4F4F4),
)
```

---

## 🎯 Panduan Penggunaan Warna

### Primary Color (#013880)
✅ **Gunakan untuk:**
- AppBar background
- Button utama (Login, Register, Submit)
- Avatar background
- Elemen branding utama
- Icon menu penting

❌ **Jangan gunakan untuk:**
- Body text (terlalu gelap)
- Large background areas (terlalu monoton)

### Secondary Color (#0078C1)
✅ **Gunakan untuk:**
- Icon interaktif
- Link/TextButton
- Fitur menu sekunder
- Highlight elements
- Accent badges

❌ **Jangan gunakan untuk:**
- Primary CTA buttons
- Text paragraf

### Background (#FFFFFF)
✅ **Gunakan untuk:**
- Scaffold background
- Page background
- Modal/Dialog background

### Surface (#F4F4F4)
✅ **Gunakan untuk:**
- Card background
- Section background
- Input field disabled state
- Divider antara sections

### Text Dark (#333333)
✅ **Gunakan untuk:**
- Body text
- Headings
- Labels
- Input text
- Descriptions

---

## 🖼️ Contoh Implementasi

### Login Page
```dart
// Logo gradient fallback
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF013880), // Primary
        Color(0xFF0078C1), // Secondary
      ],
    ),
  ),
)

// Subtitle text
Text(
  'Masuk ke akun Anda',
  style: TextStyle(color: Color(0xFF333333)),
)

// Button (otomatis menggunakan theme primary)
ElevatedButton(
  onPressed: () {},
  child: Text('Masuk'),
)
```

### Home Page
```dart
// Avatar
CircleAvatar(
  backgroundColor: Color(0xFF013880),
  child: Text('A'),
)

// Profile icon
Icon(
  Icons.person,
  color: Color(0xFF0078C1),
)

// Menu cards
_buildMenuCard(
  icon: Icons.person,
  title: 'Edit Profil',
  color: Color(0xFF013880), // Primary
)

_buildMenuCard(
  icon: Icons.settings,
  title: 'Pengaturan',
  color: Color(0xFF0078C1), // Secondary
)
```

---

## ✨ Best Practices

1. **Konsistensi**
   - Selalu gunakan warna dari AppColors class
   - Jangan hard-code hex values di UI code

2. **Kontras**
   - Pastikan text readable (gunakan textDark #333333 di background terang)
   - Gunakan white text di atas primary/secondary colors

3. **Hierarchy**
   - Primary color untuk elemen paling penting
   - Secondary untuk supporting elements
   - Surface untuk separation

4. **Accessibility**
   - Pastikan contrast ratio minimal 4.5:1 untuk text
   - Primary (#013880) pada white memiliki excellent contrast ratio

---

## 🔄 Migration dari Warna Lama

Jika ada kode lama yang masih menggunakan warna generic:

### Before ❌
```dart
// Generic colors
Colors.blue
Colors.purple
Colors.grey[600]
Theme.of(context).primaryColor // (jika deepPurple)
```

### After ✅
```dart
// myITS branding colors
AppColors.primary
AppColors.secondary
AppColors.textDark
const Color(0xFF013880)
```

---

## 📊 Color Palette Visual

```
┌─────────────────────────────────────────────────────┐
│ Primary (#013880)        █████████ Biru Tua ITS    │
│ Secondary (#0078C1)      █████████ Biru Muda ITS   │
│ Background (#FFFFFF)     █████████ Putih           │
│ Surface (#F4F4F4)        █████████ Abu-abu Muda    │
│ Text Dark (#333333)      █████████ Teks Gelap      │
└─────────────────────────────────────────────────────┘
```

---

## 🎨 Status & Feedback Colors

Tambahan untuk status messages:

```dart
// Success
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Berhasil!'),
    backgroundColor: AppColors.success, // Green
  ),
)

// Error
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error!'),
    backgroundColor: AppColors.error, // Red
  ),
)
```

---

## 📝 Checklist Implementation

File-file yang sudah diupdate dengan color palette baru:

- ✅ `lib/main.dart` - Theme configuration
- ✅ `lib/pages/login_page.dart` - Login UI colors
- ✅ `lib/pages/register_page.dart` - Register UI colors
- ✅ `lib/pages/home_page.dart` - Home UI colors
- ✅ `lib/constants/app_colors.dart` - Color constants (NEW)

Untuk fitur baru, selalu gunakan:
1. `AppColors.primary` untuk warna utama
2. `AppColors.secondary` untuk aksen
3. `AppColors.textDark` untuk text
4. `AppColors.surface` untuk card backgrounds

---

Selamat coding dengan branding myITS! 🎓
