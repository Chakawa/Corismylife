# ✅ Checklist de Mise en Production - MyCorisLife + CorisMoney

## 📋 Étape 1 : Configuration Backend (Node.js)

### Variables d'Environnement (.env)
- [x] `CORIS_MONEY_BASE_URL` configuré
- [x] `CORIS_MONEY_CLIENT_ID` configuré  
- [x] `CORIS_MONEY_CLIENT_SECRET` configuré
- [x] `CORIS_MONEY_CODE_PV` configuré
- [x] `CORIS_MONEY_DEV_MODE=false` (mode production activé)
- [ ] `NODE_ENV=production` (pour SSL strict)
- [ ] `DATABASE_URL` pointe vers la BDD de production
- [ ] `JWT_SECRET` sécurisé et unique

### Base de Données
```sql
-- Vérifier que ces tables existent :
SELECT * FROM payment_otp_requests LIMIT 1;
SELECT * FROM payment_transactions LIMIT 1;

-- Si elles n'existent pas, les créer :
CREATE TABLE IF NOT EXISTS payment_otp_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    code_pays VARCHAR(10),
    telephone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    subscription_id INTEGER REFERENCES subscriptions(id),
    transaction_id VARCHAR(255) UNIQUE,
    code_pays VARCHAR(10),
    telephone VARCHAR(20),
    montant DECIMAL(15,2),
    statut VARCHAR(50),
    description TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Ajouter colonnes de paiement à subscriptions si manquantes :
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50),
ADD COLUMN IF NOT EXISTS payment_transaction_id VARCHAR(255);
```

- [ ] Tables créées avec succès
- [ ] Colonnes `payment_method` et `payment_transaction_id` ajoutées à `subscriptions`
- [ ] Index créés pour performance :
```sql
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user 
ON payment_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_subscription 
ON payment_transactions(subscription_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_status 
ON payment_transactions(statut);
```

### Serveur Backend
- [ ] `npm install` exécuté sans erreurs
- [ ] Le serveur démarre sans erreurs : `node server.js`
- [ ] Les routes de paiement sont montées : `/api/payment/*`
- [ ] Logs de production affichés au démarrage :
```
💰 MODE PRODUCTION CORISMONEY ACTIVÉ
💰 API CorisMoney: https://testbed.corismoney.com/external/v1/api
💰 Client ID: MYCORISLIFETEST
💰 Code PV: 0280315524
💰 Les paiements seront RÉELS
```

---

## 📋 Étape 2 : Configuration Frontend (Flutter)

### Service de Paiement
Vérifier que `lib/services/corismoney_service.dart` existe avec :
- [ ] Fonction `sendOTP()`
- [ ] Fonction `processPayment()`
- [ ] Gestion des erreurs réseau
- [ ] Timeout configuré (30 secondes recommandé)

### Widget de Paiement
Vérifier que `lib/widgets/corismoney_payment_modal.dart` contient :
- [ ] Sélecteur de pays
- [ ] Champ numéro de téléphone avec validation
- [ ] Champs OTP (6 chiffres)
- [ ] Bouton "Envoyer le code"
- [ ] Bouton "Valider le paiement"
- [ ] Timer d'expiration OTP (5 minutes)
- [ ] Gestion des états : loading, success, error
- [ ] Messages d'erreur traduits en français

### Intégration dans les Écrans
Vérifier que le modal est appelé dans :
- [ ] `souscription_serenite.dart`
- [ ] `souscription_familis.dart`
- [ ] `souscription_etude.dart`
- [ ] `souscription_retraite.dart`
- [ ] `souscription_mon_bon_plan.dart`
- [ ] `souscription_epargne.dart`
- [ ] `souscription_assure_prestige.dart`
- [ ] `souscription_flex.dart`
- [ ] `sousription_solidarite.dart`
- [ ] `subscription_detail_screen.dart` (commercial)
- [ ] `proposition_detail_page.dart` (client)
- [ ] `mes_propositions_page.dart` (client)

### Assets et Images
- [x] `icone_wave.jpeg` présent dans `assets/images/`
- [x] `icone_orange_money.jpeg` présent dans `assets/images/`
- [x] `icone_corismoney.jpeg` présent dans `assets/images/`
- [x] Images déclarées dans `pubspec.yaml`

