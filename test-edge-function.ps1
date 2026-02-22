# ==========================================
# Test Script: Edge Function Generate Motivational Quotes
# ==========================================
# Script untuk test Edge Function generate-motivational-quotes
# termasuk test untuk tema Tugas Akhir (TA)
#
# Prerequisites:
# 1. Edge Function sudah di-deploy di Supabase
# 2. GEMINI_API_KEY sudah di-set di Edge Function Secrets
#
# Usage:
# .\test-edge-function.ps1

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Edge Function: Generate Motivational Quotes" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Input Supabase credentials
$SUPABASE_URL = Read-Host "Masukkan Supabase URL (contoh: https://xxxxx.supabase.co)"
$SUPABASE_ANON_KEY = Read-Host "Masukkan Supabase Anon Key"

$EDGE_FUNCTION_URL = "$SUPABASE_URL/functions/v1/generate-motivational-quotes"

Write-Host "`nEdge Function URL: $EDGE_FUNCTION_URL`n" -ForegroundColor Yellow

# Headers
$headers = @{
    "Authorization" = "Bearer $SUPABASE_ANON_KEY"
    "Content-Type" = "application/json"
}

# ==========================================
# Test 1: Generate Quote dengan Auto-Detect Theme
# ==========================================
Write-Host "`n--- Test 1: Auto-Detect Theme (General) ---" -ForegroundColor Green

$body1 = @{
    count = 2
} | ConvertTo-Json

try {
    Write-Host "Sending request..." -ForegroundColor Yellow
    $response1 = Invoke-RestMethod -Uri $EDGE_FUNCTION_URL -Method Post -Headers $headers -Body $body1
    
    Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Generated Count: $($response1.generated_count)" -ForegroundColor White
    Write-Host "Theme: $($response1.theme)" -ForegroundColor White
    Write-Host "Context: $($response1.context)" -ForegroundColor White
    Write-Host "`nQuotes Preview:" -ForegroundColor Cyan
    foreach ($quote in $response1.quotes_preview) {
        Write-Host "  📌 $quote" -ForegroundColor White
    }
} catch {
    Write-Host "`n❌ FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

# ==========================================
# Test 2: Generate Quote untuk Mahasiswa TA (Tugas Akhir)
# ==========================================
Write-Host "`n`n--- Test 2: Theme Tugas Akhir (TA) - Mahasiswa Semester 7-8 ---" -ForegroundColor Green

$body2 = @{
    count = 3
    theme = "tugas-akhir"
    context = "Mahasiswa tingkat akhir sedang mengerjakan Tugas Akhir (TA)"
} | ConvertTo-Json

try {
    Write-Host "Sending request for TA theme..." -ForegroundColor Yellow
    $response2 = Invoke-RestMethod -Uri $EDGE_FUNCTION_URL -Method Post -Headers $headers -Body $body2
    
    Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Generated Count: $($response2.generated_count)" -ForegroundColor White
    Write-Host "Theme: $($response2.theme)" -ForegroundColor White
    Write-Host "Context: $($response2.context)" -ForegroundColor White
    Write-Host "`nQuotes Preview (TA Theme):" -ForegroundColor Cyan
    foreach ($quote in $response2.quotes_preview) {
        Write-Host "  🎓 $quote" -ForegroundColor White
    }
} catch {
    Write-Host "`n❌ FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

# ==========================================
# Test 3: Generate Quote untuk UTS
# ==========================================
Write-Host "`n`n--- Test 3: Theme UTS (Ujian Tengah Semester) ---" -ForegroundColor Green

$body3 = @{
    count = 2
    theme = "UTS"
    context = "Persiapan Ujian Tengah Semester"
} | ConvertTo-Json

try {
    Write-Host "Sending request for UTS theme..." -ForegroundColor Yellow
    $response3 = Invoke-RestMethod -Uri $EDGE_FUNCTION_URL -Method Post -Headers $headers -Body $body3
    
    Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Generated Count: $($response3.generated_count)" -ForegroundColor White
    Write-Host "Theme: $($response3.theme)" -ForegroundColor White
    Write-Host "Context: $($response3.context)" -ForegroundColor White
    Write-Host "`nQuotes Preview (UTS Theme):" -ForegroundColor Cyan
    foreach ($quote in $response3.quotes_preview) {
        Write-Host "  📚 $quote" -ForegroundColor White
    }
} catch {
    Write-Host "`n❌ FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

# ==========================================
# Test 4: Generate Quote untuk UAS
# ==========================================
Write-Host "`n`n--- Test 4: Theme UAS (Ujian Akhir Semester) ---" -ForegroundColor Green

$body4 = @{
    count = 2
    theme = "UAS"
    context = "Persiapan Ujian Akhir Semester"
} | ConvertTo-Json

try {
    Write-Host "Sending request for UAS theme..." -ForegroundColor Yellow
    $response4 = Invoke-RestMethod -Uri $EDGE_FUNCTION_URL -Method Post -Headers $headers -Body $body4
    
    Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Generated Count: $($response4.generated_count)" -ForegroundColor White
    Write-Host "Theme: $($response4.theme)" -ForegroundColor White
    Write-Host "Context: $($response4.context)" -ForegroundColor White
    Write-Host "`nQuotes Preview (UAS Theme):" -ForegroundColor Cyan
    foreach ($quote in $response4.quotes_preview) {
        Write-Host "  📝 $quote" -ForegroundColor White
    }
} catch {
    Write-Host "`n❌ FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

# ==========================================
# Summary
# ==========================================
Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n✅ Jika semua test berhasil, Edge Function berjalan dengan baik!" -ForegroundColor Green
Write-Host "✅ Quotes untuk tema TA (Tugas Akhir) sudah tersedia" -ForegroundColor Green
Write-Host "✅ Auto-detect theme juga berfungsi normal" -ForegroundColor Green

Write-Host "`n📌 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check database 'motivational_quotes' untuk melihat quotes yang tersimpan" -ForegroundColor White
Write-Host "2. Test di aplikasi Flutter dengan user semester 7-8" -ForegroundColor White
Write-Host "3. Verify bahwa quotes TA muncul untuk mahasiswa tingkat akhir" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan
