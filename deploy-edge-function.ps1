# Script untuk deploy Edge Function generate-motivational-quotes
# Menggunakan npx karena Supabase CLI tidak support npm global install

Write-Host "=== Deploy Supabase Edge Function ===" -ForegroundColor Cyan
Write-Host "Function: generate-motivational-quotes`n" -ForegroundColor White

# Check apakah sudah login
Write-Host "Checking Supabase login status..." -ForegroundColor Yellow
$loginCheck = npx supabase@latest projects list 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in. Opening browser for authentication..." -ForegroundColor Yellow
    Write-Host "⚠️  Browser akan terbuka. Login dengan akun Supabase Anda.`n" -ForegroundColor Cyan
    
    # Login akan membuka browser
    npx supabase@latest login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n✗ Login gagal!" -ForegroundColor Red
        Write-Host "Solusi alternatif: Deploy via Supabase Dashboard" -ForegroundColor Yellow
        Write-Host "Baca: DEPLOYMENT_EDGE_FUNCTION.md untuk panduan lengkap`n" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host "✓ Logged in successfully`n" -ForegroundColor Green

# Link ke project (optional, skip jika sudah linked)
Write-Host "Linking to Supabase project..." -ForegroundColor Yellow
Write-Host "ℹ️  Jika sudah pernah link, step ini akan di-skip`n" -ForegroundColor Gray

# Check apakah sudah ada .supabase folder
if (-Not (Test-Path ".supabase")) {
    Write-Host "⚠️  Project belum di-link. Silakan jalankan:" -ForegroundColor Yellow
    Write-Host "npx supabase@latest link --project-ref YOUR_PROJECT_REF`n" -ForegroundColor Cyan
    Write-Host "Project Ref bisa dilihat di:" -ForegroundColor Yellow
    Write-Host "https://supabase.com/dashboard → Settings → General → Reference ID`n" -ForegroundColor White
    
    $continue = Read-Host "Lanjutkan deploy tanpa link? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
}

# Deploy Edge Function
Write-Host "`nDeploying generate-motivational-quotes function..." -ForegroundColor Yellow
Write-Host "⏳ Proses ini mungkin memakan waktu 30-60 detik...`n" -ForegroundColor Gray

npx supabase@latest functions deploy generate-motivational-quotes --no-verify-jwt

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Edge Function deployed successfully!" -ForegroundColor Green
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    Write-Host "1️⃣  Set OpenAI API Key di Supabase:" -ForegroundColor Yellow
    Write-Host "   Dashboard → Settings → Edge Functions → Manage Secrets" -ForegroundColor White
    Write-Host "   Name: OPENAI_API_KEY" -ForegroundColor Gray
    Write-Host "   Value: sk-proj-xxxxxxxxxxxx`n" -ForegroundColor Gray
    
    Write-Host "2️⃣  Test function di Dashboard:" -ForegroundColor Yellow
    Write-Host "   Dashboard → Edge Functions → generate-motivational-quotes → Invoke`n" -ForegroundColor White
    
    Write-Host "3️⃣  Lihat logs:" -ForegroundColor Yellow
    Write-Host "   npx supabase@latest functions logs generate-motivational-quotes`n" -ForegroundColor White
    
    Write-Host "📖 Panduan lengkap: DEPLOYMENT_EDGE_FUNCTION.md`n" -ForegroundColor Cyan
} else {
    Write-Host "`n✗ Deployment failed!" -ForegroundColor Red
    Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "- Check koneksi internet" -ForegroundColor White
    Write-Host "- Pastikan sudah login: npx supabase@latest login" -ForegroundColor White
    Write-Host "- Pastikan sudah link: npx supabase@latest link --project-ref YOUR_REF" -ForegroundColor White
    Write-Host "`n📖 Atau deploy via Dashboard (lebih mudah):" -ForegroundColor Cyan
    Write-Host "   Baca: DEPLOYMENT_EDGE_FUNCTION.md`n" -ForegroundColor White
}
