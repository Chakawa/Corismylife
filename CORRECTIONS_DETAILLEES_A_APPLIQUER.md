# 📋 CORRECTIONS DÉTAILLÉES - Prêtes à Appliquer

## ✅ Correction #2: "0F" au lieu de montants

### Localisation
**Fichier**: `souscription_etude.dart`
**Fonction**: N'importe où dans la classe (chercher `initState()`)

### Avant
```dart
@override
void initState() {
  super.initState();
  
  _pageController = PageController(initialPage: 0);
  _animationController = AnimationController(
    duration: Duration(milliseconds: 500),
    vsync: this,
  );
  // ... autres initialisations
  // ❌ MANQUANT: _primeCalculee et _renteCalculee ne sont pas initialisées
}
```

### Après (À Ajouter)
```dart
@override
void initState() {
  super.initState();
  
  _pageController = PageController(initialPage: 0);
  _animationController = AnimationController(
    duration: Duration(milliseconds: 500),
    vsync: this,
  );
  // ... autres initialisations
  
  // ✅ AJOUTÉ: Initialiser les variables de calcul
  _primeCalculee = 0.0;
  _renteCalculee = 0.0;
}
```

### Ou Alternative
Si vous voulez que le récap affiche "Non calculé" au lieu de "0 F":

```dart
// Dans _buildRecapContent(), modifier le formatage:
String _formatMontantAffichage(double? amount) {
  if (amount == null || amount == 0) {
    return 'Non calculé';
  }
  // Formater le montant
  return _formatMontant(amount);
}
```

---

## ✅ Correction #3: Ajouter Capital et Durée au Récap

### Localisation
**Fichier**: `souscription_etude.dart`
**Fonction**: `_buildRecapContent()`
**Où**: Après la section "Produit Souscrit"

### Code à Ajouter

Trouvez cette section:
```dart
_buildRecapSection(
  'Produit Souscrit',
  Icons.school,
  vertSucces,
  [
    // ... contenu du produit
  ],
),

SizedBox(height: 20),
// ← AJOUTER ICI
```

Ajoutez ceci:
```dart
_buildRecapSection(
  'Paramètres de Souscription',
  Icons.calculate,
  bleuSecondaire,
  [
    _buildCombinedRecapRow(
        'Capital souscrit',
        _formatMontant(double.tryParse(_capitalController.text) ?? 0),
        'Durée',
        _dureeController.text.isNotEmpty ? '${_dureeController.text} ans' : 'Non définie'),
    _buildCombinedRecapRow(
        'Mode',
        _selectedMode ?? 'Non sélectionné',
        'Périodicité',
        _selectedPeriodicite ?? 'Non sélectionnée'),
    _buildRecapRow(
        'Date d\'effet',
        _dateEffetContrat != null
            ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
            : 'Non définie'),
  ],
),

SizedBox(height: 20),
// Continue avec le reste...
```

### Résultat
```
PARAMÈTRES DE SOUSCRIPTION
├─ Capital souscrit: 100 000 F    │ Durée: 15 ans
├─ Mode: Mode Rente              │ Périodicité: Annuel
└─ Date d'effet: 16/11/2025
```

---

## ✅ Correction #4: "Finaliser" Doit Changer de Page

### Localisation
**Fichier**: `souscription_etude.dart`
**Fonction**: `_buildNavigationButtons()`

### Le Problème
Actuellement, le code fait:
```dart
onPressed: () {
  int finalStep = _isCommercial ? 3 : 2;
  
  if (_currentStep == finalStep) {
    _nextStep();  // ← Appelle _nextStep()
  } else {
    _nextStep();
  }
},
```

