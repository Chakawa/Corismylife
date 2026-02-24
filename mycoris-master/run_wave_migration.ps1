# Migration Wave - Correction Base de Donnees
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION WAVE - CORRECTION BASE DE DONNEES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Charger les variables d'environnement depuis .env
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    Write-Host "Fichier .env charge" -ForegroundColor Green
} else {
    Write-Host "Fichier .env introuvable !" -ForegroundColor Red
    exit 1
}

# Recuperer les variables necessaires
if ($env:DATABASE_URL) {
    # Parser DATABASE_URL: postgresql://user:password@host:port/dbname
    if ($env:DATABASE_URL -match 'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)') {
        $DB_USER = $matches[1]
        $DB_PASSWORD = $matches[2]
        $DB_HOST = $matches[3]
        $DB_PORT = $matches[4]
        $DB_NAME = $matches[5]
    } else {
        Write-Host "Format DATABASE_URL invalide" -ForegroundColor Red
        exit 1
    }
} else {
    # Fallback vers variables individuelles
    $DB_USER = $env:DB_USER
    $DB_PASSWORD = $env:DB_PASSWORD
    $DB_HOST = $env:DB_HOST
    $DB_PORT = $env:DB_PORT
    $DB_NAME = $env:DB_NAME
}

if (-not $DB_USER -or -not $DB_PASSWORD -or -not $DB_HOST -or -not $DB_NAME) {
    Write-Host "Variables de base de donnees manquantes dans .env" -ForegroundColor Red
    Write-Host "Verifiez: DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME" -ForegroundColor Yellow
    exit 1
}

Write-Host "Configuration de la base de donnees:" -ForegroundColor Yellow
Write-Host "   - Hote     : $DB_HOST" -ForegroundColor White
Write-Host "   - Port     : $DB_PORT" -ForegroundColor White
Write-Host "   - Base     : $DB_NAME" -ForegroundColor White
Write-Host "   - Utilisateur: $DB_USER" -ForegroundColor White
Write-Host ""

# Verifier que le fichier de migration existe
$migrationFile = "migrations\fix_wave_database_schema.sql"
if (-not (Test-Path $migrationFile)) {
    Write-Host "Fichier de migration introuvable: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Fichier de migration trouve: $migrationFile" -ForegroundColor Green
Write-Host ""

# Confirmation avant execution
Write-Host "Cette migration va modifier la structure de votre base de donnees." -ForegroundColor Yellow
Write-Host "Tables affectees: notifications, payment_transactions, subscriptions" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Voulez-vous continuer? (O/N)"

if ($confirmation -ne 'O' -and $confirmation -ne 'o') {
    Write-Host "Migration annulee par l'utilisateur." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Lancement de la migration..." -ForegroundColor Cyan
Write-Host ""

# Executer la migration avec psql
$env:PGPASSWORD = $DB_PASSWORD

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $migrationFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "MIGRATION REUSSIE !" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Votre base de donnees est prete pour Wave Payment !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prochaines etapes:" -ForegroundColor Cyan
    Write-Host "   1. Redemarrer votre serveur backend" -ForegroundColor White
    Write-Host "   2. Tester un paiement Wave depuis l'application" -ForegroundColor White
    Write-Host "   3. Verifier les logs pour toute erreur eventuelle" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERREUR LORS DE LA MIGRATION" -ForegroundColor Red
    Write-Host "Code de sortie: $LASTEXITCODE" -ForegroundColor Yellow
    Write-Host "Verifiez les messages d'erreur ci-dessus." -ForegroundColor Yellow
    Write-Host ""
}

# Nettoyer la variable d'environnement du mot de passe
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
