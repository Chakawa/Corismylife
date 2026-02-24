# =====================================================
# SCRIPT INTERACTIF - TEST WAVE CHECKOUT
# =====================================================
# Ce script vous guide pas a pas pour tester Wave
# SANS webhooks (mode polling uniquement).
# =====================================================

Write-Host "`n" -NoNewline
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   TEST WAVE CHECKOUT - MODE POLLING" -ForegroundColor Cyan
Write-Host "   Configuration Interactive" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================
# ETAPE 1 : Obtenir un JWT Token
# =====================================================
Write-Host "ETAPE 1 : Obtention du JWT Token" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour tester l'API, vous avez besoin d'un JWT token valide." -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Voulez-vous vous connecter maintenant? (o/n)"

if ($choice -eq "o") {
    $email = Read-Host "Email"
    $password = Read-Host "Mot de passe" -AsSecureString
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )

    Write-Host "`nConnexion en cours..." -ForegroundColor Cyan

    try {
        $loginBody = @{
            email = $email
            password = $passwordPlain
        } | ConvertTo-Json

        $response = Invoke-RestMethod `
            -Uri "http://127.0.0.1:5000/api/auth/login" `
            -Method POST `
            -Body $loginBody `
            -ContentType "application/json"

        $token = $response.token

        if ($token) {
            Write-Host "OK Connexion reussie !" -ForegroundColor Green
            Write-Host "Token obtenu: $($token.Substring(0, 20))..." -ForegroundColor Gray
        } else {
            Write-Host "ERREUR : token non recu" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "ERREUR de connexion" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    $token = Read-Host "Entrez votre JWT token"
}

# =====================================================
# ETAPE 2 : Configuration du test
# =====================================================
Write-Host "`nETAPE 2 : Configuration du test" -ForegroundColor Yellow
Write-Host ""

$subscriptionId = Read-Host "ID de souscription (defaut: 1)"
if ([string]::IsNullOrWhiteSpace($subscriptionId)) { $subscriptionId = 1 }

$amount = Read-Host "Montant en FCFA (defaut: 100)"
if ([string]::IsNullOrWhiteSpace($amount)) { $amount = 100 }

$description = Read-Host "Description (defaut: Test paiement Wave)"
if ([string]::IsNullOrWhiteSpace($description)) { 
    $description = "Test paiement Wave - Mode Polling" 
}

# =====================================================
# ETAPE 3 : Sauvegarder le token dans .env
# =====================================================
Write-Host "`nETAPE 3 : Sauvegarde du token" -ForegroundColor Yellow

$envPath = ".env"
$envContent = Get-Content $envPath -Raw

# Ajouter ou mettre a jour TEST_JWT_TOKEN
if ($envContent -match "TEST_JWT_TOKEN=") {
    $envContent = $envContent -replace "TEST_JWT_TOKEN=.*", "TEST_JWT_TOKEN=$token"
} else {
    $envContent += "`nTEST_JWT_TOKEN=$token"
}

Set-Content -Path $envPath -Value $envContent -NoNewline
Write-Host "OK Token sauvegarde dans .env" -ForegroundColor Green

# =====================================================
# ETAPE 4 : Verifier le serveur
# =====================================================
Write-Host "`nETAPE 4 : Verification du serveur" -ForegroundColor Yellow

try {
    $serverCheck = Invoke-RestMethod `
        -Uri "http://127.0.0.1:5000/test-db" `
        -Method GET `
        -TimeoutSec 5

    Write-Host "OK Serveur actif" -ForegroundColor Green
} catch {
    Write-Host "ERREUR Serveur inaccessible" -ForegroundColor Red
    Write-Host ""
    Write-Host "Lancez le serveur avec:" -ForegroundColor Yellow
    Write-Host "  npm start" -ForegroundColor Cyan
    Write-Host ""
    $startServer = Read-Host "Demarrer le serveur maintenant? (o/n)"
    
    if ($startServer -eq "o") {
        Write-Host "Demarrage du serveur..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start"
        Start-Sleep -Seconds 5
    } else {
        exit 1
    }
}

# =====================================================
# ETAPE 5 : Lancer le test
# =====================================================
Write-Host "`nETAPE 5 : Lancement du test" -ForegroundColor Yellow
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Gray
Write-Host "  - Subscription ID: $subscriptionId" -ForegroundColor Gray
Write-Host "  - Montant: $amount FCFA" -ForegroundColor Gray
Write-Host "  - Description: $description" -ForegroundColor Gray
Write-Host "  - Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Lancer le test? (o/n)"

if ($confirm -eq "o") {
    Write-Host "`n====================================================" -ForegroundColor Cyan
    Write-Host "LANCEMENT DU TEST WAVE" -ForegroundColor Cyan
    Write-Host "====================================================`n" -ForegroundColor Cyan
    
    node test-wave-polling.js
} else {
    Write-Host "`nTest annule" -ForegroundColor Yellow
}

Write-Host "`nScript termine" -ForegroundColor Green

