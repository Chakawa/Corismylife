# 🚀 Script de Démarrage Rapide - CORIS Dashboard Admin
# Ce script démarre automatiquement le backend et le dashboard

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   CORIS - Démarrage Dashboard Admin" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Démarrer le Backend
Write-Host "[1/2] Démarrage du Backend (port 5000)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Write-Host 'Backend CORIS API' -ForegroundColor Green; cd 'd:\CORIS\app_coris\mycoris-master'; npm start"
)

# Attendre que le backend démarre
Write-Host "Attente du démarrage du backend (5 secondes)..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# 2. Démarrer le Dashboard
Write-Host "[2/2] Démarrage du Dashboard Admin (port 3000)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Write-Host 'Dashboard Admin CORIS' -ForegroundColor Green; cd 'd:\CORIS\app_coris\dashboard-admin'; npm run dev"
)

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   ✅ Démarrage en cours !" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend:    http://localhost:5000" -ForegroundColor Cyan
Write-Host "Dashboard:  http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Appuyez sur une touche pour fermer cette fenêtre..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
