# 🔐 Intégration CorisMoney - Documentation Complète

## 📋 Table des matières
1. [Vue d'ensemble](#vue-densemble)
2. [Configuration](#configuration)
3. [Architecture](#architecture)
4. [Backend](#backend)
5. [Frontend](#frontend)
6. [Tests](#tests)
7. [Déploiement](#déploiement)
8. [Dépannage](#dépannage)

---

## 🎯 Vue d'ensemble

L'intégration CorisMoney permet aux utilisateurs de payer leurs primes d'assurance directement via leur compte CorisMoney. Le processus utilise un système de double validation avec code OTP pour garantir la sécurité des transactions.

### Fonctionnalités implémentées
- ✅ Paiement de biens et services
- ✅ Envoi de code OTP
- ✅ Vérification des informations client
- ✅ Suivi des transactions
- ✅ Historique des paiements
- ✅ Interface utilisateur moderne et responsive

### Environnement
- **Test**: `https://testbed.corismoney.com/external/v1/api`
- **Production**: `https://corismoney.com/external/v1/api` (à configurer)

---

## ⚙️ Configuration

### 1. Variables d'environnement

Éditez le fichier `.env` dans le dossier `mycoris-master` :

```env
# Configuration CorisMoney
CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=votre_client_id_ici
CORIS_MONEY_CLIENT_SECRET=votre_client_secret_ici
CORIS_MONEY_CODE_PV=votre_code_pv_ici
```

**⚠️ IMPORTANT**: Remplacez les valeurs par défaut par vos vrais identifiants CorisMoney.

### 2. Installation des dépendances

```bash
cd mycoris-master
npm install axios crypto
```

### 3. Migration de la base de données

Créez les tables nécessaires :

```bash
node scripts/run_corismoney_migration.js
```

Cela créera deux tables :
- `payment_otp_requests` : Historique des demandes d'OTP
- `payment_transactions` : Toutes les transactions de paiement

---

## 🏗️ Architecture

### Flux de paiement

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Frontend  │─────▶│   Backend   │─────▶│ CorisMoney  │
│  (React)    │      │  (Node.js)  │      │     API     │
└─────────────┘      └─────────────┘      └─────────────┘
      │                     │                     │
      │   1. Send OTP       │                     │
      │────────────────────▶│  POST /send-otp     │
      │                     │────────────────────▶│
      │                     │  ◀─────OTP envoyé   │
      │   ◀─────────────────│                     │
      │                     │                     │
      │   2. Saisie OTP     │                     │
      │                     │                     │
      │   3. Process Payment│                     │
      │────────────────────▶│  POST /paiement-bien│
      │                     │────────────────────▶│
      │                     │  ◀─────Confirmation │
      │   ◀─────────────────│                     │
      │  Succès + TX ID     │                     │
```

### Sécurité

Toutes les requêtes vers CorisMoney incluent :
- **clientId** : Identifiant unique du marchand
- **hashParam** : Hash SHA256 des paramètres + clientSecret

Exemple de calcul du hash :
```javascript
// Pour l'envoi d'OTP
hashParam = SHA256(codePays + telephone + clientSecret)

// Pour le paiement
hashParam = SHA256(codePays + telephone + codePv + montant + codeOTP + clientSecret)
```

---

## 🔧 Backend

### Structure des fichiers

```
mycoris-master/
├── services/
│   └── corisMoneyService.js       # Service principal CorisMoney
├── routes/
│   └── paymentRoutes.js           # Routes API de paiement
├── migrations/
│   └── add_corismoney_payment_tables.sql
└── scripts/
    └── run_corismoney_migration.js
```

### Endpoints API

#### 1. POST `/api/payment/send-otp`
Envoie un code OTP au numéro CorisMoney du client.

**Headers requis:**
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "codePays": "225",
  "telephone": "0102030405"
}
```

**Réponse (succès):**
```json
{
  "success": true,
  "message": "Code OTP envoyé avec succès"
}
```

---

#### 2. POST `/api/payment/process-payment`
Traite le paiement avec le code OTP.

**Headers requis:**
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "codePays": "225",
  "telephone": "0102030405",
  "montant": 50000,
  "codeOTP": "123456",
  "subscriptionId": 123,
  "description": "Paiement de prime d'assurance"
}
```

**Réponse (succès):**
```json
{
  "success": true,
  "message": "Opération effectuée avec succès !",
  "transactionId": "20232208.F422",
  "montant": 50000,
  "paymentRecordId": 456
}
```

---

#### 3. GET `/api/payment/client-info`
Récupère les informations d'un client CorisMoney.

**Query parameters:**
- `codePays`: Code pays (ex: "225")
- `telephone`: Numéro de téléphone

**Réponse (succès):**
```json
{
  "success": true,
  "data": {
    "nom": "FOFANA",
    "prenom": "Chaka",
    "telephone": "+225 0102030405"
  }
}
```

---

#### 4. GET `/api/payment/transaction-status/:transactionId`
Vérifie le statut d'une transaction.

**Paramètre:**
- `transactionId`: ID de la transaction CorisMoney

**Réponse:**
```json
{
  "success": true,
  "data": {
    "status": "SUCCESS",
    "montant": 50000
  }
}
```

---

#### 5. GET `/api/payment/history`
Récupère l'historique des paiements de l'utilisateur.

**Query parameters (optionnels):**
- `limit`: Nombre de transactions (défaut: 50)
- `offset`: Décalage (défaut: 0)

**Réponse:**
```json
{
  "success": true,
  "total": 10,
  "data": [
    {
      "id": 1,
      "transaction_id": "20232208.F422",
      "montant": 50000,
      "statut": "SUCCESS",
      "description": "Paiement de prime",
      "created_at": "2026-02-03T10:30:00Z"
    }
  ]
}
```

---

## 🎨 Frontend

### Composant principal: `CorisMoneyPaymentModal`

#### Importation
```jsx
import CorisMoneyPaymentModal from '../components/CorisMoneyPaymentModal';
```

#### Props

| Prop | Type | Requis | Description |
|------|------|--------|-------------|
| `isOpen` | boolean | ✅ | Contrôle l'affichage de la modal |
| `onClose` | function | ✅ | Fonction appelée à la fermeture |
| `onPaymentSuccess` | function | ❌ | Callback après paiement réussi |
| `montant` | number | ✅ | Montant à payer (en FCFA) |
| `subscriptionId` | number | ❌ | ID de la souscription |
| `description` | string | ❌ | Description du paiement |

#### Exemple d'utilisation

```jsx
import React, { useState } from 'react';
import CorisMoneyPaymentModal from '../components/CorisMoneyPaymentModal';

function MaPage() {
  const [showPayment, setShowPayment] = useState(false);

  const handleSuccess = (result) => {
    console.log('Transaction ID:', result.transactionId);
    console.log('Montant:', result.montant);
    // Rafraîchir les données, rediriger, etc.
  };

  return (
    <div>
      <button onClick={() => setShowPayment(true)}>
        Payer avec CorisMoney
      </button>

      <CorisMoneyPaymentModal
        isOpen={showPayment}
        onClose={() => setShowPayment(false)}
        onPaymentSuccess={handleSuccess}
        montant={50000}
        subscriptionId={123}
        description="Paiement prime assurance vie"
      />
    </div>
  );
}
```

### États du composant

Le composant gère 3 étapes :
1. **Saisie du numéro de téléphone** → Envoi de l'OTP
2. **Saisie du code OTP** → Traitement du paiement
3. **Confirmation** → Affichage du résultat

---

## 🧪 Tests

### 1. Lancer les tests automatiques

```bash
cd mycoris-master
node test_corismoney_integration.js
```

Les tests vérifieront :
- ✅ Configuration des variables d'environnement
- ✅ Disponibilité des routes API
- ✅ Envoi de code OTP
- ✅ Récupération des informations client
- ✅ Historique des paiements

### 2. Tests manuels

#### Test 1: Envoi d'OTP avec Postman/curl

```bash
curl -X POST http://localhost:5000/api/payment/send-otp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "codePays": "225",
    "telephone": "0102030405"
  }'
```

#### Test 2: Paiement complet

1. Utilisez l'interface web
2. Cliquez sur "Payer avec CorisMoney"
3. Entrez votre numéro CorisMoney de test
4. Recevez l'OTP
5. Validez le paiement

### 3. Numéros de test CorisMoney

Demandez à CorisMoney des numéros de compte de test pour l'environnement `testbed`.

---

## 🚀 Déploiement

### Pré-production (Testbed)

1. **Vérifier la configuration**
   ```bash
   # Fichier .env
   CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
   ```

2. **Tester complètement**
   - Tous les endpoints API
   - Interface utilisateur
   - Cas d'erreur (montant insuffisant, OTP invalide, etc.)

### Production

1. **Mettre à jour l'URL de base**
   ```env
   CORIS_MONEY_BASE_URL=https://corismoney.com/external/v1/api
   ```

2. **Utiliser les vrais identifiants**
   - Récupérer `clientId`, `clientSecret`, `codePv` de production
   - NE JAMAIS commiter ces valeurs dans Git

3. **Sécurité**
   - Utiliser HTTPS uniquement
   - Valider tous les montants côté serveur
   - Logger toutes les transactions
   - Mettre en place des alertes pour les échecs

4. **Monitoring**
   - Surveiller les taux de succès/échec
   - Alertes sur les erreurs 500
   - Vérifier les temps de réponse

---

## 🔧 Dépannage

### Erreur: "Identifiants CorisMoney non configurés"

**Solution:**
Vérifiez que les variables d'environnement sont bien définies dans `.env` :
```env
CORIS_MONEY_CLIENT_ID=votre_vrai_id
CORIS_MONEY_CLIENT_SECRET=votre_vrai_secret
CORIS_MONEY_CODE_PV=votre_code_pv
```

Redémarrez le serveur après modification.

---

### Erreur: "Code OTP invalide"

**Causes possibles:**
1. Code expiré (validité ~5 minutes)
2. Mauvaise saisie du code
3. Numéro de téléphone différent

**Solution:**
Demandez un nouveau code OTP.

---

### Erreur: "Solde insuffisant"

Le compte CorisMoney n'a pas assez de fonds.

**Solution:**
Vérifiez le solde ou utilisez un autre compte.

---

### Erreur de connexion à l'API CorisMoney

**Causes:**
- API CorisMoney hors ligne
- Problème réseau
- URL incorrecte

**Solution:**
1. Vérifiez `CORIS_MONEY_BASE_URL`
2. Testez la connectivité : `ping testbed.corismoney.com`
3. Contactez le support CorisMoney

---

### Transactions bloquées en statut "PENDING"

**Solution:**
Utilisez l'endpoint de vérification :
```bash
GET /api/payment/transaction-status/:transactionId
```

Cela synchronisera le statut avec CorisMoney.

---

## 📞 Support

### CorisMoney
- **Email**: support@corismoney.com
- **Documentation**: Voir le PDF fourni
- **Environnement de test**: https://testbed.corismoney.com

### Équipe Technique CORIS Assurance
- Vérifier les logs serveur : `mycoris-master/logs/`
- Consulter la base de données : tables `payment_*`

---

## 📝 Checklist de lancement

Avant de mettre en production :

- [ ] Variables d'environnement configurées (production)
- [ ] Migration de base de données exécutée
- [ ] Tests automatiques passés avec succès
- [ ] Tests manuels effectués (paiement complet)
- [ ] Monitoring mis en place
- [ ] Documentation lue par l'équipe
- [ ] Plan de rollback préparé
- [ ] Support CorisMoney informé du lancement
- [ ] Limits de transaction configurées
- [ ] Logs et alertes opérationnels

---

## 🔄 Changelog

### Version 1.0.0 (2026-02-03)
- ✅ Implémentation initiale
- ✅ Service de paiement de biens
- ✅ Interface utilisateur complète
- ✅ Tests automatiques
- ✅ Documentation

---

**Dernière mise à jour:** 3 février 2026
**Version:** 1.0.0
**Auteur:** Équipe Technique CORIS Assurance
