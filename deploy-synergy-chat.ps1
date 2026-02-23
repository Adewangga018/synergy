# ===================================
# Deploy Script untuk Gemini Chat Edge Function
# ===================================

Write-Host "`n🚀 DEPLOY GEMINI CHAT EDGE FUNCTION`n" -ForegroundColor Cyan

# ===================================
# CHECK PREREQUISITES
# ===================================

Write-Host "Checking prerequisites...`n" -ForegroundColor Yellow

# Check if Supabase CLI is installed
try {
    $supabaseVersion = supabase --version 2>$null
    Write-Host "✅ Supabase CLI installed: $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI not found" -ForegroundColor Red
    Write-Host "`nInstall Supabase CLI:" -ForegroundColor Yellow
    Write-Host "  scoop install supabase" -ForegroundColor White
    Write-Host "  OR" -ForegroundColor Gray
    Write-Host "  npm install -g supabase" -ForegroundColor White
    exit 1
}

# ===================================
# LOGIN & LINK PROJECT
# ===================================

Write-Host "`n=== Step 1: Login to Supabase ===" -ForegroundColor Cyan

$loginChoice = Read-Host "Are you already logged in to Supabase CLI? (y/n)"

if ($loginChoice -ne 'y') {
    Write-Host "Logging in to Supabase..." -ForegroundColor Yellow
    supabase login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Login failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Login successful" -ForegroundColor Green
} else {
    Write-Host "✅ Already logged in" -ForegroundColor Green
}

# ===================================
# LINK PROJECT
# ===================================

Write-Host "`n=== Step 2: Link Project ===" -ForegroundColor Cyan

$linkChoice = Read-Host "Is your project already linked? (y/n)"

if ($linkChoice -ne 'y') {
    $projectRef = Read-Host "Enter your Supabase project reference ID"
    
    Write-Host "Linking project..." -ForegroundColor Yellow
    supabase link --project-ref $projectRef
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Project linking failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Project linked successfully" -ForegroundColor Green
} else {
    Write-Host "✅ Project already linked" -ForegroundColor Green
}

# ===================================
# SET GEMINI API KEY
# ===================================

Write-Host "`n=== Step 3: Set Gemini API Key ===" -ForegroundColor Cyan

$apiKeyChoice = Read-Host "Have you set GEMINI_API_KEY secret? (y/n)"

if ($apiKeyChoice -ne 'y') {
    Write-Host "`nGet FREE Gemini API Key:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://aistudio.google.com/app/apikey" -ForegroundColor White
    Write-Host "  2. Click 'Get API Key'" -ForegroundColor White
    Write-Host "  3. Copy the key (starts with AIza...)`n" -ForegroundColor White
    
    $geminiKey = Read-Host "Enter your Gemini API Key"
    
    Write-Host "Setting secret..." -ForegroundColor Yellow
    supabase secrets set GEMINI_API_KEY=$geminiKey
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to set secret" -ForegroundColor Red
        Write-Host "You can set it manually in Supabase Dashboard:" -ForegroundColor Yellow
        Write-Host "  Settings → Edge Functions → Manage secrets" -ForegroundColor Gray
    } else {
        Write-Host "✅ GEMINI_API_KEY secret set successfully" -ForegroundColor Green
    }
} else {
    Write-Host "✅ GEMINI_API_KEY already set" -ForegroundColor Green
}

# ===================================
# DEPLOY EDGE FUNCTION
# ===================================

Write-Host "`n=== Step 4: Deploy Edge Function ===" -ForegroundColor Cyan

Write-Host "Deploying gemini-chat function..." -ForegroundColor Yellow

supabase functions deploy gemini-chat --no-verify-jwt

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if supabase/functions/gemini-chat/index.ts exists" -ForegroundColor Gray
    Write-Host "  2. Verify your project is linked correctly" -ForegroundColor Gray
    Write-Host "  3. Check Supabase Dashboard for errors" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Edge function deployed successfully!" -ForegroundColor Green

# ===================================
# LIST FUNCTIONS
# ===================================

Write-Host "`n=== Verifying Deployment ===" -ForegroundColor Cyan
Write-Host "Listing all edge functions...`n" -ForegroundColor Yellow

supabase functions list

# ===================================
# SUCCESS MESSAGE
# ===================================

Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ DEPLOYMENT SUCCESSFUL!            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test the function:" -ForegroundColor White
Write-Host "     .\test-synergy-chat.ps1" -ForegroundColor Gray
Write-Host "`n  2. Run the Flutter app:" -ForegroundColor White
Write-Host "     flutter run" -ForegroundColor Gray
Write-Host "`n  3. Click the AI FAB button (🤖) on home page" -ForegroundColor White
Write-Host "     and start chatting!`n" -ForegroundColor Gray

Write-Host "📚 Documentation: QUICKSTART_AI_CHATBOT.md`n" -ForegroundColor Cyan