**Vérifiez** que `_nextStep()` fait vraiment:
```dart
void _nextStep() {
  _pageController.nextPage(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

### Si Ça N'Marche Pas
Remplacez par ceci directement:
```dart
onPressed: () {
  int finalStep = _isCommercial ? 3 : 2;
  
  if (_currentStep == finalStep || _currentStep == finalStep + 1) {
    // On est à l'étape final, aller à la prochaine
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  } else {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
},
```

---

## ✅ Correction #5: Paiement en Overlay (OPTIONNEL)

### Localisation
**Fichier**: `souscription_etude.dart`
**Fonction**: Ajouter nouvelle fonction + modifier le bouton

### Actuellement
- Étape 3 = Récap
- Étape 4 = Paiement (nouvelle page)
- Clic "Finaliser" = PageView.nextPage()

### Si Vous Voulez un BottomSheet
**Remplacer** le bouton "Finaliser" dans `_buildNavigationButtons()`:

```dart
// Ancien:
ElevatedButton(
  onPressed: () { _nextStep(); },
  child: Text('Finaliser'),
)

// Nouveau:
ElevatedButton(
  onPressed: () {
    int finalStep = _isCommercial ? 3 : 2;
    if (_currentStep == finalStep) {
      // Au lieu de nextPage(), montrer le BottomSheet
      _showPaymentBottomSheet();
    } else {
      _nextStep();
    }
  },
  child: Text('Finaliser'),
)
```

**Ajouter** cette fonction:
```dart
void _showPaymentBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: blanc,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        color: blanc,
        child: ListView(
          controller: scrollController,
          children: [
            SizedBox(height: 20),
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: grisLeger,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(20),
              child: _buildPaymentContent(), // Réutiliser le contenu de _buildStep4()
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Note**: Cette approche nécessite d'extraire le contenu de `_buildStep4()` dans une fonction séparée.

---

## ✅ Correction #6: CORIS Solidarité - Calcul Auto

### Localisation
**Fichier**: `souscription_solidarite.dart` (si différent de étude)
**Fonction**: `initState()` + ajouter nouvelle fonction

### Avant
```dart
@override
void initState() {
  super.initState();
  
  _capitalController = TextEditingController();
  _dureeController = TextEditingController();
  // ❌ Pas de listeners
}
```

### Après
```dart
@override
void initState() {
  super.initState();
  
  _capitalController = TextEditingController();
  _dureeController = TextEditingController();
  
  // ✅ AJOUTÉ: Listeners pour calcul auto
  _capitalController.addListener(_calculateSimulation);
  _dureeController.addListener(_calculateSimulation);
}

// ✅ NOUVELLE FONCTION
void _calculateSimulation() {
  String capitalStr = _capitalController.text.trim();
  String dureeStr = _dureeController.text.trim();
  
  // Vérifier que les deux champs sont remplis
  if (capitalStr.isEmpty || dureeStr.isEmpty) {
    return;
  }
  
  // Convertir en nombres
  double? capital = double.tryParse(capitalStr);
  int? duree = int.tryParse(dureeStr);
  
  // Vérifier les valeurs
  if (capital == null || capital <= 0 || duree == null || duree <= 0) {
    return;
  }
  
  // Calculer selon votre formule
  setState(() {
    // Exemple: Prime = Capital / Durée / 12
    _primeCalculee = capital / duree / 12;
    
    // Exemple: Rente = Capital * 0.05
    _renteCalculee = capital * 0.05;
    
    // Calculer aussi capital au terme et autres
    _capitalAuTerme = capital + (_renteCalculee * duree); // Exemple
  });
  
  // Optionnel: Log pour debug
  debugPrint('Simulation calculée: Prime=$_primeCalculee, Rente=$_renteCalculee');
}

// ✅ AJOUTER au dispose()
@override
void dispose() {
  _capitalController.removeListener(_calculateSimulation);
  _dureeController.removeListener(_calculateSimulation);
  
  _capitalController.dispose();
  _dureeController.dispose();
  // ... autres dispose
  super.dispose();
}
```

### Résultat
```
Utilisateur tape capital: 100 000
        ↓
[onChange] _calculateSimulation() appelée
        ↓
setState() met à jour l'écran
        ↓
Résultats affichés en temps réel
```

---

## 📊 Ordre de Difficulté

| # | Correction | Temps | Difficulté | Dépendances |
|---|-----------|-------|-----------|------------|
| 1 | Erreur Null | 0 min | N/A | ✅ DÉJÀ FAIT |
| 2 | "0F" au lieu de montants | 5 min | ⭐ Très facile | Aucune |
| 3 | Capital/Durée au récap | 10 min | ⭐ Facile | Aucune |
| 4 | Finaliser change page | 5 min | ⭐ Facile | Aucune |
| 5 | Paiement en BottomSheet | 30 min | ⭐⭐ Moyen | Refactorisation |
| 6 | Solidarité calcul auto | 10 min | ⭐ Facile | Aucune |

---

## 🎯 Ordre d'Exécution Recommandé

1. **Testez la correction #1** (Null)
2. **Si OK**, appliquez:
   - #2 (5 min)
   - #3 (10 min)
   - #4 (5 min)
   - #6 (10 min)
3. **Optionnel**: #5 (BottomSheet)

**Temps total**: ~30 min (sans #5), ~60 min (avec #5)

---

Dites-moi quelle correction appliquer en premier!
