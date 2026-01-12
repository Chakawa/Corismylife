#!/usr/bin/env pwsh
# Script de comparaison et fusion intelligente
# Compare les fichiers locaux avec GitHub et identifie les différences

Write-Host "=== ANALYSE COMPARATIVE COMPLÈTE ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$results = @()

# Configuration
$baseUrl = "https://raw.githubusercontent.com/Chakawa/Corismylife/85851f8a7248269bf215c7aee81e19a43867fa65"
$tempDir = "d:\CORIS\app_coris\github_temp_compare"

# Créer le dossier temporaire s'il n'existe pas
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Liste des fichiers critiques à vérifier
$filesToCheck = @(
    @{
        Name = "souscription_retraite.dart"
        Path = "mycorislife-master/lib/features/souscription/presentation/screens/souscription_retraite.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_retraite.dart"
        HasNewModifications = $true
        NewFeatures = @("capitalValues map avec 46 durées")
    },
    @{
        Name = "souscription_serenite.dart"
        Path = "mycorislife-master/lib/features/souscription/presentation/screens/souscription_serenite.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_serenite.dart"
        HasNewModifications = $false
    },
    @{
        Name = "souscription_etude.dart"
        Path = "mycorislife-master/lib/features/souscription/presentation/screens/souscription_etude.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_etude.dart"
        HasNewModifications = $false
    },
    @{
        Name = "souscription_familis.dart"
        Path = "mycorislife-master/lib/features/souscription/presentation/screens/souscription_familis.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\features\souscription\presentation\screens\souscription_familis.dart"
        HasNewModifications = $false
    },
    @{
        Name = "proposition_detail_page.dart"
        Path = "mycorislife-master/lib/features/client/presentation/screens/proposition_detail_page.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\features\client\presentation\screens\proposition_detail_page.dart"
        HasNewModifications = $false
    },
    @{
        Name = "subscription_service.dart"
        Path = "mycorislife-master/lib/services/subscription_service.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\services\subscription_service.dart"
        HasNewModifications = $false
    },
    @{
        Name = "questionnaire_medical_service.dart"
        Path = "mycorislife-master/lib/services/questionnaire_medical_service.dart"
        Local = "d:\CORIS\app_coris\mycorislife-master\lib\services\questionnaire_medical_service.dart"
        HasNewModifications = $false
    },
    @{
        Name = "subscriptionController.js"
        Path = "mycoris-master/controllers/subscriptionController.js"
        Local = "d:\CORIS\app_coris\mycoris-master\controllers\subscriptionController.js"
        HasNewModifications = $true
        NewFeatures = @("3 fonctions questionnaire médical avec BDD")
    },
    @{
        Name = "authController.js"
        Path = "mycoris-master/controllers/authController.js"
        Local = "d:\CORIS\app_coris\mycoris-master\controllers\authController.js"
        HasNewModifications = $false
    },
    @{
        Name = "subscriptionRoutes.js"
        Path = "mycoris-master/routes/subscriptionRoutes.js"
        Local = "d:\CORIS\app_coris\mycoris-master\routes\subscriptionRoutes.js"
        HasNewModifications = $false
    }
)

Write-Host "📊 Analyse de $($filesToCheck.Count) fichiers critiques..." -ForegroundColor Yellow
Write-Host ""

