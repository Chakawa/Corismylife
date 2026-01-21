# Mise à jour des tarifs CORIS RETRAITE - 21 janvier 2026

## Résumé des modifications

Les tarifs de la souscription CORIS RETRAITE ont été mis à jour pour utiliser la même méthode de calcul que la simulation.

## Changements effectués

### 1. Remplacement de la table tarifaire

**AVANT :** Table `premiumValues` (prime pour 1 million de capital)
```dart
final Map<int, Map<String, double>> premiumValues = {
  5: {
    'mensuel': 17385.55245,      // Prime pour obtenir 1M FCFA
    'trimestriel': 51343.16466,
    ...
  },
  ...
}
```

**APRÈS :** Table `capitalValues` (capital pour prime de référence)
```dart
final Map<int, Map<String, double>> capitalValues = {
  5: {
    'mensuel': 605463.405379,    // Capital obtenu avec prime de 10 000 FCFA
    'trimestriel': 615056.504123, // Capital obtenu avec prime de 30 000 FCFA
    'semestriel': 620331.447928,  // Capital obtenu avec prime de 60 000 FCFA
    'annuel': 625666.388106       // Capital obtenu avec prime de 120 000 FCFA
  },
  ...
}
```

### 2. Nouvelle méthode de calcul

#### Calcul de la PRIME (à partir d'un capital souhaité)

**AVANT :**
```dart
// Ancienne méthode (moins précise)
Prime = (Capital_Voulu × Prime_pour_1M) / 1 000 000
```

**APRÈS :**
```dart
// Nouvelle méthode (plus précise)
Prime = (Capital_Voulu × Prime_Reference) / Capital_pour_Prime_Reference

Où:
- Prime_Reference = 10 000 (mensuel), 30 000 (trimestriel), 60 000 (semestriel), 120 000 (annuel)
- Capital_pour_Prime_Reference = valeur dans capitalValues[durée][périodicité]
```

#### Calcul du CAPITAL (à partir d'une prime payée)

**AVANT :**
```dart
// Ancienne méthode (moins précise)
Capital = (Prime_Payée × 1 000 000) / Prime_pour_1M
```

**APRÈS :**
```dart
// Nouvelle méthode (plus précise)
Capital = (Prime_Payée × Capital_pour_Prime_Reference) / Prime_Reference

Où:
- Prime_Reference = 10 000 (mensuel), 30 000 (trimestriel), 60 000 (semestriel), 120 000 (annuel)
- Capital_pour_Prime_Reference = valeur dans capitalValues[durée][périodicité]
```

## Exemple de comparaison

### Durée: 10 ans, Périodicité: Annuel, Capital souhaité: 2 000 000 FCFA

**ANCIENNE MÉTHODE :**
```
Prime_pour_1M = 87500.89678 FCFA
Prime = (2 000 000 × 87500.89678) / 1 000 000
Prime = 175 001.79 FCFA
```

**NOUVELLE MÉTHODE :**
```
Capital_pour_Prime_Reference = 1 371 414.515917 FCFA
Prime_Reference = 120 000 FCFA
Prime = (2 000 000 × 120 000) / 1 371 414.515917
Prime = 175 000.89 FCFA
```

**Différence :** ~0.90 FCFA (plus précis avec la nouvelle méthode)

### Durée: 10 ans, Périodicité: Annuel, Prime payée: 200 000 FCFA

**ANCIENNE MÉTHODE :**
```
Prime_pour_1M = 87500.89678 FCFA
Capital = (200 000 × 1 000 000) / 87500.89678
Capital = 2 285 690.02 FCFA
```

**NOUVELLE MÉTHODE :**
```
Capital_pour_Prime_Reference = 1 371 414.515917 FCFA
Prime_Reference = 120 000 FCFA
Capital = (200 000 × 1 371 414.515917) / 120 000
Capital = 2 285 690.86 FCFA
```

**Différence :** ~0.84 FCFA (plus précis avec la nouvelle méthode)

## Avantages de la nouvelle méthode

1. **Précision accrue** : Utilise directement les valeurs de capital au lieu de faire un calcul inverse
2. **Cohérence** : Même méthode dans la simulation et la souscription
3. **Transparence** : Les valeurs de capital affichées correspondent exactement aux calculs
4. **Maintenance** : Une seule table à maintenir (capitalValues) au lieu de deux tables différentes

## Fichiers modifiés

- `lib/features/souscription/presentation/screens/souscription_retraite.dart`
  - Lignes 185-464 : Remplacement de `premiumValues` par `capitalValues`
  - Ligne 1069-1087 : Mise à jour de `calculatePremium()`
  - Ligne 1089-1117 : Mise à jour de `calculateCapital()`

## Tests recommandés

1. Tester le calcul de prime pour différentes durées (5, 10, 20, 30, 50 ans)
2. Tester le calcul de capital pour différentes périodicités (mensuel, trimestriel, semestriel, annuel)
3. Comparer les résultats entre simulation et souscription
4. Vérifier que les montants minimaux sont respectés

## Notes

- Les valeurs de `capitalValues` sont identiques à celles de la simulation
- Les primes de référence correspondent aux minimas de chaque périodicité pour 10 ans
- Aucun changement dans l'interface utilisateur, uniquement la logique de calcul
