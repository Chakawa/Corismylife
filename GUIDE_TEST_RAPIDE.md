# 🚀 GUIDE RAPIDE - LANCER ET TESTER

**Durée totale**: ~10 minutes

---

## 1️⃣ LANCER L'APP (2 min)

```bash
# Terminal PowerShell
cd d:\CORIS\app_coris\mycorislife-master
flutter run
```

**Attendre**: Compilation + démarrage émulateur (~2 min)

**Résultat attendu**: 
- App lance avec splash screen CORIS
- Écran de connexion apparaît
- ✅ PAS D'ERREUR CRASH

---

## 2️⃣ TEST FLUX CLIENT (3 min)

### A. Connexion Client
```
Email: fofana@example.com (ou votre compte client)
Mot de passe: (votre mot de passe)
→ Cliquer "Connexion"
```

**Attendre** le chargement du profil

### B. Sélectionner ÉTUDE
```
Home → Produits → CORIS ÉTUDE
```

### C. Remplir Étape 1 (Paramètres)
```
- Âge parent: 35 (par exemple)
- Âge enfant: 5
- Mode: Mode Prime (ou Rente)
- Périodicité: Mensuel
- Montant: 10000
→ Cliquer "Suivant"
```

### D. Remplir Étape 2 (Bénéficiaires)
```
- Bénéficiaire: Nom du bénéficiaire
- Lien parenté: Enfant
- Contact d'urgence: Nom + Téléphone
→ Cliquer "Suivant"
```

### E. Vérifier Étape 3 (Récap)
```
✅ DOIT AFFICHER:
  - Informations Personnelles (OK)
  - Produit Souscrit (OK)
  - ✨ PARAMÈTRES DE SOUSCRIPTION (NOUVEAU!)
  - Contacts (OK)
  
❌ DOIT PAS AFFICHER:
  - Erreur "Null is not a subtype..."
  - "0F" pour les montants
  - "Calcul en cours..."
```

### F. Finaliser
```
→ Cliquer "Finaliser"

✅ DOIT AFFICHER:
  - Page de paiement
  - ❌ PAS D'ERREUR

❌ DOIT PAS:
  - Crash avec erreur Null
  - Rester sur récap sans rien faire
```

**✅ TEST CLIENT RÉUSSI** si pas d'erreur Null

---

## 3️⃣ TEST FLUX COMMERCIAL (3 min)

### A. Connexion Commercial
```
Email: commercial@example.com
Mot de passe: (mot de passe commercial)
→ Cliquer "Connexion"
```

### B. Sélectionner ÉTUDE
```
Home → Produits → CORIS ÉTUDE
```

### C. Étape 0 (Infos Client) ⭐ SPÉCIFIQUE AU COMMERCIAL
```
- Civilité: M./Mme
- Nom: Tester Nom
- Prénom: Tester Prenom
- Email: test@example.com
- Téléphone: +225XXXXXXXXXX
- Date naissance: 01/01/1985
- Lieu naissance: Abidjan
- Adresse: Rue Test
→ Cliquer "Suivant"
```

### D. Étape 1 (Paramètres)
```
- Âge enfant: 5
- Mode: Mode Prime
- Périodicité: Mensuel
- Montant: 10000

⭐ IMPORTANT: 
Les montants Prime et Rente DOIVENT se calculer automatiquement
(Vous ne devez pas avoir de champ "Montant" à remplir)

→ Cliquer "Suivant"
```

### E. Étape 2 (Bénéficiaires)
```
- Bénéficiaire: Nom
- Lien parenté: Enfant
- Contact d'urgence: Nom + Téléphone
→ Cliquer "Suivant"
```

### F. Étape 3 (Récap) ⭐ CRITIQUE
```
✅ DOIT AFFICHER:
  - Informations Personnelles DU CLIENT
  - Produit Souscrit (ÉTUDE)
  - ✨ PARAMÈTRES DE SOUSCRIPTION
  - Les montants calculés (Prime + Rente)
  - Contacts (Bénéficiaire + Urgence)
  
❌ DOIT PAS AFFICHER:
  - Erreur "Null is not a subtype..."
  - "Calcul en cours..."
  - Montants = 0 ou vides
```

