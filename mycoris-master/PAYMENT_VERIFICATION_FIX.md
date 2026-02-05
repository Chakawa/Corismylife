# 🔒 Vérification du Statut de Paiement CorisMoney - CORRECTION CRITIQUE

## 🚨 Problème Identifié

### Ancien Comportement (DANGEREUX)
```javascript
// ❌ PROBLÈME : Marquage comme SUCCESS sans vérification
if (result.success) {
  await pool.query(
    `UPDATE subscriptions SET statut = 'paid'`  // ❌ IMMÉDIAT !
  );
  
  return res.json({
    success: true,
    message: 'Paiement effectué avec succès'  // ❌ FAUX si solde insuffisant !
  });
}
```

**Conséquences graves :**
- ✅ Client saisit le code OTP
- ⚠️ Solde insuffisant sur CorisMoney
- ❌ Application affiche "Paiement effectué avec succès"
- ❌ Proposition transformée en contrat
- ❌ Client pense avoir payé alors que non
- ❌ Manque à gagner pour l'entreprise

---

## ✅ Nouvelle Solution Implémentée

### 1. Vérification du Statut Réel

```javascript
// ✅ CORRECT : Vérification du statut auprès de CorisMoney
const result = await corisMoneyService.paiementBien(codePays, telephone, montant, codeOTP);

if (result.success) {
  // Attendre 2 secondes pour le traitement
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // ✅ Vérifier le statut réel de la transaction
  const statusResult = await corisMoneyService.getTransactionStatus(result.transactionId);
  
  if (statusResult.data.statut === 'SUCCESS') {
    transactionStatus = 'SUCCESS';
  } else if (statusResult.data.statut === 'INSUFFICIENT_BALANCE') {
    transactionStatus = 'FAILED';
    errorMessage = 'Solde insuffisant';
  } else {
    transactionStatus = 'PENDING';
  }
}
```

### 2. Transformation Conditionnelle en Contrat

```javascript
// ✅ Ne créer le contrat QUE si paiement vraiment réussi
if (transactionStatus === 'SUCCESS' && subscriptionId) {
  console.log('🎉 Paiement confirmé ! Création du contrat...');
  
  // Mettre à jour la proposition
  await pool.query(`UPDATE subscriptions SET statut = 'paid'`);
  
  // Créer le contrat
  const nextPaymentDate = calculateNextPaymentDate(new Date(), periodicite);
  
  await pool.query(`
    INSERT INTO contracts (
      subscription_id, user_id, contract_number, product_name,
      status, amount, periodicite, start_date, next_payment_date,
      duration_years, payment_method
    ) VALUES (...)
  `);
  
  return res.json({
    success: true,
    message: 'Paiement effectué avec succès',
    contractCreated: true  // ✅ Contrat créé
  });
}
```

### 3. Gestion des Échecs

```javascript
// ❌ Solde insuffisant ou erreur
if (transactionStatus === 'FAILED') {
  return res.status(400).json({
    success: false,
    message: errorMessage || 'Le paiement a échoué. Vérifiez votre solde CorisMoney.',
    status: 'FAILED'
  });
}

// ⏳ Transaction en attente
if (transactionStatus === 'PENDING') {
  return res.status(202).json({
    success: true,
    message: 'Transaction en cours de traitement.',
    status: 'PENDING'
  });
}
```

---

## 📊 Flux Complet de Paiement

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Client saisit le code OTP                                │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Appel API CorisMoney paiementBien()                      │
│    Params: codePays, telephone, montant, codeOTP            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. CorisMoney traite la transaction                         │
│    → Vérifie le solde                                       │
│    → Débite le compte (si solde OK)                         │
│    → Retourne transactionId                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. ⏳ Attente de 2 secondes (traitement asynchrone)         │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. ✅ Vérification du statut réel                           │
│    Appel API: getTransactionStatus(transactionId)           │
└─────────────────┬───────────────────────────────────────────┘
                  │
        ┌─────────┴─────────┬──────────────┐
        ▼                   ▼              ▼
   ┌─────────┐         ┌────────┐     ┌─────────┐
   │ SUCCESS │         │ FAILED │     │ PENDING │
   └────┬────┘         └───┬────┘     └────┬────┘
        │                  │               │
        ▼                  ▼               ▼
