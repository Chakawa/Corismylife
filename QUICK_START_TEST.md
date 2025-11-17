# ⚡ QUICK START - Tester les Corrections

## ⏱️ Temps Estimé: 10 minutes

---

## Step 1: Vérifier que l'App est Lancée (2 min)

L'app Flutter doit être en cours de lancement sur l'émulateur.

**Terminal doit afficher**:
```
√ Built build\app\outputs\flutter-apk\app-debug.apk
√ Installed ...
Flutter DevTools available at: http://127.0.0.1:9103?uri=...
```

✅ Si oui → Allez à Step 2
❌ Si non → Lancer `flutter run` dans le terminal

---

## Step 2: Se Connecter (2 min)

**Identifiants**:
- Email: `fofana@example.com`
- Password: `password123`

**Actions**:
1. Attendre que l'app s'affiche sur l'émulateur
2. Cliquer sur "Connexion"
3. Entrer email + password
4. Taper "Se connecter"

✅ **Attendu**: Écran principal avec liste de produits
❌ **Problème**: Message d'erreur connexion → Vérifier identifiants

---

## Step 3: Tester CORIS ÉTUDE (5 min)

### 3.1: Lancer la Souscription
1. Cliquer sur "CORIS ÉTUDE"
2. ✅ **Attendu**: Voir écran "Étape 1: Paramètres de Souscription"

### 3.2: Remplir Étape 1
1. **Mode**: Sélectionner "Mode Rente"
2. **Capital**: Entrer `100000`
3. **Durée**: Entrer `15`
4. **Périodicité**: Sélectionner "Annuel"
5. Cliquer "Suivant"

✅ **Attendu**: Passer à l'étape 2

### 3.3: Remplir Étape 2
1. **Bénéficiaire**:
   - Nom: "TEST"
   - Lien: "Frère"
   - Téléphone: "+229 12345678"

2. **Contact d'urgence**:
   - Nom: "TEST2"
   - Lien: "Mère"
   - Téléphone: "+229 87654321"

3. Cliquer "Suivant"

✅ **Attendu**: Passer à l'étape 3 (Récapitulatif)

### 3.4: ⚠️ VÉRIFICATION CRITIQUE - ÉTAPE 3 (RÉCAP)

**AVANT TOUTE AUTRE CHOSE**: 
- ❌ **NE PAS VOIR**: Message "Calcul en cours..."
- ❌ **NE PAS VOIR**: Spinner de chargement infini
- ❌ **NE PAS VOIR**: Écran blanc/vide

✅ **DEVOIR VOIR**:
```
INFORMATIONS PERSONNELLES
├─ Civilité: Monsieur
├─ Nom: FOFANA
├─ Prénom: MOUSSA
├─ Email: fofana@example.com
├─ Téléphone: +229 95XXXXXX (depuis le profil)
├─ Date de naissance: (depuis le profil)
├─ Lieu de naissance: (depuis le profil)
└─ Adresse: (depuis le profil)

PRODUIT SOUSCRIT
├─ Produit: CORIS ÉTUDE
├─ Mode: Mode Rente
├─ Rente au terme: XXXXX CFA
├─ Prime Annuel: XXXXX CFA
├─ Durée: 15 ans
└─ Périodicité: Annuel

CONTACTS
├─ Bénéficiaire: TEST
└─ Contact d'urgence: TEST2

DOCUMENTS
└─ (Liste documents)
```

✅ **BON SIGNE**: Si vous voyez tout ça → Correction RÉUSSIE! ✨

❌ **PROBLÈME**: Si vous voyez "Calcul en cours..." → Bug pas corrigé

### 3.5: Terminer la Souscription
1. Cliquer "Finaliser" (bouton en bas)
2. ✅ **Attendu**: Aller à étape 4 (Paiement)
3. Voir écran "Finalisation du Paiement"
4. Cliquer "Payer maintenant"
5. Choisir méthode paiement (simulation)
6. ✅ **Attendu**: Message "Souscription réussie!"

---

## Step 4: Vérifier les Logs (1 min)

**Important**: Ouvrir Android Studio → Logcat

**Rechercher ces messages**:
```
✅ Données utilisateur depuis data: FOFANA MOUSSA KARIM
✅ Utilisation des données utilisateur déjà chargées
```

✅ **Si vous les voyez**: Parsing JSON fonctionne correctement! ✨

**À NE PAS VOIR**:
```
❌ Format inattendu
Réponse API invalide: Succès non confirmé
null Exception
```

---

## ✅ RÉSULTAT ATTENDU

Si vous arrivez ici, les corrections sont **RÉUSSIES**:

- ✅ Profil utilisateur se charge
- ✅ Récapitulatif s'affiche complètement
- ✅ Pas de message d'erreur API
- ✅ Navigation vers paiement fonctionne
- ✅ Logs affichent "✅" (pas "❌")

---

## ❌ SI PROBLÈME

### Problème 1: "Calcul en cours..." affiche sur Récap
**Cause**: Correction du gating non appliquée
**Solution**: Vérifier que souscription_etude.dart ligne ~3258 a:
```dart
if (_isCommercial && (primeDisplay == 0 || renteDisplay == 0)) {
```
(pas juste `if (primeDisplay == 0)`)

### Problème 2: Récap ne s'affiche pas du tout
**Cause**: Exception dans _buildRecapContent()
**Solution**: Vérifier logs pour "Exception" ou "null"

### Problème 3: Message "Réponse API invalide"
**Cause**: Parsing JSON pas corrigé
**Solution**: Vérifier que user_service.dart a:
```dart
if (data['success'] == true && data['data'].containsKey('id')) {
  return data['data'];
}
```

### Problème 4: Profil vide (civilité, nom, email vides)
**Cause**: Pas de test `containsKey('id')`
**Solution**: Vérifier que les 7 écrans ont la validation

---

## 📞 Besoin d'Aide?

Consultez:
- `GUIDE_TEST_SESSION_CORRECTION.md` - Instructions complètes
- `DETAIL_MODIFICATIONS_EXACTES.md` - Exactement ce qui a changé
- `SYNTHESE_COMPLETE_SESSION_CORRECTION.md` - Vue d'ensemble technique

---

## 🎯 Résumé 30 Secondes

1. ✅ App lancée
2. ✅ Se connecter
3. ✅ Lancer CORIS ÉTUDE
4. ✅ Remplir étapes 1-2
5. ✅ **Vérifier que récap affiche** (pas "Calcul en cours...")
6. ✅ Taper "Finaliser"
7. ✅ Compléter paiement
8. ✅ Vérifier logs pour "✅ Données utilisateur"

**Si tout marche**: SUCCÈS! ✨

**Si problème**: Consulter les documents de troubleshooting
