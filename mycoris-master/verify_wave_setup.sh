#!/bin/bash
# ============================================================================
# Script de vérification et configuration Wave Checkout
# ============================================================================
# Usage: bash verify_wave_setup.sh

echo "🌊 VÉRIFICATION WAVE CHECKOUT"
echo "=============================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
PASS=0
FAIL=0

# ============================================================================
# 1. Vérifier les variables d'environnement
# ============================================================================
echo "📋 1. VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT"
echo "───────────────────────────────────────────────"

check_env() {
  local var=$1
  local description=$2
  
  if [ -z "${!var}" ]; then
    echo -e "${RED}❌ $var${NC} - $description (MANQUANT)"
    FAIL=$((FAIL + 1))
  else
    if [[ ${!var} == *"xxx"* ]] || [[ ${!var} == *"your"* ]]; then
      echo -e "${YELLOW}⚠️  $var${NC} - $description (À METTRE À JOUR)"
      FAIL=$((FAIL + 1))
    else
      echo -e "${GREEN}✅ $var${NC} - $description"
      PASS=$((PASS + 1))
    fi
  fi
}

# Charger le .env
if [ -f ".env" ]; then
  export $(cat .env | grep -v '#' | xargs)
  echo -e "${GREEN}✅ Fichier .env trouvé${NC}\n"
else
  echo -e "${RED}❌ Fichier .env non trouvé${NC}"
  echo "   Créer un fichier .env avec:"
  echo "   cp .env.wave.example .env"
  echo ""
  FAIL=$((FAIL + 1))
fi

# Vérifier les variables requises
check_env "WAVE_API_KEY" "API Key Wave (sk_live_...)"
check_env "WAVE_WEBHOOK_SECRET" "Secret Webhook Wave (whsk_live_...)"
check_env "WAVE_SUCCESS_URL" "URL de succès"
check_env "WAVE_ERROR_URL" "URL d'erreur"
check_env "WAVE_WEBHOOK_URL" "URL du webhook"

echo ""

# ============================================================================
# 2. Vérifier les routes
# ============================================================================
echo "🔧 2. VÉRIFICATION DES ROUTES"
echo "─────────────────────────────"

check_route() {
  local route=$1
  local file=$2
  
  if grep -q "router\.\(get\|post\)('$route'" "$file" 2>/dev/null; then
    echo -e "${GREEN}✅ $route${NC} - Route trouvée"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}❌ $route${NC} - Route manquante"
    FAIL=$((FAIL + 1))
  fi
}

check_route "/wave-success" "routes/paymentRoutes.js"
check_route "/wave-error" "routes/paymentRoutes.js"
check_route "/wave/webhook" "routes/paymentRoutes.js"
check_route "/confirm-wave-payment" "routes/paymentRoutes.js"

echo ""

# ============================================================================
# 3. Vérifier les certificats HTTPS
# ============================================================================
echo "🔐 3. VÉRIFICATION DES CERTIFICATS HTTPS"
echo "────────────────────────────────────────"

if [ -f "/etc/letsencrypt/live/185.98.138.168/cert.pem" ]; then
  EXPIRY=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/185.98.138.168/cert.pem | cut -d= -f2)
  echo -e "${GREEN}✅ Certificat trouvé${NC}"
  echo "   Expiration: $EXPIRY"
  PASS=$((PASS + 1))
else
  echo -e "${YELLOW}⚠️  Certificat Let's Encrypt non trouvé${NC}"
  echo "   Créer avec: sudo certbot certonly --standalone -d 185.98.138.168"
  FAIL=$((FAIL + 1))
fi

echo ""

# ============================================================================
# 4. Vérifier la base de données
# ============================================================================
echo "🗄️  4. VÉRIFICATION DE LA BASE DE DONNÉES"
echo "──────────────────────────────────────────"

