# Assets - myITS Synergy Logo

## Logo Instructions

Untuk menampilkan logo myITS Synergy di halaman login, silakan tambahkan file logo dengan nama:

**`myits_synergy_logo.png`**

### Lokasi File
Letakkan file logo di folder:
```
assets/images/myits_synergy_logo.png
```

### Spesifikasi Logo Rekomendasi
- **Format**: PNG (dengan background transparan)
- **Ukuran**: 512x512 px atau 1024x1024 px
- **Ratio**: 1:1 (persegi)
- **File size**: < 500KB

### Alternatif Format
Anda juga bisa menggunakan format lain:
- JPG/JPEG (untuk background solid)
- SVG (vector, perlu package flutter_svg)

### Fallback
Jika logo belum ditambahkan, aplikasi akan menampilkan icon placeholder dengan:
- Gradient background
- Icon school
- Text "myITS"

### Cara Menambahkan Logo

1. Siapkan file logo myITS Synergy
2. Rename menjadi `myits_synergy_logo.png`
3. Copy ke folder `assets/images/`
4. Jalankan `flutter clean` dan `flutter run`

### Contoh Struktur Folder
```
synergy/
├── assets/
│   └── images/
│       └── myits_synergy_logo.png  ← Letakkan logo di sini
├── lib/
└── pubspec.yaml
```

---

**Note**: Logo sudah dikonfigurasi di `pubspec.yaml` dan akan otomatis dimuat saat aplikasi dijalankan.