### Configuration Backend URL
Dans `lib/config/api_config.dart` ou équivalent :
```dart
class ApiConfig {
  // URL de production
  static const String baseUrl = 'https://votre-serveur.com';
  
  // Endpoints
  static const String sendOtpEndpoint = '/api/payment/send-otp';
  static const String processPaymentEndpoint = '/api/payment/process-payment';
  static const String transactionStatusEndpoint = '/api/payment/transaction-status';
}
```
- [ ] `baseUrl` configuré avec l'URL de production
- [ ] Tous les endpoints définis

---

## 📋 Étape 3 : Tests d'Intégration

### Tests Backend (API)
```bash
# Exécuter le script de test
cd /path/to/mycoris-master
node test-corismoney-api.js
```

- [ ] Test envoi OTP réussi
- [ ] Test paiement réussi avec OTP valide
- [ ] Test vérification statut transaction réussi
- [ ] Logs corrects affichés dans la console
- [ ] Données enregistrées dans `payment_transactions`

### Tests Frontend (Flutter)
Depuis l'application Flutter :

**Test 1 : Envoi OTP**
- [ ] Ouvrir une souscription (ex: Sérenité)
- [ ] Aller à l'étape de paiement
- [ ] Cliquer sur "CORIS Money"
- [ ] Saisir un numéro de téléphone valide
- [ ] Cliquer "Envoyer le code"
- [ ] Vérifier réception du SMS avec code OTP
- [ ] Vérifier que le timer démarre (5 minutes)

**Test 2 : Paiement**
- [ ] Saisir le code OTP reçu
- [ ] Cliquer "Valider le paiement"
- [ ] Vérifier le loader pendant le traitement
- [ ] Vérifier le message de succès
- [ ] Vérifier la redirection après succès
- [ ] Vérifier que le statut de la souscription passe à "paid"

**Test 3 : Gestion des Erreurs**
- [ ] Test avec numéro invalide → Message d'erreur approprié
- [ ] Test avec OTP expiré → Message d'erreur approprié
- [ ] Test avec OTP incorrect → Message d'erreur approprié
- [ ] Test sans connexion internet → Message d'erreur approprié
- [ ] Test avec serveur down → Message d'erreur approprié

**Test 4 : Historique**
- [ ] Voir l'historique des paiements dans le profil
- [ ] Vérifier les détails d'une transaction
- [ ] Vérifier le statut affiché (SUCCESS/FAILED)

---

## 📋 Étape 4 : Tests avec Vrais Utilisateurs

### Phase de Test Bêta
- [ ] Sélectionner 5-10 testeurs
- [ ] Leur donner accès à l'application
- [ ] Leur fournir un montant de test (ex: 1000 FCFA)
- [ ] Observer les comportements :
  - [ ] Facilité de saisie du numéro
  - [ ] Compréhension du processus OTP
  - [ ] Temps de réponse de l'API
  - [ ] Messages d'erreur compréhensibles

### Retours Utilisateurs
- [ ] Collecter les retours (bugs, suggestions)
- [ ] Corriger les problèmes identifiés
- [ ] Améliorer l'UX si nécessaire

---

## 📋 Étape 5 : Monitoring et Logs

### Backend
Configuration des logs en production :
```javascript
// Dans corisMoneyService.js - déjà configuré
console.log('💰 MODE PRODUCTION CORISMONEY ACTIVÉ');
console.log('📱 Envoi OTP:', codePays, telephone);
console.log('💰 Traitement paiement:', montant, 'FCFA');
console.log('✅ Paiement réussi, Transaction ID:', transactionId);
console.error('❌ Erreur paiement:', error.message);
```

- [ ] Logs activés et visibles
- [ ] Rotation des logs configurée (logrotate ou PM2)
- [ ] Alertes configurées pour les erreurs critiques

### Base de Données
Requêtes de monitoring :
```sql
-- Transactions du jour
SELECT COUNT(*), SUM(montant), statut 
FROM payment_transactions 
WHERE DATE(created_at) = CURRENT_DATE 
GROUP BY statut;

-- Taux de réussite
SELECT 
  statut,
  COUNT(*) as total,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pourcentage
FROM payment_transactions
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY statut;

-- Dernières transactions échouées
SELECT * FROM payment_transactions 
WHERE statut = 'FAILED' 
ORDER BY created_at DESC 
LIMIT 10;
```

