# 🎯 RÉPONSES DIRECTES À VOS 3 QUESTIONS

Date: 24 Février 2026

---

## ❓ QUESTION 1: "Quand je clique Wave, rien ne se passe"

### Pourquoi c'est arrivé ?

Le backend ne retournait pas l'URL Wave (`launchUrl`) au frontend Flutter à cause de:
1. ❌ URLs placeholder dans `.env` 
2. ❌ `WAVE_WEBHOOK_SECRET` manquant
3. ❌ Pages /wave-success et /wave-error n'existaient pas

### ✅ Ce qui a été FAIT

1. ✅ Créé les pages `/wave-success` et `/wave-error`
2. ✅ Vérifiez que `WAVE_API_KEY` est correct
3. ✅ Code Flutter attendait bien l'URL Wave

### 🔧 Comment FIXER maintenant

**Il faut remplacer les URLs placeholder dans `.env`:**

```powershell
# Ouvrez le fichier .env
notepad d:\CORIS\app_coris\mycoris-master\.env

# Remplacez:
WAVE_SUCCESS_URL=https://votre-domaine.com/wave-success
WAVE_ERROR_URL=https://votre-domaine.com/wave-error
WAVE_WEBHOOK_URL=https://votre-domaine.com/api/payment/wave/webhook

# Par VOTRE domaine réel:
WAVE_SUCCESS_URL=https://[VOTRE_URL]/wave-success
WAVE_ERROR_URL=https://[VOTRE_URL]/wave-error
WAVE_WEBHOOK_URL=https://[VOTRE_URL]/api/payment/wave/webhook
```

**Puis redémarrer:**
```powershell
# Appuyer Ctrl+C pour arrêter le serveur
# Puis:
npm start
```

**Maintenant ça devrait s'ouvrir !** ✅

---

## ❓ QUESTION 2: "Je dois donner quoi à Wave comme informations du compte merchant ?"

### 📋 Données à Fournir à Wave (Côté CORIS)

Wave demande ces informations pour créer le compte merchant:

```
================================================
INFORMATIONS D'ENTREPRISE
================================================
Nom Entreprise:        CORIS Assurance Vie
Type:                  Assurance
Pays:                  Côte d'Ivoire (CI)
Devise:                XOF (Franc CFA)

================================================
CONTACT PRINCIPAL
================================================
Email Entreprise:      contact@coris-assurance.ci ← À DÉCIDER
Téléphone:             +225 XX XX XX XX XX     ← À DÉCIDER
Nom Responsable:       [Nom de qui signe]      ← À DÉCIDER
Fonction:              Directeur/PDG

================================================
ADRESSE
================================================
Adresse:               [Adresse du siège]
Ville:                 [Ville]
Code Postal:           [Code]

================================================
DOCUMENTS À FOURNIR
================================================
- Registre de commerce
- Statuts de la société
- Pièce d'identité du responsable
- Certificat d'immatriculation
- Extrait Kbis (si applicable)

================================================
```

### 🔑 Clés Wave Fournies PAR Wave (Après création)

Une fois le compte créé, Wave fournira:

```
API KEY (PRODUCTION):
✅ wave_ci_prod_AqlIPJvDjeIPjMfZzfJIwlgFM3fMMhO8dXm0ma3Y5VgcMBkD6ZGFAkJG3qwGjfOC5zOwGZrbwMqNIiBFV88xC_NlhGzS8z5DVw

WEBHOOK SECRET:
⏳ À RÉCUPÉRER depuis Wave Dashboard
⏳ À METTRE DANS .env comme:
   WAVE_WEBHOOK_SECRET=xxxxx_le_secret_ici_xxxxx
```

### ✅ Résumé

**VOUS DONNEZ à Wave:**
- Données entreprise CORIS
- Documents
- Contact responsable

