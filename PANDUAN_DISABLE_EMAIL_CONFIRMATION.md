# Cara Menonaktifkan Email Confirmation di Supabase
## Panduan Detail dengan Screenshot Path

### Langkah-Langkah:

#### 1. Login ke Supabase
- Buka browser: **https://app.supabase.com**
- Login dengan akun Anda

#### 2. Pilih Project
- Pilih project **Synergy** (atau project yang Anda gunakan)

#### 3. Navigasi ke Authentication Settings

**OPSI A - Lewat Providers (Paling Umum):**
```
Dashboard
  └─ Authentication (di sidebar kiri, icon shield/lock)
      └─ Providers (tab di atas, sejajar dengan Users, Policies)
          └─ Email (klik untuk expand)
              └─ CONFIRM EMAIL (toggle switch) ← MATIKAN INI
```

**OPSI B - Lewat Configuration:**
```
Dashboard
  └─ Authentication (di sidebar kiri)
      └─ Configuration (tab di atas)
          └─ Providers section
              └─ Email provider
                  └─ Confirm email (toggle) ← MATIKAN INI
```

**OPSI C - Lewat Settings:**
```
Dashboard
  └─ Project Settings (icon gear di sidebar paling bawah)
      └─ Authentication
          └─ Email Auth
              └─ Confirm email (toggle) ← MATIKAN INI
```

#### 4. Lokasi Pasti di Dashboard Terbaru (2024-2026):

Pilih di sidebar kiri:
1. **Authentication** (icon 🔐)
2. Di bagian atas halaman, pilih tab **"Configuration"** (bukan Providers atau Users)
3. Scroll ke bawah ke bagian **"Auth Providers"**
4. Cari provider **"Email"** dan klik untuk expand
5. Lihat opsi **"Confirm email"** atau **"Enable email confirmation"**
6. **Toggle OFF** (matikan)
7. Klik **"Save"** di bagian bawah

### Alternatif Jika Tidak Menemukan Toggle:

Jika Anda tidak menemukan toggle "Confirm email", coba cara ini:

#### Via SQL (Lebih Pasti):
1. Buka **SQL Editor** di sidebar
2. Jalankan query ini untuk cek setting saat ini:

```sql
-- Cek auth config
SELECT * FROM auth.config;
```

3. Untuk disable email confirmation secara manual via SQL:

```sql
-- Update auth config untuk disable email confirmation
-- Ini cara alternatif jika tidak ada toggle di UI
UPDATE auth.config 
SET value = 'false' 
WHERE key = 'MAILER_AUTOCONFIRM';
```

⚠️ **CATATAN PENTING**: Query SQL di atas mungkin tidak work karena `auth.config` adalah sistem internal Supabase. Lebih baik gunakan dashboard.

### Screenshot Visual Path (Teks):

```
┌─────────────────────────────────────────┐
│  SUPABASE DASHBOARD                     │
├─────────────────────────────────────────┤
│  [Logo]                                 │
│                                         │
│  ☰ Project: Synergy                     │
│  ─────────────────────────             │
│  📊 Home                                │
│  📝 Table Editor                        │
│  🔐 Authentication  ← KLIK INI          │
│     │                                   │
│     ├─ Users                            │
│     ├─ Policies                         │
│     └─ Configuration ← ATAU TAB INI     │
│  💾 Storage                             │
│  ...                                    │
│  ⚙️ Project Settings ← ATAU KLIK INI    │
│                                         │
└─────────────────────────────────────────┘
```

### Jika Masuk ke Configuration/Providers:

Anda akan melihat list seperti ini:
```
Auth Providers
├─ Email                    [Enabled ✓]
│  ├─ Enable sign ups       [ON]
│  ├─ Confirm email         [ON] ← MATIKAN INI JADI OFF
│  └─ ...
├─ Phone                    [Disabled]
├─ Google                   [Disabled]
└─ ...
```

### Tips Mencari:

1. **Gunakan Search/Find** (Ctrl+F di browser)
   - Cari kata: `confirm email`
   - Atau: `email confirmation`

2. **Cek Tab-Tab di Authentication**
   - Ada beberapa tab: Users, Policies, Configuration, Rate Limits, etc.
   - **Configuration** adalah yang paling sering punya setting ini

3. **Cek Versi Dashboard**
   - Supabase sering update UI
   - Jika tampilan berbeda, cari menu **"Providers"** atau **"Email Settings"**

### Jika Benar-Benar Tidak Ada:

Kemungkinan:
1. ✅ **Email confirmation sudah OFF** - Tidak perlu diubah lagi
2. ✅ **Setting ada di project level lain** - Cek project settings
3. ❌ **Role Anda tidak punya akses** - Pastikan Anda owner/admin project

### Test Apakah Email Confirmation Aktif:

Cara paling mudah untuk cek:
1. Coba register dengan email baru di app
2. Jika **LANGSUNG bisa login** tanpa harus cek email = Email confirmation OFF ✅
3. Jika muncul pesan "Check your email" = Email confirmation masih ON ❌

### Alternative Solution (Tanpa Disable Email Confirmation):

Jika tidak bisa menonaktifkan email confirmation, gunakan cara ini:

**1. Gunakan Email Asli Saat Testing**
- Daftar dengan email yang bisa Anda akses
- Check inbox dan klik link confirmation
- Setelah confirmed, baru bisa login

**2. Gunakan Mailtrap untuk Development**
- Setup Mailtrap.io (free)
- Integrate dengan Supabase SMTP
- Email confirmation akan masuk ke Mailtrap

**3. Skip Email Confirmation untuk User Tertentu (SQL)**
```sql
-- Manually confirm user setelah register
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'test@example.com';
```

---

### Kesimpulan:

**Lokasi paling mungkin:**
- **Authentication** → **Configuration** (tab) → **Auth Providers** → **Email** → **Confirm email** [Toggle OFF]

**Jika tidak ketemu:**
- Email confirmation mungkin sudah OFF
- Atau gunakan email asli untuk testing

Coba register sekali lagi di app. Jika rate limit error sudah hilang dan berhasil register, setting sudah benar!
