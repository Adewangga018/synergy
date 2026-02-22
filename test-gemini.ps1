# Script untuk test Gemini API dan list models yang tersedia
# Ganti YOUR_API_KEY dengan API key Gemini kamu

$API_KEY = Read-Host "Masukkan Gemini API Key"

Write-Host "`n=== Testing Gemini API ===" -ForegroundColor Cyan
Write-Host "Fetching available models...`n" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://generativelanguage.googleapis.com/v1beta/models?key=$API_KEY" -Method Get
    
    Write-Host "Available Models:" -ForegroundColor Green
    foreach ($model in $response.models) {
        if ($model.supportedGenerationMethods -contains "generateContent") {
            Write-Host "  - $($model.name)" -ForegroundColor White
            Write-Host "    Display Name: $($model.displayName)" -ForegroundColor Gray
            Write-Host "    Description: $($model.description)" -ForegroundColor Gray
            Write-Host ""
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
