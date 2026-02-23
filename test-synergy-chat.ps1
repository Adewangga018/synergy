# ===================================
# Test Script untuk Gemini Chat Edge Function
# ===================================

Write-Host "`n🤖 SYNERGY AI CHATBOT - TEST SCRIPT`n" -ForegroundColor Cyan

# ===================================
# CONFIGURATION
# ===================================

$SUPABASE_URL = Read-Host "Masukkan Supabase URL (https://xxx.supabase.co)"
$ANON_KEY = Read-Host "Masukkan Supabase Anon Key"

Write-Host "`n✅ Configuration loaded" -ForegroundColor Green

# ===================================
# TEST 1: Simple Chat (No Context)
# ===================================

Write-Host "`n=== TEST 1: Simple Chat (No Context, No Auth) ===" -ForegroundColor Yellow
Write-Host "Sending message: 'Halo! Perkenalkan dirimu'`n" -ForegroundColor Gray
Write-Host "Note: Test ini TIDAK memerlukan authentication karena include_context = false`n" -ForegroundColor Cyan

try {
    $headers = @{
        "Content-Type" = "application/json"
    }

    $body = @{
        message = "Halo! Perkenalkan dirimu sebagai AI assistant untuk myITS Synergy"
        include_context = $false
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/gemini-chat" `
        -Method Post `
        -Headers $headers `
        -Body $body

    if ($response.success) {
        Write-Host "✅ TEST 1 PASSED" -ForegroundColor Green
        Write-Host "AI Response:" -ForegroundColor Cyan
        Write-Host $response.response -ForegroundColor White
    } else {
        Write-Host "❌ TEST 1 FAILED" -ForegroundColor Red
        Write-Host "Error: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ TEST 1 FAILED (Exception)" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# ===================================
# TEST 2: Context-Aware Chat
# ===================================

Write-Host "`n=== TEST 2: Context-Aware Chat ===" -ForegroundColor Yellow
Write-Host "Sending message: 'Jadwal kuliah aku minggu ini apa aja?'`n" -ForegroundColor Gray

try {
    $body2 = @{
        message = "Jadwal kuliah aku minggu ini apa aja?"
        include_context = $true
    } | ConvertTo-Json

    $response2 = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/gemini-chat" `
        -Method Post `
        -Headers $headers `
        -Body $body2

    if ($response2.success) {
        Write-Host "✅ TEST 2 PASSED" -ForegroundColor Green
        Write-Host "AI Response:" -ForegroundColor Cyan
        Write-Host $response2.response -ForegroundColor White
        Write-Host "`nContext Used: $($response2.context_used)" -ForegroundColor Gray
    } else {
        Write-Host "❌ TEST 2 FAILED" -ForegroundColor Red
        Write-Host "Error: $($response2.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ TEST 2 FAILED (Exception)" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===================================
# TEST 3: Conversation History
# ===================================

Write-Host "`n=== TEST 3: Conversation with History ===" -ForegroundColor Yellow
Write-Host "Sending message with conversation history`n" -ForegroundColor Gray

try {
    $body3 = @{
        message = "Aku punya lomba hari Jumat, tapi ada kuis juga. Gimana menurutmu?"
        include_context = $true
        conversation_history = @(
            @{
                role = "user"
                content = "Halo AI!"
            },
            @{
                role = "assistant"
                content = "Halo! Ada yang bisa aku bantu?"
            }
        )
    } | ConvertTo-Json -Depth 10

    $response3 = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/gemini-chat" `
        -Method Post `
        -Headers $headers `
        -Body $body3

    if ($response3.success) {
        Write-Host "✅ TEST 3 PASSED" -ForegroundColor Green
        Write-Host "AI Response:" -ForegroundColor Cyan
        Write-Host $response3.response -ForegroundColor White
    } else {
        Write-Host "❌ TEST 3 FAILED" -ForegroundColor Red
        Write-Host "Error: $($response3.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ TEST 3 FAILED (Exception)" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===================================
# TEST 4: Workload Analysis
# ===================================

Write-Host "`n=== TEST 4: Workload Analysis ===" -ForegroundColor Yellow
Write-Host "Sending message: 'Minggu depan jadwalku seberapa padat?'`n" -ForegroundColor Gray

try {
    $body4 = @{
        message = "Cak, minggu depan jadwalku seberapa padat? Kasih analisis dong"
        include_context = $true
    } | ConvertTo-Json

    $response4 = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/gemini-chat" `
        -Method Post `
        -Headers $headers `
        -Body $body4

    if ($response4.success) {
        Write-Host "✅ TEST 4 PASSED" -ForegroundColor Green
        Write-Host "AI Response:" -ForegroundColor Cyan
        Write-Host $response4.response -ForegroundColor White
    } else {
        Write-Host "❌ TEST 4 FAILED" -ForegroundColor Red
        Write-Host "Error: $($response4.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ TEST 4 FAILED (Exception)" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===================================
# SUMMARY
# ===================================

Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Check the results above to verify all tests passed" -ForegroundColor White
Write-Host "`nIf all tests passed (✅), your Gemini Chat is working correctly!" -ForegroundColor Green
Write-Host "If any test failed (❌), check the error messages and troubleshooting guide.`n" -ForegroundColor Yellow

# ===================================
# TROUBLESHOOTING TIPS
# ===================================

Write-Host "Common issues:" -ForegroundColor Yellow
Write-Host "1. GEMINI_API_KEY not found → Set secret in Supabase Dashboard" -ForegroundColor Gray
Write-Host "2. Invalid authentication → Check Anon Key is correct" -ForegroundColor Gray
Write-Host "3. Function not found → Wait 1-2 minutes after deployment" -ForegroundColor Gray
Write-Host "4. Network error → Check Supabase URL is correct`n" -ForegroundColor Gray

Write-Host "📚 For more help, see: QUICKSTART_AI_CHATBOT.md`n" -ForegroundColor Cyan
