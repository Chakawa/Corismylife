# Script pour ajouter la colonne api_response à la table payment_transactions
# Date: 2026-02-11

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 Migration: Ajout colonne api_response" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Configuration base de données
$DB_HOST = "185.98.138.168"
$DB_PORT = "5432"
$DB_NAME = "mycorisdb"
$DB_USER = "corisuser"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  - Host: $DB_HOST" -ForegroundColor White
Write-Host "  - Port: $DB_PORT" -ForegroundColor White
Write-Host "  - Database: $DB_NAME" -ForegroundColor White
Write-Host "  - User: $DB_USER" -ForegroundColor White
Write-Host ""

# Demander le mot de passe
$DB_PASSWORD = Read-Host "🔑 Entrez le mot de passe de la base de données" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DB_PASSWORD)
$DB_PASSWORD_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "⏳ Exécution de la migration..." -ForegroundColor Yellow

# Définir la variable d'environnement PGPASSWORD
$env:PGPASSWORD = $DB_PASSWORD_PLAIN

try {
    # Exécuter le fichier SQL
    $output = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "add_api_response_column.sql" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Migration réussie!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Détails:" -ForegroundColor Cyan
        Write-Host $output -ForegroundColor Gray
        Write-Host ""
        Write-Host "✅ La colonne api_response (JSONB) a été ajoutée avec succès" -ForegroundColor Green
        Write-Host "✅ Index GIN créé pour optimiser les requêtes JSON" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Erreur lors de la migration" -ForegroundColor Red
        Write-Host $output -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
    exit 1
} finally {
    # Effacer le mot de passe de l'environnement
    $env:PGPASSWORD = ""
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 Migration terminée avec succès!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
