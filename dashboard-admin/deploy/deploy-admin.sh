#!/usr/bin/env bash
set -euo pipefail

# Script de déploiement local serveur (à exécuter SUR le serveur Linux)
# Usage:
#   cd /chemin/vers/dashboard-admin
#   chmod +x deploy/deploy-admin.sh
#   ./deploy/deploy-admin.sh

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="/var/www/coris/dashboard-admin"

echo "[1/5] Installation des dépendances..."
cd "$APP_DIR"
npm ci

echo "[2/5] Build production..."
npm run build

echo "[3/5] Création du dossier cible..."
sudo mkdir -p "$TARGET_DIR"

echo "[4/5] Copie du build..."
sudo rsync -av --delete "$APP_DIR/dist/" "$TARGET_DIR/dist/"

echo "[5/5] Terminé. Pensez à recharger Nginx :"
echo "    sudo nginx -t && sudo systemctl reload nginx"
