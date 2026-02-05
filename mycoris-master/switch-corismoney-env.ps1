# Script PowerShell pour basculer entre Testbed et Production CorisMoney
# Usage: .\switch-corismoney-env.ps1 -Mode production
#    ou: .\switch-corismoney-env.ps1 -Mode testbed

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("testbed", "production")]
    [string]$Mode
)

$envFile = "D:\CORIS\app_coris\mycoris-master\.env"
$backupDir = "D:\CORIS\app_coris\mycoris-master\.env.backups"

# Créer le dossier de backup s'il n'existe pas
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 Basculement CorisMoney: $Mode" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Sauvegarder l'environnement actuel
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir ".env.$timestamp"
Copy-Item $envFile $backupFile
Write-Host "✅ Sauvegarde créée: $backupFile" -ForegroundColor Green
Write-Host ""

if ($Mode -eq "production") {
    Write-Host "⚠️  PASSAGE EN PRODUCTION CORISMONEY ⚠️" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ATTENTION: Les paiements seront RÉELS !" -ForegroundColor Red
    Write-Host ""
    Write-Host "Assurez-vous d'avoir:" -ForegroundColor Yellow
    Write-Host "  1. L'URL de l'API production CorisMoney" -ForegroundColor Yellow
    Write-Host "  2. Le Client ID production" -ForegroundColor Yellow
    Write-Host "  3. Le Client Secret production" -ForegroundColor Yellow
    Write-Host "  4. Le Code PV production" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Continuer? (oui/non)"
    
    if ($confirm -ne "oui") {
        Write-Host "❌ Annulé" -ForegroundColor Red
        exit
    }
    
    Write-Host ""
    Write-Host "📝 Configuration Production CorisMoney" -ForegroundColor Cyan
    Write-Host ""
    
    $apiUrl = Read-Host "URL API Production (ex: https://api.corismoney.com/external/v1/api)"
    $clientId = Read-Host "Client ID Production"
    $clientSecret = Read-Host "Client Secret Production"
    $codePv = Read-Host "Code PV Production"
    
    # Lire le fichier .env
    $envContent = Get-Content $envFile
    
    # Remplacer les lignes CorisMoney
    $newContent = $envContent | ForEach-Object {
        if ($_ -match "^CORIS_MONEY_BASE_URL=") {
            "CORIS_MONEY_BASE_URL=$apiUrl"
        }
        elseif ($_ -match "^CORIS_MONEY_CLIENT_ID=") {
            "CORIS_MONEY_CLIENT_ID=$clientId"
        }
        elseif ($_ -match "^CORIS_MONEY_CLIENT_SECRET=") {
            "CORIS_MONEY_CLIENT_SECRET=$clientSecret"
        }
        elseif ($_ -match "^CORIS_MONEY_CODE_PV=") {
            "CORIS_MONEY_CODE_PV=$codePv"
        }
        elseif ($_ -match "^NODE_ENV=") {
            "NODE_ENV=production"
        }
        else {
            $_
        }
    }
    
    # Sauvegarder
    $newContent | Set-Content $envFile
    
    Write-Host ""
    Write-Host "✅ Configuration PRODUCTION activée" -ForegroundColor Green
    Write-Host "   URL: $apiUrl" -ForegroundColor White
    Write-Host "   Client ID: $clientId" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  RAPPEL: PAIEMENTS RÉELS ACTIVÉS !" -ForegroundColor Red
    
} else {
    # Mode Testbed
    Write-Host "🧪 Retour au mode TESTBED" -ForegroundColor Cyan
    Write-Host ""
    
    # Lire le fichier .env
    $envContent = Get-Content $envFile
    
    # Remplacer les lignes CorisMoney avec les valeurs testbed
    $newContent = $envContent | ForEach-Object {
        if ($_ -match "^CORIS_MONEY_BASE_URL=") {
            "CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api"
        }
        elseif ($_ -match "^CORIS_MONEY_CLIENT_ID=") {
            "CORIS_MONEY_CLIENT_ID=MYCORISLIFETEST"
        }
        elseif ($_ -match "^CORIS_MONEY_CLIENT_SECRET=") {
            "CORIS_MONEY_CLIENT_SECRET=`$2a`$10`$H.lf9RrqqWpCISE.LK78gucwG8N87dyW8dkkPoJ9mUZ5E9botCEwa"
        }
        elseif ($_ -match "^CORIS_MONEY_CODE_PV=") {
            "CORIS_MONEY_CODE_PV=0280315524"
        }
        elseif ($_ -match "^NODE_ENV=") {
            "NODE_ENV=development"
        }
        else {
            $_
        }
    }
    
    # Sauvegarder
    $newContent | Set-Content $envFile
    
    Write-Host "✅ Configuration TESTBED activée" -ForegroundColor Green
    Write-Host "   URL: https://testbed.corismoney.com/external/v1/api" -ForegroundColor White
    Write-Host "   Client ID: MYCORISLIFETEST" -ForegroundColor White
    Write-Host ""
    Write-Host "ℹ️  Les paiements sont en mode test" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔄 Redémarrage du serveur..." -ForegroundColor Cyan

# Arrêter Node.js si en cours
$nodeProcess = Get-Process -Name node -ErrorAction SilentlyContinue
if ($nodeProcess) {
    Write-Host "⏸️  Arrêt du serveur en cours..." -ForegroundColor Yellow
    Stop-Process -Name node -Force
    Start-Sleep -Seconds 2
    Write-Host "✅ Serveur arrêté" -ForegroundColor Green
}

# Démarrer le serveur
Write-Host ""
Write-Host "🚀 Démarrage du serveur..." -ForegroundColor Cyan
Write-Host ""
Set-Location "D:\CORIS\app_coris\mycoris-master"
Start-Process -NoNewWindow -FilePath "npm" -ArgumentList "start"

Start-Sleep -Seconds 3

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Basculement terminé !" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq "production") {
    Write-Host "📌 Prochaines étapes recommandées:" -ForegroundColor Yellow
    Write-Host "   1. Vérifier les logs du serveur" -ForegroundColor White
    Write-Host "   2. Tester avec: node test-account-check.js" -ForegroundColor White
    Write-Host "   3. Effectuer un paiement TEST avec 100 FCFA" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  N'OUBLIEZ PAS: Les paiements sont RÉELS !" -ForegroundColor Red
} else {
    Write-Host "📌 Mode testbed activé" -ForegroundColor Cyan
    Write-Host "   Les paiements sont simulés" -ForegroundColor White
}

Write-Host ""
Write-Host "📁 Backup disponible: $backupFile" -ForegroundColor Gray
Write-Host ""
