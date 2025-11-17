# 🔴 PROBLÈMES SIGNALÉS + SOLUTIONS

## Problème 1: Erreur "type 'Null' is not a subtype of type 'FutureOr<Map<String, dynamic>>'"

**Cause**: Dans `_loadUserDataForRecap()`, la fonction retourne `null` au lieu d'une Map
**Symptôme**: L'image montre cette erreur rouge

### Solution 1.1: Corriger la fonction `_loadUserDataForRecap()`

Chercher cette fonction et s'assurer qu'elle ne retourne JAMAIS null:

```dart
Future<Map<String, dynamic>> _loadUserDataForRecap() async {
  try {
    final userData = await UserService.getProfile();
    
    if (userData.isNotEmpty) {
      _userData = userData;
      return userData;
    }
    
    // Si vide, retourner Map vide JAMAIS null
    return {}; // ← Pas de null!
  } catch (e) {
    debugPrint('Erreur: $e');
    return {}; // ← Jamais null!
  }
}
```

---

## Problème 2: Récap affiche "0F" au lieu des valeurs

**Cause**: Les variables `_primeCalculee` et `_renteCalculee` ne sont pas initialisées ou sont à null
**Symptôme**: Affiche "0 F" au lieu de "150 000 F"

### Solution 2.1: Initialiser les variables

```dart
// En haut de la classe, chercher:
double? _primeCalculee;
double? _renteCalculee;

// Remplacer par:
double? _primeCalculee = 0;
double? _renteCalculee = 0;
```

### Solution 2.2: Vérifier le formatage

Chercher `_formatMontant()` et s'assurer qu'elle traite les 0:

```dart
String _formatMontant(double amount) {
  if (amount == null || amount == 0) {
    return 'Non calculé'; // ← Au lieu de "0 F"
  }
  // Formater le montant...
}
```

---

## Problème 3: Récap n'affiche pas les données de souscription

**Cause**: Les champs (capital, durée, etc.) ne sont pas affichés dans le récap
**Symptôme**: Le récapitulatif manque les infos de la simulation

### Solution 3: Ajouter les champs au récap

Dans `_buildRecapContent()`, ajouter après les infos du produit:

```dart
_buildRecapSection(
  'Simulation',
  Icons.calculate,
  vertSucces,
  [
    _buildCombinedRecapRow(
        'Capital choisi',
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

---

## Problème 4: Clic sur "Finaliser" ne change pas la page (toujours étape 3)

**Cause**: Le bouton n'appelle pas `_nextStep()` correctement, ou la navigation ne fonctionne pas
**Symptôme**: Cliquer "Finaliser" ne passe pas à l'étape 4

### Solution 4: Vérifier le PageController

```dart
// Chercher _buildNavigationButtons() et vérifier:
ElevatedButton(
  onPressed: () {
    int finalStep = _isCommercial ? 3 : 2;
    
    if (_currentStep == finalStep) {
      // Passer à l'étape paiement
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  },
  child: Text('Finaliser'),
)
```

---

## Problème 5: Paiement ne s'affiche pas en bas de la fenêtre (overlay)

**Cause**: L'architecture utilise PageView (pages séparées) au lieu d'overlay

**Actuel**: PageView (étape 3 = récap, étape 4 = paiement séparé)
**Demandé**: Paiement en overlay en bas de la même page

### Solution 5: Modèle actuel vs demandé

**Si vous voulez garder PageView**: Rien à faire, c'est normal que l'étape 4 soit une nouvelle page

**Si vous voulez un overlay**: Faudrait refactoriser avec `showModalBottomSheet` ou `BottomSheet`:

```dart
// Dans _buildRecapContent(), remplacer le bouton "Finaliser" par:
FloatingActionButton.extended(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildPaymentSheet(),
    );
  },
  label: Text('Finaliser'),
)
```

---

## Problème 6: CORIS Solidarité - Calcul auto à partir de Capital + Durée

**Cause**: Le calcul ne se lance pas automatiquement, il faut appuyer sur un bouton
**Symptôme**: Utilisateur entre capital et durée, mais rien ne se calcule

### Solution 6: Ajouter TextWatcher (onChange listener)

```dart
// Dans initState(), ajouter:
_capitalController.addListener(_calculateSimulation);
_dureeController.addListener(_calculateSimulation);

// Puis créer la fonction:
void _calculateSimulation() {
  if (_capitalController.text.isNotEmpty && _dureeController.text.isNotEmpty) {
    setState(() {
      double capital = double.tryParse(_capitalController.text) ?? 0;
      int duree = int.tryParse(_dureeController.text) ?? 0;
      
      // Exemple simple (à adapter selon votre formule)
      _primeCalculee = capital / duree / 12;
      _renteCalculee = capital * 0.05;
    });
  }
}
```

---

## Problème 7: Erreur NULL n'affiche pas pour Commercial non plus

**Cause**: Le FutureBuilder ou le parsing retourne null
**Symptôme**: Les deux flux client et commercial ont l'erreur

### Solution 7: Revérifier `_loadUserDataForRecap()`

S'assurer qu'elle JAMAIS retourne null, toujours retourner une Map (même vide):

```dart
Future<Map<String, dynamic>> _loadUserDataForRecap() async {
  try {
    final userData = await UserService.getProfile();
    return userData ?? {}; // Jamais null!
  } catch (e) {
    return {}; // Jamais null!
  }
}
```

---

## RÉSUMÉ DES FIXES

| Problème | Fix | Priorité |
|----------|-----|----------|
| Erreur Null | Retourner Map vide, jamais null | 🔴 CRITIQUE |
| "0F" au lieu de montants | Initialiser variables à 0, pas null | 🔴 CRITIQUE |
| Données de souscription manquantes | Ajouter champs capital/durée au récap | 🟡 HAUT |
| Finaliser ne change pas de page | Vérifier PageController.nextPage() | 🟡 HAUT |
| Paiement pas en overlay | Décider: PageView ou BottomSheet | 🟡 HAUT |
| Solidarité: Calcul auto | Ajouter onChange listener | 🟡 HAUT |

---

## PLAN D'ACTION

1. **Immédiat** (5 min): Fixer le retour null → toujours Map
2. **Rapide** (10 min): Initialiser variables à 0 au lieu de null
3. **Moyen** (30 min): Ajouter champs au récap + onChange listeners
4. **Futur** (si OK): Décider PageView vs BottomSheet pour paiement

---

Dites-moi quel problème corriger **EN PREMIER**, et je vais appliquer la solution au code!
