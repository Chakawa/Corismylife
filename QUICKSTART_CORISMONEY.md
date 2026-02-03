# 🚀 Guide de Démarrage Rapide - CorisMoney

## ⚡ Mise en route en 5 minutes

### Étape 1: Configuration (2 min)

1. **Ouvrez le fichier `.env`** dans `mycoris-master/`

2. **Ajoutez vos identifiants CorisMoney** (fournis par CorisMoney):
```env
CORIS_MONEY_CLIENT_ID=votre_client_id
CORIS_MONEY_CLIENT_SECRET=votre_secret
CORIS_MONEY_CODE_PV=votre_code_pv
```

3. **Sauvegardez le fichier**

### Étape 2: Migration de la base de données (1 min)

```bash
cd mycoris-master
node scripts/run_corismoney_migration.js
```

✅ Vous devriez voir: "Migration terminée avec succès !"

### Étape 3: Redémarrer le serveur (1 min)

```bash
# Dans le terminal du backend
cd mycoris-master
npm start
```

Vérifiez que vous voyez dans les logs:
```
✅ Connexion PostgreSQL établie avec succès
🚀 Serveur démarré sur le port 5000
```

### Étape 4: Tester l'intégration (1 min)

```bash
# Dans un nouveau terminal
cd mycoris-master
node test_corismoney_integration.js
```

Vous verrez les résultats des tests automatiques.

---

## 💡 Utilisation dans le frontend

### Option 1: Ajouter le bouton de paiement dans une page existante

**Exemple: Dans la page de souscription**

```jsx
import CorisMoneyPaymentModal from '../components/CorisMoneyPaymentModal';

// Dans votre composant
const [showPayment, setShowPayment] = useState(false);

// Dans votre JSX, ajoutez le bouton
<button onClick={() => setShowPayment(true)}>
  💳 Payer avec CorisMoney
</button>

// Ajoutez le composant modal
<CorisMoneyPaymentModal
  isOpen={showPayment}
  onClose={() => setShowPayment(false)}
  onPaymentSuccess={(result) => {
    alert('Paiement réussi! ID: ' + result.transactionId);
    // Rafraîchir la page ou rediriger
  }}
  montant={50000}
  description="Paiement de prime d'assurance"
/>
```

### Option 2: Page de démonstration

Une page de démonstration est disponible:
```
dashboard-admin/src/pages/PaymentExample.jsx
```

Pour l'ajouter au menu, modifiez votre routing.

---

## 🧪 Test rapide avec Postman

### 1. Obtenir un token d'authentification

**POST** `http://localhost:5000/api/auth/login`

Body:
```json
{
  "email": "admin@coris.ci",
  "password": "Admin@2024"
}
```

Copiez le `token` de la réponse.

---

### 2. Envoyer un code OTP

**POST** `http://localhost:5000/api/payment/send-otp`

Headers:
```
Authorization: Bearer VOTRE_TOKEN
Content-Type: application/json
```

Body:
```json
{
  "codePays": "225",
  "telephone": "0102030405"
}
```

---

### 3. Effectuer le paiement

**POST** `http://localhost:5000/api/payment/process-payment`

Headers:
```
Authorization: Bearer VOTRE_TOKEN
Content-Type: application/json
```

Body:
```json
{
  "codePays": "225",
  "telephone": "0102030405",
  "montant": 1000,
  "codeOTP": "CODE_RECU_PAR_SMS",
  "description": "Test de paiement"
}
```

---

## ❓ FAQ Rapide

### Q: Où trouver mes identifiants CorisMoney?
**R:** Contactez votre représentant commercial CorisMoney ou le support technique.

### Q: Puis-je tester sans avoir de compte CorisMoney?
**R:** Non, vous devez avoir un compte marchand CorisMoney pour tester. Demandez un compte de test (testbed).

### Q: Le code OTP n'arrive pas
**R:** 
- Vérifiez que le numéro de téléphone est bien enregistré sur CorisMoney
- Assurez-vous d'utiliser l'environnement testbed pour les tests
- Contactez le support CorisMoney si le problème persiste

### Q: J'obtiens "Identifiants non configurés"
**R:** Vérifiez que vous avez bien modifié le fichier `.env` et redémarré le serveur.

### Q: Comment passer en production?
**R:** 
1. Changez `CORIS_MONEY_BASE_URL` vers l'URL de production
2. Utilisez vos identifiants de production (pas de test)
3. Testez complètement en environnement de staging
4. Documentez le plan de rollback
5. Lancez!

---

## 📞 Support

- **Documentation complète:** `INTEGRATION_CORISMONEY.md`
- **Code source backend:** `mycoris-master/services/corisMoneyService.js`
- **Code source frontend:** `dashboard-admin/src/components/CorisMoneyPaymentModal.jsx`
- **Tests:** `mycoris-master/test_corismoney_integration.js`

---

## ✅ Checklist de vérification

Avant de déployer en production:

- [ ] Variables `.env` configurées
- [ ] Migration de la base de données exécutée
- [ ] Serveur redémarré
- [ ] Tests automatiques passent
- [ ] Test manuel de bout en bout effectué
- [ ] Interface utilisateur testée sur mobile et desktop
- [ ] Plan de rollback préparé
- [ ] Équipe formée sur le processus de paiement
- [ ] Support CorisMoney informé du lancement

---

**Bon courage! 🚀**

Si vous rencontrez des problèmes, consultez la documentation complète dans `INTEGRATION_CORISMONEY.md` ou les logs du serveur.
