# ===================================
# Test Gemini Chat Edge Function (Direct API Call)
# ===================================

Write-Host "`n🧪 TESTING GEMINI CHAT EDGE FUNCTION`n" -ForegroundColor Cyan

# GANTI DENGAN DATA SUPABASE ANDA
$SUPABASE_URL = Read-Host "Enter your Supabase URL (e.g., https://xxx.supabase.co)"
$SUPABASE_ANON_KEY = Read-Host "Enter your Supabase Anon Key"

# Test request
$body = @{
    message = "Halo! Test chat"
    include_context = $false
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
    "apikey" = $SUPABASE_ANON_KEY
}

$url = "$SUPABASE_URL/functions/v1/gemini-chat"

Write-Host "📡 Calling: $url" -ForegroundColor Yellow
Write-Host "📦 Body: $body`n" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body -ErrorAction Stop
    
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 5
    
} catch {
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    Write-Host "Error Message:" -ForegroundColor Yellow
    $_.Exception.Message
    
    if ($_.ErrorDetails.Message) {
        Write-Host "`nError Details:" -ForegroundColor Yellow
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5
    }
}

Write-Host "`n" -ForegroundColor White
