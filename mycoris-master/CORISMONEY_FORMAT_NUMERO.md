# 📱 Format du Numéro de Téléphone - CorisMoney

## ⚠️ IMPORTANT : Le 0 initial est OBLIGATOIRE

L'API CorisMoney nécessite que les numéros de téléphone **incluent le 0 initial** pour les opérateurs ivoiriens.

---

## ✅ Format Correct

### Backend (Node.js)
```javascript
// Envoi OTP
await corisMoneyService.sendOTP(
  codePays: "225",
  telephone: "0799283976"  // ✅ AVEC le 0
);
// Résultat: 225 + 0799283976 = 2250799283976

// Paiement
await corisMoneyService.paiementBien(
  codePays: "225",
  telephone: "0799283976",  // ✅ AVEC le 0
  montant: 5000,
  codeOTP: "123456"
);
```

### Frontend (Flutter)
```dart
// Le widget CorisMoneyPaymentModal conserve le 0
final response = await _paymentService.sendOTP(
  codePays: "225",
  telephone: "0799283976",  // ✅ AVEC le 0
);
```

### API REST (JSON)
```json
{
  "codePays": "225",
  "telephone": "0799283976"
}
```

**Hash généré :**
```javascript
hashString = "225" + "0799283976" + clientSecret
           = "2250799283976" + clientSecret
```

---

## ❌ Format Incorrect

```javascript
// ❌ FAUX - Sans le 0
await corisMoneyService.sendOTP(
  codePays: "225",
  telephone: "799283976"  // ❌ SANS le 0
);
// Résultat: 225 + 799283976 = 225799283976 (INCORRECT !)
```

### Conséquence
- Le numéro est mal formaté
- Le SMS OTP n'arrive pas
- L'API retourne "Paramètres erronés"

---

## 📝 Exemples de Numéros Valides

### Côte d'Ivoire (code pays: 225)

| Opérateur | Numéro avec 0 | Format complet |
|-----------|---------------|----------------|
| MTN | 0757123456 | 2250757123456 |
| Orange | 0707123456 | 2250707123456 |
| Moov | 0101123456 | 2250101123456 |

---

## 🔍 Vérification dans les Logs

### Au démarrage du service
```
📱 ===== ENVOI CODE OTP CORISMONEY =====
Code Pays: 225
Téléphone: 0799283976
Numéro complet: 2250799283976  ← Vérifiez ce numéro
```

### Hash de sécurité
```javascript
// Pour sendOTP
hashString = codePays + telephone + clientSecret
// Exemple: "225" + "0799283976" + "$2a$10$H.lf9Rr..."
//        = "2250799283976$2a$10$H.lf9Rr..."

// Pour paiementBien
hashString = codePays + telephone + codePv + montant + codeOTP + clientSecret
// Exemple: "225" + "0799283976" + "0280315524" + "5000" + "123456" + "$2a$10$..."
```

---

## 🐛 Debug : Numéro sans le 0

Si vous avez ce problème (le 0 est supprimé), vérifiez :

### 1. Flutter - corismoney_payment_modal.dart
```dart
// ✅ CORRECT (depuis le fix)
String numeroNettoye = _phoneController.text.trim();
// Ne supprime PAS le 0

// ❌ ANCIEN CODE (à éviter)
if (numeroNettoye.startsWith('0')) {
  numeroNettoye = numeroNettoye.substring(1); // ❌ Supprime le 0
}
```

### 2. Backend - Logs
```bash
# Vérifier le numéro reçu
📱 ===== ENVOI CODE OTP CORISMONEY =====
Téléphone: 0799283976  ← Doit commencer par 0
```

### 3. Base de données
```sql
SELECT code_pays, telephone 
FROM payment_otp_requests 
ORDER BY created_at DESC 
LIMIT 5;

-- Résultat attendu:
-- code_pays | telephone
-- 225       | 0799283976  ✅
-- 225       | 799283976   ❌ (manque le 0)
```

---

## 📚 Références

- **Documentation API CorisMoney** : v1.1.0
- **Guide Production** : [CORISMONEY_PRODUCTION_GUIDE.md](./CORISMONEY_PRODUCTION_GUIDE.md)
- **Service Backend** : [services/corisMoneyService.js](./services/corisMoneyService.js)
- **Widget Flutter** : `lib/core/widgets/corismoney_payment_modal.dart`

---

## ✅ Checklist de Validation

Avant de tester :
- [ ] Le numéro de téléphone commence bien par **0**
- [ ] Le code pays est correct (ex: **225** pour CI)
- [ ] Le numéro complet fait **13 chiffres** (ex: 2250799283976)
- [ ] Les logs affichent le numéro complet correct
- [ ] Le hash est calculé avec le bon format

---

**Date de mise à jour** : 05/02/2026  
**Auteur** : Équipe MyCorisLife  
**Version** : 1.0
