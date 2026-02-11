# 🚀 Guide de Test - Système de Paiement Complet

## 📋 Ce qui a été amélioré

### ✅ 1. Sauvegarde Complète API
- **Avant:** Seules les données de base étaient sauvegardées
- **Maintenant:** TOUTE la réponse JSON de CorisMoney est stockée dans `api_response` (JSONB)
- **Avantage:** Audit complet, debugging facilité, conformité réglementaire

### ✅ 2. SMS de Confirmation Automatique
- **Avant:** Aucune notification après paiement
- **Maintenant:** SMS envoyé automatiquement au client après paiement réussi
- **Message:** "Bonjour [Nom], votre paiement de [Montant] FCFA a été effectué avec succès ! Votre contrat [Numéro] est maintenant VALIDE."

### ✅ 3. Statut Contrat "valid"
- **Avant:** Statut "active" (confus)
- **Maintenant:** Statut "valid" pour les contrats payés
- **Clarté:** Distinction claire entre propositions et contrats validés

---

## 🧪 Test Rapide (5 minutes)

### Étape 1: Démarrer le serveur
```powershell
cd d:\CORIS\app_coris\mycoris-master
npm start
```

### Étape 2: Lancer le test complet
**Dans un NOUVEAU terminal PowerShell:**
```powershell
cd d:\CORIS\app_coris\mycoris-master
node test-systeme-complet.js
```

### Étape 3: Suivre le processus
1. Le test se connecte automatiquement
2. Il envoie un OTP au **226-61347475**
3. **Vous devez entrer le code OTP** reçu par SMS
4. Le système traite le paiement
5. **Vérification automatique:**
   - ✅ Transaction sauvegardée avec JSON complet
   - ✅ Contrat créé avec statut "valid"
   - ✅ SMS de confirmation envoyé

---

## 📊 Que vérifier après le test ?

### 1. Console du serveur Node.js
Vous devriez voir :
```
✅ Transaction enregistrée (ID: XXX)
🎉 Paiement confirmé ! Transformation de la proposition en contrat...
✅ Contrat créé avec succès !
✅ SMS de confirmation envoyé au client
```

### 2. SMS reçu
Le client devrait recevoir :
```
Bonjour FOFANA CHAKA, votre paiement de 100 FCFA a été effectué 
avec succès ! Votre contrat CORIS-XXX-XXXXXXX est maintenant 
VALIDE. Merci de votre confiance. CORIS Assurance
```

### 3. Base de données
Le test affiche automatiquement :
- ✅ Transaction avec `api_response` (JSON complet)
- ✅ Contrat avec statut `valid`
- ✅ Toutes les données CorisMoney sauvegardées

---

## 🔍 Vérification Manuelle BDD (Optionnel)

```sql
-- Voir la dernière transaction avec réponse API complète
SELECT 
  id,
  transaction_id,
  montant,
  statut,
  api_response,
  created_at
FROM payment_transactions
ORDER BY created_at DESC
LIMIT 1;

-- Voir le JSON détaillé
SELECT 
  transaction_id,
  api_response->>'statut' AS api_statut,
  api_response->>'montant' AS api_montant,
  api_response->>'nom' AS client_nom,
  api_response
FROM payment_transactions
WHERE api_response IS NOT NULL
ORDER BY created_at DESC
LIMIT 1;
```

---

## 📁 Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `routes/paymentRoutes.js` | ✅ Import `sendSMS`, sauvegarde `api_response`, envoi SMS |
| `add_api_response_column.sql` | ✅ Script migration JSONB |
| `install_api_response_quick.ps1` | ✅ Installation automatique |
| `test-systeme-complet.js` | ✅ Test validation complète |

---

## 🎯 Checklist Finale

Après avoir lancé `test-systeme-complet.js`, vérifiez :

- [ ] ✅ Connexion utilisateur réussie
- [ ] ✅ OTP envoyé au 226-61347475
- [ ] ✅ Code OTP entré et validé
- [ ] ✅ Paiement traité avec succès
- [ ] ✅ Transaction sauvegardée avec `api_response` (JSONB)
- [ ] ✅ Contrat créé avec statut `valid`
- [ ] ✅ SMS de confirmation reçu sur le téléphone

---

## 🚨 En cas de problème

### Serveur ne démarre pas
```powershell
# Vérifier si le port 5000 est libre
netstat -ano | findstr :5000

# Tuer le processus si nécessaire
taskkill /F /PID <PID>
```

### Colonne api_response manquante
```powershell
# Réexécuter la migration
.\install_api_response_quick.ps1
```

### SMS non reçu
- Vérifier le token SMS dans `.env`
- Consulter les logs du serveur pour les erreurs d'envoi
- Le paiement est QUAND MÊME validé (SMS non bloquant)

---

## 📞 Support

**Fichiers de référence:**
- Documentation complète: `AMELIORATION_PAIEMENT_COMPLETE.md`
- Tests CorisMoney: `GUIDE_TEST_CORISMONEY.md`
- Configuration: `.env`

**Contacts API:**
- CorisMoney: https://testbed.corismoney.com
- SMS letexto: https://apis.letexto.com

---

## 🎉 Conclusion

Si tous les ✅ ci-dessus sont validés, votre système est **OPÉRATIONNEL** avec :
1. ✅ Audit trail complet (JSON sauvegardé)
2. ✅ Notifications clients automatiques (SMS)
3. ✅ Statuts clairs ("valid" = contrat payé)

**Le système est prêt pour la production !** 🚀
