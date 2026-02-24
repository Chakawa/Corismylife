# =====================================================
# TEST RAPIDE WAVE - Mode Polling Sans Webhooks
# =====================================================

param(
    [string]$Email = "",
    [string]$Password = "",
    [int]$Amount = 100,
    [int]$SubscriptionId = 1
)

$ErrorActionPreference = "Stop"

Write-Host "`n🌊 TEST RAPIDE WAVE CHECKOUT`n" -ForegroundColor Cyan

# =====================================================
# 1. OBTENIR LE TOKEN
# =====================================================
if ([string]::IsNullOrWhiteSpace($Email) -or [string]::IsNullOrWhiteSpace($Password)) {
    Write-Host "❌ Email et mot de passe requis" -ForegroundColor Red
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\test-wave-quick.ps1 -Email 'votre@email.com' -Password 'pass' -Amount 100`n" -ForegroundColor Gray
    exit 1
}

Write-Host "🔐 Connexion..." -ForegroundColor Yellow

try {
    $loginResponse = Invoke-RestMethod `
        -Uri "http://127.0.0.1:5000/api/auth/login" `
        -Method POST `
        -Body (@{email=$Email; password=$Password} | ConvertTo-Json) `
        -ContentType "application/json"
    
    $token = $loginResponse.token
    Write-Host "✅ Connecté: $($loginResponse.user.email)" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec connexion: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# =====================================================
# 2. CRÉER SESSION WAVE
# =====================================================
Write-Host "`n📝 Création session Wave..." -ForegroundColor Yellow

try {
    $createResponse = Invoke-RestMethod `
        -Uri "http://127.0.0.1:5000/api/payment/wave/create-session" `
        -Method POST `
        -Headers @{Authorization="Bearer $token"} `
        -Body (@{
            subscriptionId=$SubscriptionId
            amount=$Amount
            description="Test Wave - Polling Mode"
        } | ConvertTo-Json) `
        -ContentType "application/json"
    
    $sessionId = $createResponse.data.sessionId
    $launchUrl = $createResponse.data.launchUrl
    $transactionId = $createResponse.data.transactionId
    
    Write-Host "✅ Session créée" -ForegroundColor Green
    Write-Host "   Session ID: $sessionId" -ForegroundColor Gray
    Write-Host "   Transaction: $transactionId" -ForegroundColor Gray
    Write-Host "`n🔗 URL Wave:" -ForegroundColor Cyan
    Write-Host "   $launchUrl" -ForegroundColor White
} catch {
    Write-Host "❌ Échec: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# =====================================================
# 3. ATTENDRE CONFIRMATION
# =====================================================
Write-Host "`n📱 Ouvrez l'URL ci-dessus et complétez le paiement Wave" -ForegroundColor Yellow
Read-Host "`nAppuyez sur ENTRÉE après avoir payé"

# =====================================================
# 4. POLLING DU STATUT
# =====================================================
Write-Host "`n🔄 Vérification du statut (polling)..." -ForegroundColor Yellow

$maxAttempts = 10
$found = $false

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "   Tentative $i/$maxAttempts..." -ForegroundColor Gray
    
    try {
        $statusResponse = Invoke-RestMethod `
            -Uri "http://127.0.0.1:5000/api/payment/wave/status/$sessionId?subscriptionId=$SubscriptionId&transactionId=$transactionId" `
            -Method GET `
            -Headers @{Authorization="Bearer $token"}
        
        $status = $statusResponse.data.status
        $providerStatus = $statusResponse.data.providerStatus
        
        Write-Host "   Statut: $status | Provider: $providerStatus" -ForegroundColor Gray
        
        if ($status -eq "COMPLETED" -or $providerStatus -eq "complete") {
            Write-Host "`n🎉 PAIEMENT RÉUSSI !" -ForegroundColor Green
            Write-Host ($statusResponse | ConvertTo-Json -Depth 5)
            $found = $true
            break
        }
        
        if ($status -eq "FAILED" -or $providerStatus -in @("failed", "cancelled", "expired")) {
            Write-Host "`n❌ PAIEMENT ÉCHOUÉ: $status" -ForegroundColor Red
            Write-Host ($statusResponse | ConvertTo-Json -Depth 5)
            $found = $true
            break
        }
        
        if ($i -lt $maxAttempts) {
            Start-Sleep -Seconds 3
        }
    } catch {
        Write-Host "   ⚠️  Erreur: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($i -lt $maxAttempts) {
            Start-Sleep -Seconds 3
        }
    }
}

if (-not $found) {
    Write-Host "`n⏱️  Timeout - Paiement toujours en attente" -ForegroundColor Yellow
    Write-Host "Vérifiez manuellement avec:" -ForegroundColor Gray
    Write-Host "  Session ID: $sessionId" -ForegroundColor Gray
}

Write-Host "`n✅ Test terminé`n" -ForegroundColor Cyan
