# Checklist de Vérification Post-Correction

## 1️⃣ Test du Flux Client - CORIS ÉTUDE

### Avant de Commencer
- [ ] Assurer que l'émulateur Android/iOS est bien lancé
- [ ] Assurer que le backend est accessible à `http://10.0.2.2:5000/api` (ou autre URL configurée)

### Étape 1: Login avec un Compte Existant
- [ ] Naviguer vers l'écran de connexion
- [ ] Entrer les identifiants: `Email: fofana@example.com` + `Password: password123`
- [ ] Vérifier que la connexion réussit

### Étape 2: Lancer la Souscription CORIS ÉTUDE
- [ ] Cliquer sur "CORIS ÉTUDE" depuis l'écran principal
- [ ] Attendre le chargement initial (spinner)

### Étape 3: Remplir les Paramètres (Étape 1)
- [ ] Sélectionner un mode (Mode Rente ou Mode Prime)
- [ ] Entrer le capital: `100000` CFA
- [ ] Entrer la durée: `15` ans
- [ ] Sélectionner la périodicité: `Annuel`
- [ ] Cliquer sur "Suivant"

### Étape 4: Remplir les Contacts (Étape 2)
- [ ] Entrer les infos bénéficiaire
- [ ] Entrer les infos contact d'urgence
- [ ] Cliquer sur "Suivant"

### Étape 5: Vérifier le Récapitulatif (Étape 3)
- [ ] ⚠️ **POINT CRITIQUE**: Vérifier qu'il n'y a PAS le message "Calcul en cours..."
- [ ] ✅ **Attendu**: Voir le récapitulatif complet avec:
  - Civilité: Monsieur
  - Nom: FOFANA
  - Prénom: MOUSSA
  - Email: fofana@example.com
  - Téléphone: +229 95XXXXXX (depuis profil)
  - Date de naissance: (depuis profil)
  - Lieu de naissance: (depuis profil)
  - Adresse: (depuis profil)
  - Produit: CORIS ÉTUDE
  - Mode: (Mode Rente ou Prime selon choix)
  - Prime/Rente: (valeurs calculées)
  - Durée: 15 ans
  - Périodicité: Annuel
  - Bénéficiaire
  - Contact d'urgence
  - Documents
- [ ] ⚠️ **LOGS À VÉRIFIER** (Ouvrir Logcat/Console):
  - Chercher: `✅ Données utilisateur depuis data: FOFANA MOUSSA`
  - Ne PAS voir: `❌ Format inattendu` ou `Réponse API invalide`
- [ ] Bouton en bas: "Finaliser" (pas "Paiement" ou autre)
- [ ] Cliquer sur "Finaliser"

### Étape 6: Paiement (Étape 4)
- [ ] ✅ **Attendu**: Voir l'écran "Finalisation du Paiement"
- [ ] Voir le montant à payer
- [ ] Cliquer sur "Payer maintenant"
- [ ] Choisir une méthode de paiement (simulation)
- [ ] Compléter le paiement

### Résultat Attendu
- [ ] ✅ Message de succès: "Souscription réussie!"
- [ ] ✅ Redirection vers une page de confirmation

---

## 2️⃣ Test du Flux Commercial - CORIS ÉTUDE

### Avant de Commencer
- [ ] Créer/utiliser un compte commercial
- [ ] Se connecter avec les identifiants commerciaux

### Étape 1: Lancer la Souscription CORIS ÉTUDE
- [ ] Cliquer sur "CORIS ÉTUDE"

### Étape 2: Infos Client (Étape 0 - Commercial Only)
- [ ] Remplir les données du client:
  - Civilité: Monsieur/Madame
  - Nom: TEST
  - Prénom: CLIENT
  - Email: test@example.com
  - Téléphone: +229 12345678
  - Lieu de naissance: Cotonou
  - Adresse: Rue Test 123
  - Pièce d'identité: Télécharger une image
- [ ] Cliquer "Suivant"

### Étape 3: Prime/Rente (Étape 1)
- [ ] Sélectionner Mode: Mode Rente
- [ ] Entrer Capital: 100000
- [ ] Vérifier que Prime et Rente se CALCULENT (voir les valeurs apparaître)
- [ ] Vérifier Durée: 15 ans
- [ ] Vérifier Périodicité: Annuel
- [ ] Cliquer "Suivant"

### Étape 4: Contacts (Étape 2)
- [ ] Remplir bénéficiaire et contact d'urgence
- [ ] Cliquer "Suivant"

