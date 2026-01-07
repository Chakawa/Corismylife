@echo off
REM ==========================================
REM CORIS Dashboard - Script de Démarrage (Windows)
REM ==========================================
REM Ce script démarre complètement le système CORIS Admin Dashboard
REM Usage: start-all.bat  ou double-cliquer sur ce fichier

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     🚀 CORIS Admin Dashboard - Démarrage Complet          ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM ==========================================
REM Étape 1: Migration Base de Données
REM ==========================================
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Étape 1: Migration Base de Données
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

if exist "mycoris-master" (
    cd mycoris-master
    echo ▶ Exécution: node run_notifications_migration.js
    call node run_notifications_migration.js
    if errorlevel 1 (
        echo ❌ Erreur migration
        pause
        exit /b 1
    )
    echo ✅ Migration réussie
    cd ..
) else (
    echo ❌ Dossier mycoris-master non trouvé
    pause
    exit /b 1
)

echo.
echo.

REM ==========================================
REM Étape 2: Démarrer Backend
REM ==========================================
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Étape 2: Démarrage du Backend
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

if exist "mycoris-master" (
    echo ▶ Démarrage du serveur backend sur port 5000...
    cd mycoris-master
    start "Backend CORIS" cmd /k "npm start"
    echo ✅ Backend démarré dans une nouvelle fenêtre
    echo    URL: http://localhost:5000
    cd ..
    timeout /t 3 /nobreak
) else (
    echo ❌ Dossier mycoris-master non trouvé
    pause
    exit /b 1
)

echo.
echo.

REM ==========================================
REM Étape 3: Démarrer Frontend
REM ==========================================
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Étape 3: Démarrage du Dashboard Frontend
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

if exist "dashboard-admin" (
    echo ▶ Démarrage du dashboard frontend sur port 3000...
    cd dashboard-admin
    start "Frontend CORIS" cmd /k "npm run dev"
    echo ✅ Frontend démarré dans une nouvelle fenêtre
    echo    URL: http://localhost:3000
    cd ..
) else (
    echo ❌ Dossier dashboard-admin non trouvé
    pause
    exit /b 1
)

echo.
echo.

REM ==========================================
REM Afficher Informations de Démarrage
REM ==========================================
echo ╔════════════════════════════════════════════════════════════╗
echo ║            ✅ DÉMARRAGE RÉUSSI                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo 📊 ACCÈS AU SYSTÈME:
echo    🌐 Dashboard:  http://localhost:3000
echo    🔌 API:        http://localhost:5000
echo.

echo 📝 IDENTIFIANTS:
echo    Email: [votre email admin]
echo    Mot de passe: [votre mot de passe]
echo.

echo 📋 FONCTIONNALITÉS DISPONIBLES:
echo    ✅ Gestion des utilisateurs (CRUD complet)
echo    ✅ Notifications en temps réel
echo    ✅ Dashboard analytique
echo    ✅ Authentification JWT
echo.

echo 📋 FENÊTRES OUVERTES:
echo    1. Backend (5000)  - Terminal avec logs serveur
echo    2. Frontend (3000) - Terminal avec Vite HMR
echo    3. Cette fenêtre   - Contrôle principal
echo.

echo ⚠️  POUR ARRÊTER LE SYSTÈME:
echo    1. Appuyez sur Ctrl+C dans chaque fenêtre du terminal
echo    2. Ou fermez les fenêtres normalement
echo.

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo Appuyez sur une touche pour continuer ou fermer cette fenêtre...
pause

endlocal