**Wave VOUS DONNE:**
- ✅ API Key (vous l'avez déjà!)
- ⏳ Webhook Secret (à récupérer et configurer)

---

## ❓ QUESTION 3: "Les URLs success/error, c'est où qu'on les crée ?"

### 🎯 Réponse Courte

**Les URLs sont composées de 2 parties:**

1. **Domaine de BASE** = Où tourne VOTRE serveur
   - Votre URL backend
   - À VOUS DE DÉCIDER

2. **Chemin** = `/wave-success` ou `/wave-error`
   - ✅ DÉJÀ CRÉÉ par nous dans le backend

### 📍 Exemples Concrets

#### Exemple 1: Développement Local
```env
# Votre domaine de base:
http://localhost:5000

# URLs composées:
WAVE_SUCCESS_URL=http://localhost:5000/wave-success
WAVE_ERROR_URL=http://localhost:5000/wave-error
WAVE_WEBHOOK_URL=http://localhost:5000/api/payment/wave/webhook
```

#### Exemple 2: Ngrok (Tunnel)
```env
# Votre domaine de base:
https://abc123.ngrok-free.app

# URLs composées:
WAVE_SUCCESS_URL=https://abc123.ngrok-free.app/wave-success
WAVE_ERROR_URL=https://abc123.ngrok-free.app/wave-error
WAVE_WEBHOOK_URL=https://abc123.ngrok-free.app/api/payment/wave/webhook
```

#### Exemple 3: Domaine Production
```env
# Votre domaine de base:
https://api.corisassurance.com

# URLs composées:
WAVE_SUCCESS_URL=https://api.corisassurance.com/wave-success
WAVE_ERROR_URL=https://api.corisassurance.com/wave-error
WAVE_WEBHOOK_URL=https://api.corisassurance.com/api/payment/wave/webhook
```

### 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│ WAVE (Service de Paiement)              │
└─────────────────────────────────────────┘
              ↓
        Utilisateur clique "Payer"
              ↓
┌─────────────────────────────────────────┐
│ Flutter App (Mobile)                    │
│ ├─ Appelle backend: POST /wave/create   │
│ └─ Reçoit: launchUrl de Wave            │
└─────────────────────────────────────────┘
              ↓
        Lance l'URL Wave
              ↓
┌─────────────────────────────────────────┐
│ Utilisateur effectue paiement sur Wave  │
└─────────────────────────────────────────┘
              ↓
   Après paiement, Wave envoie utilisateur à:
              ↓
┌─────────────────────────────────────────┐
│ Backend Node.js                         │
│ Routes:                                 │
│  GET /wave-success  ← page HTML        │
│  GET /wave-error    ← page HTML        │
│  POST /api/payment/wave/webhook        │
└─────────────────────────────────────────┘
              ↓
    Pages HTML affichées à l'utilisateur
```

### 🎁 Ce Qui a Été Créé

**✅ Les pages existent DÉJÀ:**

**`/wave-success`** → Page HTML verte avec ✅
```
Affiche: "Paiement Réussi!"
Ferme la fenêtre après 5 secondes
Teste l'URL: http://localhost:5000/wave-success
```

**`/wave-error`** → Page HTML rouge avec ❌
```
Affiche: "Paiement Échoué"
Bouton "Réessayer"
Teste l'URL: http://localhost:5000/wave-error
```

**`/api/payment/wave/webhook`** → Endpoint de sécurité
```
Reçoit les notify de Wave post-paiement
Valide la signature Wave
Met à jour la transaction en base
```

### ✅ Conclusion

**VOUS ne devez PAS créer les pages.**  
**NOUS les avons créées pour vous. ✅**

**VOUS devez JUSTE:**
1. Remplacer le domaine de base dans `.env`
2. Redémarrer le serveur
3. Wave utilisera ces URLs automatiquement

---

## 📊 SYNTHÈSE DES 3 RÉPONSES

| Question | Réponse | Status |
|----------|---------|--------|
| **Q1: Pourquoi Wave ne s'ouvre pas** | URLs placeholder dans .env | ❌ À FIXER |
| **Q2: Données pour merchant Wave** | Entreprise CORIS + documents | ✅ À FAIRE UNE FOIS |
| **Q3: Où créer success/error** | Déjà créé en backend ✅ | ✅ DÉJÀ FAIT |

---

## 🚀 ACTIONS FINALES (5 minutes)

1. **Ouvrir `.env`**
2. **Remplacer les URLS:**
   ```env
   WAVE_SUCCESS_URL=[VOTRE_URL]/wave-success
   WAVE_ERROR_URL=[VOTRE_URL]/wave-error
   WAVE_WEBHOOK_URL=[VOTRE_URL]/api/payment/wave/webhook
   ```
3. **Ajouter le Webhook Secret** (si vous l'avez)
4. **Redémarrer npm start**
5. **Tester un paiement Wave**

✅ **C'est tout!** Wave devrait fonctionner maintenant.

---

**Document: RÉPONSES DIRECTES**  
**Date: 24/02/2026**  
**Urgence: HAUTE - À faire maintenant**