foreach ($file in $filesToCheck) {
    Write-Host "Analyse: $($file.Name)" -ForegroundColor Cyan
    
    $result = @{
        Name = $file.Name
        Status = "OK"
        LocalSize = 0
        GitHubSize = 0
        Difference = 0
        LocalExists = $false
        GitHubExists = $false
        HasNewModifications = $file.HasNewModifications
        NewFeatures = $file.NewFeatures
        Recommendation = ""
    }
    
    # Vérifier l'existence du fichier local
    if (Test-Path $file.Local) {
        $result.LocalExists = $true
        $result.LocalSize = (Get-Item $file.Local).Length
        Write-Host "  ✅ Local trouvé: $($result.LocalSize) bytes" -ForegroundColor Green
    } else {
        $result.Status = "MISSING_LOCAL"
        Write-Host "  ❌ Fichier local MANQUANT" -ForegroundColor Red
    }
    
    # Télécharger depuis GitHub pour comparer
    $githubUrl = "$baseUrl/$($file.Path)"
    $tempFile = Join-Path $tempDir $file.Name
    
    try {
        Invoke-WebRequest -Uri $githubUrl -OutFile $tempFile -ErrorAction Stop
        $result.GitHubExists = $true
        $result.GitHubSize = (Get-Item $tempFile).Length
        Write-Host "  ✅ GitHub: $($result.GitHubSize) bytes" -ForegroundColor Green
    } catch {
        $result.Status = "MISSING_GITHUB"
        Write-Host "  ⚠️ Impossible de télécharger depuis GitHub" -ForegroundColor Yellow
    }
    
    # Comparer les tailles
    if ($result.LocalExists -and $result.GitHubExists) {
        $result.Difference = $result.LocalSize - $result.GitHubSize
        
        if ($result.Difference -eq 0) {
            Write-Host "  ✅ Tailles identiques" -ForegroundColor Green
            $result.Recommendation = "Fichier identique, aucune action"
        } elseif ($result.Difference -gt 0) {
            Write-Host "  📈 Local plus grand de $($result.Difference) bytes" -ForegroundColor Cyan
            if ($file.HasNewModifications) {
                $result.Recommendation = "OK - Contient les nouvelles modifications: $($file.NewFeatures -join ', ')"
                Write-Host "    ✅ $($result.Recommendation)" -ForegroundColor Green
            } else {
                $result.Status = "INVESTIGATE"
                $result.Recommendation = "Vérifier pourquoi le local est plus grand"
                Write-Host "    ⚠️ $($result.Recommendation)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  📉 Local plus petit de $([Math]::Abs($result.Difference)) bytes" -ForegroundColor Yellow
            if ($file.HasNewModifications) {
                $result.Status = "MERGE_NEEDED"
                $result.Recommendation = "FUSION NECESSAIRE - Preserver: $($file.NewFeatures -join ', ')"
                Write-Host "    ⚠️ $($result.Recommendation)" -ForegroundColor Red
            } else {
                $result.Status = "RESTORE_RECOMMENDED"
                $result.Recommendation = "RESTAURATION recommandee depuis GitHub"
                Write-Host "    🔄 $($result.Recommendation)" -ForegroundColor Yellow
            }
        }
    }
    
    $results += $result
    Write-Host ""
}

# Résumé
Write-Host "=== RÉSUMÉ ===" -ForegroundColor Cyan
Write-Host ""

$okFiles = $results | Where-Object { $_.Status -eq "OK" }
$mergeFiles = $results | Where-Object { $_.Status -eq "MERGE_NEEDED" }
$restoreFiles = $results | Where-Object { $_.Status -eq "RESTORE_RECOMMENDED" }
$investigateFiles = $results | Where-Object { $_.Status -eq "INVESTIGATE" }
$missingFiles = $results | Where-Object { $_.Status -like "MISSING_*" }

Write-Host "✅ Fichiers OK: $($okFiles.Count)" -ForegroundColor Green
if ($okFiles.Count -gt 0) {
    $okFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
}
Write-Host ""

Write-Host "🔄 Fichiers nécessitant une FUSION: $($mergeFiles.Count)" -ForegroundColor Yellow
if ($mergeFiles.Count -gt 0) {
    $mergeFiles | ForEach-Object { 
        Write-Host "   - $($_.Name)" -ForegroundColor Red
        Write-Host "     Raison: $($_.Recommendation)" -ForegroundColor Gray
    }
}
Write-Host ""

Write-Host "📥 Fichiers à RESTAURER: $($restoreFiles.Count)" -ForegroundColor Cyan
if ($restoreFiles.Count -gt 0) {
    $restoreFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
}
Write-Host ""

if ($investigateFiles.Count -gt 0) {
    Write-Host "🔍 Fichiers à INVESTIGUER: $($investigateFiles.Count)" -ForegroundColor Magenta
    $investigateFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
    Write-Host ""
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Fichiers MANQUANTS: $($missingFiles.Count)" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "   - $($_.Name) ($($_.Status))" -ForegroundColor Gray }
    Write-Host ""
}

# Sauvegarder les résultats en JSON
$jsonPath = "d:\CORIS\app_coris\compare_results.json"
$results | ConvertTo-Json -Depth 10 | Out-File $jsonPath
Write-Host "📄 Résultats sauvegardés dans: $jsonPath" -ForegroundColor Green
Write-Host ""

Write-Host "=== FIN DE L'ANALYSE ===" -ForegroundColor Cyan
