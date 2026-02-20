# Troubleshooting - Email Rate Limit Error

## Error: over_email_send_rate_limit

Jika Anda mengalami error berikut saat registrasi:
```
AuthApiException(message: For security purposes, you can only request this after 5 seconds., 
statusCode: 429, code: over_email_send_rate_limit)
```

### Penyebab
Supabase membatasi pengiriman email verifikasi untuk mencegah spam. Error ini terjadi jika:
- Mencoba registrasi beberapa kali dalam waktu singkat
- Email confirmation masih aktif di Supabase settings

### Solusi yang Sudah Diterapkan

✅ **Kode sudah diupdate** dengan:
1. Menonaktifkan email confirmation saat sign up
2. Error handling yang lebih baik
3. Pesan error yang lebih user-friendly

### Langkah Tambahan di Supabase Dashboard

Untuk development, sebaiknya matikan email confirmation:

1. **Buka Supabase Dashboard** → [https://app.supabase.com](https://app.supabase.com)

2. **Pilih Project** → `dswirqyxefvscpdobknb` (synergy)

3. **Authentication** → **Settings** (di sidebar kiri)

4. **Email Auth** section:
   - Uncheck/matikan **"Confirm email"**
   - Atau set **"Confirm email"** → **"No"**

5. **Save** perubahan

### Cara Testing

Setelah setting diubah:

```bash
flutter clean
flutter pub get
flutter run
```

Coba registrasi dengan data baru:
- Email: `test@example.com`
- NRP: `5026221001`
- Password: `password123`

### Untuk Production

⚠️ **PENTING**: Untuk production, sebaiknya:
- **Aktifkan kembali** email confirmation
- Tambahkan email template yang bagus
- Setup custom SMTP (opsional)
- Tambahkan reCAPTCHA

### Error Lain yang Mungkin Terjadi

| Error | Penyebab | Solusi |
|-------|----------|--------|
| `User already registered` | Email sudah dipakai | Gunakan email lain |
| `NRP sudah terdaftar` | NRP sudah dipakai | Gunakan NRP lain |
| `Email sudah terdaftar` | Email sudah di DB | Login atau reset password |

### Tunggu Sebelum Retry

Jika tetap error:
- Tunggu **60 detik** sebelum mencoba lagi
- Clear app data: `flutter clean`
- Restart app

### Contact Support

Jika masalah berlanjut, periksa:
- Supabase project status
- Internet connection
- API keys di `main.dart`

---

**Last Updated**: February 14, 2026
