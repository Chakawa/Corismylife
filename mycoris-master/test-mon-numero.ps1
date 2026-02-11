# Script de test automatique avec votre numéro : 2250576097537
# Ce script démarre le serveur et lance le test

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "TEST AVEC VOTRE NUMERO: 2250576097537" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Étape 1: Vérifier le mode DEV
Write-Host "[1/3] Verification du mode DEV..." -ForegroundColor Yellow
$envContent = Get-Content .env -Raw
if ($envContent -match "CORIS_MONEY_DEV_MODE=true") {
    Write-Host "[OK] Mode DEV active (simulation)" -ForegroundColor Green
} else {
    Write-Host "[INFO] Activation du mode DEV..." -ForegroundColor Yellow
    $envContent = $envContent -replace "CORIS_MONEY_DEV_MODE=false", "CORIS_MONEY_DEV_MODE=true"
    Set-Content .env -Value $envContent
    Write-Host "[OK] Mode DEV active" -ForegroundColor Green
}

Write-Host ""

# Étape 2: Démarrer le serveur
Write-Host "[2/3] Demarrage du serveur..." -ForegroundColor Yellow
Write-Host ""

# Tuer les processus Node.js existants
taskkill /F /IM node.exe 2>$null | Out-Null
Start-Sleep -Seconds 1

# Démarrer le serveur en arrière-plan
$serverJob = Start-Job -ScriptBlock {
    Set-Location "d:\CORIS\app_coris\mycoris-master"
    node server.js
}

Write-Host "Attente du demarrage du serveur..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Vérifier si le serveur répond
try {
    $response = Invoke-WebRequest "http://localhost:5000/test-db" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    Write-Host "[OK] Serveur demarre sur http://localhost:5000" -ForegroundColor Green
} catch {
    Write-Host "[ATTENTION] Le serveur met du temps a demarrer..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
}

Write-Host ""

# Étape 3: Lancer le test
Write-Host "[3/3] Lancement du test..." -ForegroundColor Yellow
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

node test-mon-numero.js

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] Pour arreter le serveur:" -ForegroundColor Yellow
Write-Host "       taskkill /F /IM node.exe" -ForegroundColor White
Write-Host ""
Write-Host "[INFO] Pour remettre en mode PRODUCTION:" -ForegroundColor Yellow
Write-Host "       Editez .env et changez CORIS_MONEY_DEV_MODE=false" -ForegroundColor White
Write-Host ""