- [ ] Dashboard de monitoring créé (ex: Grafana, Metabase)
- [ ] Alertes configurées pour les échecs répétés

---

## 📋 Étape 6 : Sécurité

### Backend
- [ ] Variables d'environnement sécurisées (pas de commit dans Git)
- [ ] HTTPS activé sur le serveur
- [ ] CORS configuré pour autoriser uniquement l'app Flutter
- [ ] Rate limiting activé sur les routes de paiement
- [ ] Validation stricte des montants (min/max)
- [ ] Authentification JWT obligatoire sur toutes les routes

### Frontend
- [ ] Token JWT stocké de manière sécurisée (flutter_secure_storage)
- [ ] Pas de données sensibles en clair dans le code
- [ ] Validation côté client des entrées utilisateur
- [ ] Timeout configuré sur les requêtes réseau

### API CorisMoney
- [ ] Hash SHA256 correct sur toutes les requêtes
- [ ] Headers `clientId` et `hashParam` présents
- [ ] Certificat SSL vérifié (`rejectUnauthorized: true` en production)

---

## 📋 Étape 7 : Documentation

### Documentation Technique
- [x] `CORISMONEY_PRODUCTION_GUIDE.md` créé
- [ ] Documentation API mise à jour
- [ ] Schéma de base de données à jour
- [ ] Flux de paiement documenté

### Documentation Utilisateur
- [ ] Guide utilisateur pour le paiement CorisMoney
- [ ] FAQ sur les problèmes courants
- [ ] Vidéo explicative (optionnel)

---

## 📋 Étape 8 : Déploiement Production

### Backend
```bash
# 1. Cloner le projet sur le serveur de production
git clone https://github.com/votre-repo/mycoris-backend.git
cd mycoris-backend

# 2. Installer les dépendances
npm install --production

# 3. Configurer .env avec les variables de production
cp .env.example .env
nano .env  # Éditer avec les vraies valeurs

# 4. Vérifier la connexion à la base de données
node test-db-connection.js

# 5. Lancer avec PM2 (recommandé)
npm install -g pm2
pm2 start server.js --name mycoris-api
pm2 save
pm2 startup
```

- [ ] Backend déployé sur le serveur
- [ ] PM2 configuré pour redémarrage automatique
- [ ] Logs PM2 accessibles : `pm2 logs mycoris-api`

### Frontend
```bash
# 1. Build de production
cd mycorislife-master
flutter build apk --release  # Pour Android
flutter build ios --release  # Pour iOS

# 2. Tester l'APK/IPA
flutter install  # Installer sur un device

# 3. Publier sur les stores
# - Google Play Console (Android)
# - App Store Connect (iOS)
```

- [ ] APK/IPA généré sans erreurs
- [ ] Application testée sur device réel
- [ ] Application publiée sur Play Store / App Store

---

## 📋 Étape 9 : Post-Production

### Monitoring (Première Semaine)
- [ ] Surveiller les logs quotidiennement
- [ ] Vérifier le taux de réussite des paiements
- [ ] Collecter les retours utilisateurs
- [ ] Corriger les bugs critiques rapidement

### Optimisations
- [ ] Analyser les performances (temps de réponse API)
- [ ] Optimiser les requêtes lentes
- [ ] Ajouter du caching si nécessaire

### Support Client
- [ ] Former l'équipe support sur le processus de paiement
- [ ] Créer des scripts de résolution de problèmes
- [ ] Mettre en place un système de ticketing

---

## 📊 Indicateurs de Succès

- **Taux de réussite des paiements** : > 95%
- **Temps de réponse API** : < 3 secondes
- **Satisfaction utilisateur** : > 4/5
- **Nombre d'erreurs critiques** : 0 par semaine

---

## 🚨 Contact en Cas d'Urgence

- **Support CorisMoney** : [contact@corismoney.com] ou hotline
- **Admin Base de Données** : [admin@mycoris.com]
- **Développeur Backend** : [dev@mycoris.com]
- **Développeur Flutter** : [flutter@mycoris.com]

---

**Date de création** : 05/02/2026  
**Dernière mise à jour** : 05/02/2026  
**Responsable** : Équipe MyCorisLife  
**Statut** : ✅ Configuration finalisée, prêt pour les tests