### G. Finaliser
```
→ Cliquer "Finaliser"

✅ DOIT AFFICHER:
  - Page de paiement
  - ❌ PAS D'ERREUR

❌ DOIT PAS:
  - Crash avec erreur Null
  - Rester bloqué sur récap
```

**✅ TEST COMMERCIAL RÉUSSI** si pas d'erreur Null et montants affichés

---

## 4️⃣ TEST RAPIDE DES 6 PRODUITS (2 min)

Répéter **rapidement** avec les 6 produits:

```
Home → Produits → (Choisir produit) → Remplir Étape 1
→ Cliquer "Suivant"
→ Vérifier que RÉCAP S'AFFICHE (pas d'erreur Null)
→ Retour (bouton "Précédent")
```

**Produits à tester**:
- ✅ ÉTUDE
- ✅ FAMILIS
- ✅ SÉRÉNITÉ
- ✅ RETRAITE
- ✅ FLEX
- ✅ ÉPARGNE

**Résultat attendu pour chaque**:
- ✅ Pas d'erreur Null
- ✅ Récap s'affiche
- ✅ Pas de "0F"

---

## 5️⃣ RAPPORT FINAL (1 min)

### Si TOUT MARCHE ✅

```
Parfait! Toutes les corrections fonctionnent:

✅ Pas d'erreur Null dans aucun produit
✅ Récap s'affiche correctement pour client ET commercial
✅ Les montants s'affichent (pas "0F")
✅ Les 6 produits fonctionnent
✅ Bouton Finaliser navigue vers paiement

L'app est PRÊTE POUR PRODUCTION!
```

### Si ERREUR ❌

```
Prendre NOTE de:

1. Quel produit? (ÉTUDE, FAMILIS, etc.)
2. Quel flux? (Client ou Commercial)
3. Quel message d'erreur exact?
4. Screenshot si possible
5. À quel moment? (Étape 1, 2, 3, Récap?)

Exemple à envoyer:
"Erreur trouvée dans FAMILIS flux client:
 Étape 3 (Récap) crash avec:
 'type 'Null' is not a subtype of type 'FutureOr<Map<String, dynamic>>''
 Screenshot: [...]"
```

---

## 📋 CHECKLIST FINAL

```
AVANT DE CLIQUER "Finaliser":

☐ Email et mot de passe corrects
☐ Étapes 1-2 remplies correctement
☐ Pas d'erreurs rouges sur l'écran
☐ Étape 3 (Récap) s'affiche sans crash
☐ Montants affichés (pas "0F")
☐ Tous les champs visibles

APRÈS "Finaliser":

☐ Pas de crash Null
☐ Page paiement s'affiche
☐ Possibilité de revenir (bouton Précédent)
```

---

## 🆘 TROUBLESHOOTING RAPIDE

**Problème**: App crash au démarrage
```
Solution: flutter clean && flutter run
```

**Problème**: "Erreur lors du chargement du profil"
```
Solution: Vérifier connexion internet + accès API
```

**Problème**: Page blanche après "Finaliser"
```
Solution: Attendre 3-5 sec (chargement paiement)
```

**Problème**: "Null is not a subtype..." TOUJOURS
```
Solution: Vérifier que tous les fichiers sont modifiés
          flutter analyze
```

---

## ⏱️ TIMING

```
Setup:          1-2 min (compilation)
Test Client:    3 min (con + remplir + vérif)
Test Commercial: 3 min (con + remplir + vérif)
Test 6 produits: 2 min (rapide pour chacun)
Rapport:        1 min (noter résultats)

TOTAL:          ~10 minutes
```

---

**🚀 C'est parti! Lancez l'app et testez maintenant!**

```bash
flutter run
```

*Bonne chance! 🎉*