┌───────────────┐  ┌──────────────┐  ┌─────────────┐
│ ✅ Créer      │  │ ❌ Erreur    │  │ ⏳ Attente  │
│ le contrat    │  │ "Solde       │  │ "Transaction│
│               │  │ insuffisant" │  │ en cours"   │
│ → Proposition │  │              │  │             │
│   devient     │  │ → Proposition│  │ → Garder en │
│   contrat     │  │   reste en   │  │   pending   │
│               │  │   attente    │  │             │
│ → Afficher    │  │              │  │             │
│   dans page   │  │ → Enregistré │  │             │
│   contrats    │  │   en BDD     │  │             │
│               │  │   avec statut│  │             │
│ → Calculer    │  │   FAILED     │  │             │
│   prochaine   │  │              │  │             │
│   échéance    │  │              │  │             │
└───────────────┘  └──────────────┘  └─────────────┘
```

---

## 🗄️ Structure de la Base de Données

### Table `contracts` (nouvelle)

```sql
CREATE TABLE contracts (
  id SERIAL PRIMARY KEY,
  subscription_id INTEGER UNIQUE,  -- Lien avec la proposition
  user_id INTEGER,
  contract_number VARCHAR(100) UNIQUE,  -- Ex: CORIS-SER-1738732800000
  product_name VARCHAR(100),
  status VARCHAR(50) DEFAULT 'active',  -- active, suspended, expired, cancelled
  amount DECIMAL(15, 2),
  periodicite VARCHAR(50),  -- mensuelle, trimestrielle, semestrielle, annuelle, unique
  start_date TIMESTAMP,
  next_payment_date TIMESTAMP,  -- NULL si paiement unique
  end_date TIMESTAMP,  -- Calculé automatiquement
  duration_years INTEGER,
  payment_method VARCHAR(50),  -- CorisMoney, Orange Money, Wave, etc.
  total_paid DECIMAL(15, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Table `payment_transactions` (mise à jour)

```sql
-- Ajout de la colonne error_message
ALTER TABLE payment_transactions 
ADD COLUMN IF NOT EXISTS error_message TEXT;

-- Les statuts possibles :
-- 'SUCCESS' : Paiement réussi
-- 'FAILED'  : Échec (solde insuffisant, etc.)
-- 'PENDING' : En attente de confirmation
```

---

## 📱 Intégration Flutter

### 1. Service de Gestion des Contrats

Fichier : `lib/services/contract_service.dart`

```dart
class ContractService {
  /// Récupère tous les contrats de l'utilisateur
  Future<Map<String, dynamic>> getContracts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/payment/contracts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    return json.decode(response.body);
  }
  
  /// Récupère les détails d'un contrat
  Future<Map<String, dynamic>> getContractDetails(int contractId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/payment/contracts/$contractId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    return json.decode(response.body);
  }
}
```

### 2. Page d'Affichage des Contrats

Fichier : `lib/features/client/presentation/screens/contracts_page.dart`

**Fonctionnalités :**
- ✅ Liste de tous les contrats actifs
- ✅ Statut de chaque contrat (Actif, Suspendu, Expiré)
- ✅ Montant et périodicité
- ✅ Prochaine date de paiement
- ✅ Statut du paiement :
  - 🟢 "À jour"
  - 🟠 "Échéance proche (7 jours)"
  - 🔴 "En retard"
- ✅ Nombre de paiements restants
- ✅ Historique des paiements

### 3. Page de Détails d'un Contrat

**Affiche :**
- Numéro de contrat
- Produit d'assurance
- Montant et périodicité
- Date de début et de fin
- Durée du contrat
- Prochain paiement
- Total payé
- Historique complet des paiements

---

## 🎯 Calcul des Prochaines Échéances

```javascript
function calculateNextPaymentDate(startDate, periodicite) {
  const nextDate = new Date(startDate);
  
  switch(periodicite?.toLowerCase()) {
    case 'mensuelle':
      nextDate.setMonth(nextDate.getMonth() + 1);
      break;
    case 'trimestrielle':
      nextDate.setMonth(nextDate.getMonth() + 3);
      break;
    case 'semestrielle':
      nextDate.setMonth(nextDate.getMonth() + 6);
      break;
    case 'annuelle':
      nextDate.setFullYear(nextDate.getFullYear() + 1);
      break;
    case 'unique':
    default:
      return null;  // Pas de prochaine échéance
  }
  
  return nextDate;
}
```

**Exemples :**
- Paiement unique : `next_payment_date = NULL`
- Mensuel (01/02/2026) : `next_payment_date = 01/03/2026`
- Trimestriel (01/02/2026) : `next_payment_date = 01/05/2026`
- Semestriel (01/02/2026) : `next_payment_date = 01/08/2026`
- Annuel (01/02/2026) : `next_payment_date = 01/02/2027`

---

## 🔍 Requêtes API

### 1. Récupérer tous les contrats

```http
GET /api/payment/contracts
Authorization: Bearer <token>

Response 200 OK:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "contract_number": "CORIS-SER-1738732800000",
      "product_name": "Coris Sérénité",
      "status": "active",
      "amount": 50000,
      "periodicite": "mensuelle",
      "start_date": "2026-02-05T10:00:00Z",
      "next_payment_date": "2026-03-05T10:00:00Z",
      "end_date": "2031-02-05T10:00:00Z",
      "duration_years": 5,
      "payment_method": "CorisMoney",
      "total_paid": 50000,
      "payments_remaining": 59,
      "payment_status": "À jour"
    }
  ],
  "total": 1
}
```

### 2. Récupérer les détails d'un contrat

```http
GET /api/payment/contracts/1
Authorization: Bearer <token>

Response 200 OK:
{
  "success": true,
  "data": {
    "id": 1,
    "contract_number": "CORIS-SER-1738732800000",
    "product_name": "Coris Sérénité",
    ...
    "payment_history": [
      {
        "transaction_id": "TXN-12345",
        "montant": 50000,
        "statut": "SUCCESS",
        "date": "2026-02-05T10:00:00Z"
      }
    ]
  }
}
```

---

## 📋 Checklist de Vérification

### Backend
- [x] Fonction `getTransactionStatus()` implémentée dans `corisMoneyService.js`
- [x] Vérification du statut après paiement dans `paymentRoutes.js`
- [x] Gestion des cas SUCCESS, FAILED, PENDING
- [x] Enregistrement en BDD avec le vrai statut
- [x] Fonction `calculateNextPaymentDate()` créée
- [x] Table `contracts` créée avec triggers
- [x] Routes `/api/payment/contracts` et `/api/payment/contracts/:id` ajoutées
- [x] Vue `active_contracts_details` créée

### Frontend (Flutter)
- [x] Service `ContractService` créé
- [x] Page `ContractsPage` créée
- [x] Page `ContractDetailPage` créée
- [x] Formatage des dates, montants, périodicités
- [x] Affichage des statuts avec couleurs
- [x] Calcul des paiements restants

### Base de Données
- [x] Script SQL `create_contracts_table.sql` créé
- [x] Colonne `error_message` ajoutée à `payment_transactions`
- [x] Index de performance ajoutés
- [x] Triggers pour `updated_at` et `end_date`

---

## 🚀 Déploiement

### 1. Créer la table contracts

```bash
psql -U postgres -d mycoris -f create_contracts_table.sql
```

### 2. Vérifier les migrations

```bash
# Vérifier que la table existe
psql -U postgres -d mycoris -c "\d contracts"

# Vérifier que la colonne error_message existe
psql -U postgres -d mycoris -c "\d payment_transactions"
```

### 3. Tester l'API

```bash
# Test 1 : Paiement avec solde suffisant
# → Devrait créer le contrat

# Test 2 : Paiement avec solde insuffisant
# → Devrait retourner FAILED, pas de contrat

# Test 3 : Récupérer les contrats
curl -H "Authorization: Bearer <token>" \
  http://localhost:5000/api/payment/contracts
```

---

## 🎉 Résultat Final

### Avant (Problème)
1. Client saisit OTP ✅
2. Solde insuffisant ⚠️
3. App dit "Paiement réussi" ❌
4. Contrat créé ❌
5. Client pense avoir payé ❌

### Après (Solution)
1. Client saisit OTP ✅
2. Solde insuffisant ⚠️
3. **Vérification du statut réel** ✅
4. **App dit "Solde insuffisant"** ✅
5. **Pas de contrat créé** ✅
6. **Transaction enregistrée comme FAILED** ✅
7. Client peut réessayer avec un compte approvisionné ✅

---

**Date de création** : 05/02/2026  
**Auteur** : Équipe MyCorisLife  
**Version** : 2.0 (Correction Critique)
