#!/bin/bash

# ==========================================
# CORIS Dashboard - Script de Démarrage Complet
# ==========================================
# Ce script démarre complètement le système CORIS Admin Dashboard
# Usage: bash start-all.sh  ou  chmod +x start-all.sh && ./start-all.sh

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🚀 CORIS Admin Dashboard - Démarrage Complet          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs pour affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================================
# Étape 1: Migration Base de Données
# ==========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Étape 1: Migration Base de Données${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -d "mycoris-master" ]; then
    cd mycoris-master
    echo -e "${YELLOW}▶ Exécution: node run_notifications_migration.js${NC}"
    if node run_notifications_migration.js; then
        echo -e "${GREEN}✅ Migration réussie${NC}"
    else
        echo -e "${RED}❌ Erreur migration${NC}"
        exit 1
    fi
    cd ..
else
    echo -e "${RED}❌ Dossier mycoris-master non trouvé${NC}"
    exit 1
fi

echo ""
echo ""

# ==========================================
# Étape 2: Démarrer Backend
# ==========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Étape 2: Démarrage du Backend${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -d "mycoris-master" ]; then
    echo -e "${YELLOW}▶ Démarrage du serveur backend sur port 5000...${NC}"
    cd mycoris-master
    npm start &
    BACKEND_PID=$!
    echo -e "${GREEN}✅ Backend démarré (PID: $BACKEND_PID)${NC}"
    echo -e "${GREEN}   URL: http://localhost:5000${NC}"
    cd ..
    
    # Attendre que le backend soit prêt
    sleep 3
else
    echo -e "${RED}❌ Dossier mycoris-master non trouvé${NC}"
    exit 1
fi

echo ""
echo ""

# ==========================================
# Étape 3: Démarrer Frontend
# ==========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Étape 3: Démarrage du Dashboard Frontend${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -d "dashboard-admin" ]; then
    echo -e "${YELLOW}▶ Démarrage du dashboard frontend sur port 3000...${NC}"
    cd dashboard-admin
    npm run dev &
    FRONTEND_PID=$!
    echo -e "${GREEN}✅ Frontend démarré (PID: $FRONTEND_PID)${NC}"
    echo -e "${GREEN}   URL: http://localhost:3000${NC}"
    cd ..
else
    echo -e "${RED}❌ Dossier dashboard-admin non trouvé${NC}"
    exit 1
fi

echo ""
echo ""

# ==========================================
# Afficher Informations de Démarrage
# ==========================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            ✅ DÉMARRAGE RÉUSSI                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 ACCÈS AU SYSTÈME:${NC}"
echo -e "  🌐 Dashboard:  ${BLUE}http://localhost:3000${NC}"
echo -e "  🔌 API:        ${BLUE}http://localhost:5000${NC}"
echo ""
echo -e "${YELLOW}📝 IDENTIFIANTS:${NC}"
echo "  Email: [votre email admin]"
echo "  Mot de passe: [votre mot de passe]"
echo ""
echo -e "${BLUE}📋 FONCTIONNALITÉS DISPONIBLES:${NC}"
echo "  ✅ Gestion des utilisateurs (CRUD complet)"
echo "  ✅ Notifications en temps réel"
echo "  ✅ Dashboard analytique"
echo "  ✅ Authentification JWT"
echo ""
echo -e "${YELLOW}⚠️  POUR ARRÊTER LE SYSTÈME:${NC}"
echo "  Appuyez sur Ctrl+C dans ce terminal"
echo ""
echo -e "${BLUE}🔍 LOGS:${NC}"
echo "  Backend:  Visible dans ce terminal"
echo "  Frontend: Visible dans le terminal du dashboard"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Garder les processus en arrière-plan actifs
wait

# ==========================================
# Cleanup si le script est arrêté
# ==========================================
trap "echo -e '${YELLOW}Arrêt du système...${NC}'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo -e '${GREEN}✅ Système arrêté${NC}'; exit 0" SIGINT SIGTERM
