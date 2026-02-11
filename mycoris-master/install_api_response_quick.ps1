# Script rapide pour ajouter la colonne api_response
# Utilise la connexion depuis .env

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Migration: Ajout colonne api_response" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$DB_HOST = "185.98.138.168"
$DB_PORT = "5432"
$DB_NAME = "mycorisdb"
$DB_USER = "db_admin"
$DB_PASSWORD = "Corisvie2025"

Write-Host "Execution de la migration..." -ForegroundColor Yellow

# Définir PGPASSWORD
$env:PGPASSWORD = $DB_PASSWORD

try {
    # Exécuter le SQL
    $output = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "add_api_response_column.sql" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] Migration reussie!" -ForegroundColor Green
        Write-Host ""
        Write-Host $output -ForegroundColor Gray
        Write-Host ""
        Write-Host "[OK] Colonne api_response (JSONB) ajoutee" -ForegroundColor Green
        Write-Host "[OK] Index GIN cree pour requetes JSON" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "[ERREUR]:" -ForegroundColor Red
        Write-Host $output -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "[ERREUR]: $_" -ForegroundColor Red
    exit 1
} finally {
    $env:PGPASSWORD = ""
}

Write-Host ""
Write-Host "==> Migration terminee!" -ForegroundColor Green
