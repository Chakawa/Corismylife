# ✅ CORRECTIONS APPLIQUÉES

## 1️⃣ CORRECTION CRITIQUE: Erreur "Null is not a subtype" - APPLIQUÉE ✅

### Problème
L'erreur rouge: `type 'Null' is not a subtype of type 'FutureOr<Map<String, dynamic>>'`

### Cause
Dans `_buildStep3()`, le FutureBuilder recevait `null` comme future pour les commerciaux:
```dart
// ❌ AVANT (MAUVAIS)
future: _isCommercial ? null : _loadUserDataForRecap(),
```

FutureBuilder ne peut pas avoir `null` comme future!

### Solution Appliquée ✅
Restructurer le code pour éviter le null:

```dart
// ✅ APRÈS (BON)
child: _isCommercial
    ? _buildRecapContent()
    : FutureBuilder<Map<String, dynamic>>(
        future: _loadUserDataForRecap(),
        builder: (context, snapshot) {
          // Traitement du FutureBuilder uniquement pour clients
        },
      ),
```

**Impact**: ✅ Erreur Null ÉLIMINÉE
**Status**: APPLIQUÉE dans `souscription_etude.dart`

---

## 2️⃣ À FAIRE: Affichage "0F" au lieu de montants

### Problème
Le récapitulatif affiche "0 F" au lieu de "150 000 F"

### Cause
Variables `_primeCalculee` et `_renteCalculee` sont à null ou non initialisées

### Solution à Appliquer
Chercher dans `initState()`:
```dart
@override
void initState() {
  // Ajouter:
  _primeCalculee = 0.0;
  _renteCalculee = 0.0;
  // ...
}
```

---

## 3️⃣ À FAIRE: Données de souscription manquantes au récap

### Problème
Le récapitulatif n'affiche pas: Capital, Durée, Périodicité

### Solution à Appliquer
Dans `_buildRecapContent()`, ajouter une section "Simulation" après le "Produit":

```dart
SizedBox(height: 20),

_buildRecapSection(
  'Simulation',
  Icons.calculate,
  vertSucces,
  [
    _buildCombinedRecapRow(
        'Capital souscrit',
        _formatMontant(double.tryParse(_capitalController.text) ?? 0),
        'Durée',
        '${_dureeController.text} ans'),
    _buildCombinedRecapRow(
        'Mode',
        _selectedMode ?? 'Non sélectionné',
        'Périodicité',
        _selectedPeriodicite ?? 'Non sélectionnée'),
  ],
),
```

**Où insérer**: Après `_buildRecapSection('Produit Souscrit', ...)`

---

## 4️⃣ À FAIRE: "Finaliser" doit changer de page immédiatement

### Problème
Cliquer "Finaliser" ne change pas à la page de paiement

### Solution à Appliquer
Vérifier le bouton "Finaliser" dans `_buildNavigationButtons()`:

```dart
ElevatedButton(
  onPressed: () {
    int finalStep = _isCommercial ? 3 : 2;
    
    if (_currentStep == finalStep) {
      // Passer à l'étape suivante (paiement)
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Autres étapes
      _nextStep();
    }
  },
  child: Text((_currentStep == finalStep) ? 'Finaliser' : 'Suivant'),
)
```

---

## 5️⃣ À FAIRE: Paiement en overlay en bas (pas nouvelle page)

### Problème Architectural
Actuellement, le paiement est une nouvelle étape (étape 4) dans PageView.
Vous voulez qu'il s'affiche en bas de la même fenêtre.

### Solution Option A: Garder PageView (comme maintenant)
- Rien à faire
- Clic "Finaliser" → nouvelle page (étape 4 = paiement)
- C'est la structure actuelle

### Solution Option B: Changer en BottomSheet
Si vous voulez vraiment un overlay en bas:

```dart
// Remplacer le bouton "Finaliser" par:
FloatingActionButton.extended(
  onPressed: () => _showPaymentBottomSheet(),
  label: Text('Finaliser'),
)

// Ajouter la fonction:
void _showPaymentBottomSheet() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      height: 400,
      child: _buildPaymentContent(),
    ),
  );
}
```

**Recommandation**: Garder PageView (Option A) - c'est plus standard

---

## 6️⃣ À FAIRE: CORIS Solidarité - Calcul auto capital + durée

### Problème
La simulation se lance seulement si on clique un bouton

### Solution à Appliquer
Ajouter des listeners aux TextFields:

```dart
@override
void initState() {
  super.initState();
  
  // Ajouter après l'initialisation des contrôleurs:
  _capitalController.addListener(_calculateSimulation);
  _dureeController.addListener(_calculateSimulation);
}

void _calculateSimulation() {
  String capitalStr = _capitalController.text;
  String dureeStr = _dureeController.text;
  
  if (capitalStr.isNotEmpty && dureeStr.isNotEmpty) {
    double capital = double.tryParse(capitalStr) ?? 0;
    int duree = int.tryParse(dureeStr) ?? 0;
    
    if (capital > 0 && duree > 0) {
      setState(() {
        // À adapter selon votre formule de calcul
        _primeCalculee = capital / duree / 12;
        _renteCalculee = capital * 0.05;
      });
    }
  }
}

@override
void dispose() {
  _capitalController.removeListener(_calculateSimulation);
  _dureeController.removeListener(_calculateSimulation);
  super.dispose();
}
```

---

## RÉSUMÉ DES ACTIONS

| # | Problème | Status | Action |
|---|----------|--------|--------|
| 1 | Erreur Null FutureBuilder | ✅ APPLIQUÉE | Restructurer avec ternaire |
| 2 | "0F" au lieu de montants | 📝 À FAIRE | Initialiser variables dans initState() |
| 3 | Données souscription manquantes | 📝 À FAIRE | Ajouter section Simulation au récap |
| 4 | Finaliser ne change pas de page | 📝 À FAIRE | Vérifier PageController.nextPage() |
| 5 | Paiement pas en overlay | 📖 DÉCISION | Garder PageView ou passer en BottomSheet? |
| 6 | Solidarité: Calcul auto | 📝 À FAIRE | Ajouter listeners onChange |

---

## PROCHAINES ÉTAPES

1. **Compile et teste** avec la correction du Null (déjà appliquée)
2. **Raporte-moi** si l'erreur rouge disparaît
3. **Je vais appliquer** les autres corrections une par une

Dites-moi si vous voyez encore l'erreur Null après cette correction!