### Étape 5: Récapitulatif (Étape 3) - COMMERCIAL
- [ ] ⚠️ **POINT CRITIQUE**: Vérifier que le récap affiche correctement
- [ ] ✅ **Attendu**: Voir les données du client saisies (TEST, CLIENT, etc.)
- [ ] ✅ **Attendu**: Voir Prime et Rente calculées
- [ ] ⚠️ **Éviter**: Message "Calcul en cours..." (doit avoir les valeurs)
- [ ] Bouton: "Finaliser"
- [ ] Cliquer "Finaliser"

### Étape 6: Paiement (Étape 4)
- [ ] Voir écran paiement
- [ ] Cliquer "Payer maintenant"
- [ ] Compléter paiement

### Résultat Attendu
- [ ] ✅ Message de succès
- [ ] ✅ Confirmation visible

---

## 3️⃣ Tests Rapides pour Autres Produits

### Tester Rapidement: CORIS FAMILIS
- [ ] Client: Remplir, vérifier récap affiche sans "Calcul en cours"
- [ ] Commercial: Remplir, vérifier Prime calculée

### Tester Rapidement: CORIS RETRAITE
- [ ] Client: Vérifier récap affiche profil correctement

### Tester Rapidement: CORIS FLEX
- [ ] Client: Vérifier pas d'erreur API

### Tester Rapidement: CORIS SÉRÉNITÉ
- [ ] Client: Vérifier récap visible

### Tester Rapidement: CORIS SOLIDARITÉ
- [ ] Client: Vérifier pas de gating message

### Tester Rapidement: CORIS ÉPARGNE
- [ ] Client: Vérifier affichage complet

---

## 4️⃣ Logs à Chercher (Important!)

### ✅ BONS LOGS (Comportement Attendu)
```
✅ Données utilisateur depuis data: FOFANA MOUSSA KARIM
✅ Utilisation des données utilisateur déjà chargées
I/Flutter: Profile loaded: {id: 3, civilite: Monsieur, nom: FOFANA, ...}
```

### ❌ MAUVAIS LOGS (Problèmes)
```
❌ Format inattendu: ...
Réponse API invalide: Succès non confirmé
❌ Exception: null
null Exception: Null check operator used on a null value
I/Flutter: Future not completed yet but rebuilding...
```

### 🔍 LOGS À NOTER
- Toute ligne avec `_loadUserDataForRecap`
- Toute ligne avec `getProfile()`
- Toute ligne avec `primeDisplay` ou `renteDisplay`
- Toute ligne concernant `_buildRecapContent`

---

## 5️⃣ Problèmes Possibles et Solutions

### Problème: "Calcul en cours..." n'apparaît pas (Comportement Normal)
- **Cause**: Client n'a pas de prime/rente à calculer
- **Attendu**: Récap affiche sans calcul
- **Solution**: C'est correct!

### Problème: "Calcul en cours..." apparaît et persiste (Anomalie)
- **Cause**: Commercial n'a pas complété l'étape 1 (calcul pas lancé)
- **Solution**: Vérifier que l'étape 1 calcule bien Prime et Rente

### Problème: Récap ne s'affiche pas du tout (Blocker)
- **Cause**: Possible erreur dans _buildRecapContent()
- **Solution**: Vérifier logs pour exception

### Problème: Profil ne se charge pas (Blocker)
- **Logs**: Chercher `❌ Format inattendu`
- **Cause**: API retourne format non reconnu
- **Solution**: Vérifier que getProfile() couvre tous les cas

### Problème: Bouton "Finaliser" n'existe pas
- **Cause**: Logique du nom du bouton incorrecte
- **Solution**: Vérifier `_currentStep` et `finalStep`

---

## 6️⃣ Checklist Post-Test

- [ ] Tous les logs montrent "✅" (pas de "❌")
- [ ] Récapitulatif s'affiche correctement pour clients
- [ ] Récapitulatif s'affiche avec calculs pour commerciaux
- [ ] Bouton "Finaliser" navigue vers paiement
- [ ] Tous les 7 produits testés rapidement
- [ ] Pas de crashes ou exceptions
- [ ] Profil utilisateur affiche correctement

---

## 7️⃣ Si Tout Marche ✅

Indiquer au développeur:
- ✅ Corrections appliquées avec succès
- ✅ Tous les tests passent
- ✅ Pas de régressions observées
- ✅ Prêt pour production

## Si Quelque Chose ne Marche ❌

Indiquer:
- ❌ Quel produit échoue (ÉTUDE, FAMILIS, etc.)
- ❌ Quel flux échoue (CLIENT, COMMERCIAL)
- ❌ Quel message d'erreur exactement
- ❌ Screenshot du problème
- ❌ Logs pertinents (grep pour "❌" ou "Exception")