if psql -U ${DB_USER:-postgres} -d ${DB_NAME:-mycorisdb} -c "SELECT 1" > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Connexion PostgreSQL OK${NC}"
  
  # Vérifier les tables
  if psql -U ${DB_USER:-postgres} -d ${DB_NAME:-mycorisdb} -c "SELECT 1 FROM payment_transactions LIMIT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Table payment_transactions existe${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${YELLOW}⚠️  Table payment_transactions non trouvée${NC}"
    FAIL=$((FAIL + 1))
  fi
  
  if psql -U ${DB_USER:-postgres} -d ${DB_NAME:-mycorisdb} -c "SELECT 1 FROM subscriptions LIMIT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Table subscriptions existe${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}❌ Table subscriptions manquante${NC}"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${RED}❌ Connexion PostgreSQL échouée${NC}"
  FAIL=$((FAIL + 1))
fi

echo ""

# ============================================================================
# 5. Vérifier le serveur est en marche
# ============================================================================
echo "🚀 5. VÉRIFICATION DU SERVEUR"
echo "─────────────────────────────"

if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Serveur écoute sur port 5000${NC}"
  PASS=$((PASS + 1))
else
  echo -e "${YELLOW}⚠️  Serveur non accessible sur port 5000${NC}"
  echo "   Lancer avec: npm start ou pm2 start app.js"
  FAIL=$((FAIL + 1))
fi

# Vérifier HTTPS
if curl -k -s -o /dev/null -w "%{http_code}" https://185.98.138.168:5000/api > /dev/null 2>&1; then
  echo -e "${GREEN}✅ HTTPS accessible${NC}"
  PASS=$((PASS + 1))
else
  echo -e "${RED}❌ HTTPS non accessible${NC}"
  FAIL=$((FAIL + 1))
fi

echo ""

# ============================================================================
# 6. Tests d'URL
# ============================================================================
echo "🌐 6. TESTS DES URLS"
echo "────────────────────"

echo -n "   GET /wave-success... "
STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "https://185.98.138.168:5000/wave-success?session_id=test")
if [ "$STATUS" = "200" ]; then
  echo -e "${GREEN}✅ 200${NC}"
  PASS=$((PASS + 1))
else
  echo -e "${RED}❌ $STATUS${NC}"
  FAIL=$((FAIL + 1))
fi

echo -n "   GET /wave-error... "
STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "https://185.98.138.168:5000/wave-error?session_id=test")
if [ "$STATUS" = "200" ]; then
  echo -e "${GREEN}✅ 200${NC}"
  PASS=$((PASS + 1))
else
  echo -e "${RED}❌ $STATUS${NC}"
  FAIL=$((FAIL + 1))
fi

echo ""

# ============================================================================
# Rapport final
# ============================================================================
echo "════════════════════════════════════════"
echo "📊 RAPPORT FINAL"
echo "════════════════════════════════════════"
echo -e "✅ Réussi: $GREEN$PASS$NC"
echo -e "❌ Échoué: $RED$FAIL$NC"
echo "════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}🎉 TOUT EST CONFIGURÉ CORRECTEMENT!${NC}"
  echo ""
  echo "Prochaines étapes:"
  echo "1. Tester avec un vrai paiement:"
  echo "   - Ouvrir l'app Flutter"
  echo "   - Naviguer vers une Proposition"
  echo "   - Cliquer sur 'Payer avec Wave'"
  echo ""
  echo "2. Vérifier les logs:"
  echo "   tail -f logs/payment.log | grep -i webhook"
  echo ""
  echo "3. Configurer Wave Webhook dans le Dashboard:"
  echo "   https://dashboard.wave.com/settings/webhooks"
  echo "   URL: $WAVE_WEBHOOK_URL"
  echo ""
  exit 0
else
  echo -e "${RED}⚠️  CERTAINS ÉLÉMENTS MANQUENT${NC}"
  echo ""
  echo "Actions requises:"
  echo "1. Vérifier les variables .env"
  echo "2. Relancer: npm restart"
  echo "3. Vérifier les certificats HTTPS"
  echo "4. Re-exécuter ce script"
  echo ""
  exit 1
fi
