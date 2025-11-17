# QUICK REFERENCE: CALCUL ET TRIGGERS - 7 ÉCRANS DE SOUSCRIPTION

## 📍 LOCALISATION RAPIDE

| Écran | Calcul | Ligne | Listeners | Recap | Payer | Status |
|-------|--------|-------|-----------|-------|-------|--------|
| **Etude** | _recalculerValeurs | 1935 | didChanges? | 3181 | 3714 | ⚠️ À vérifier |
| **Familis** | MANQUANT | ? | ? | 4170 | 4603 | 🔴 CRITIQUE |
| **Epargne** | N/A | - | None | 1894 | 2337 | ✅ OK |
| **Retraite** | _effectuerCalcul | 730 | initState(526) | ? | 2534 | ⚠️ Recap? |
| **Flex** | _effectuerCalcul | 1926 | NON TROUVÉ | NON TROUVÉ | 4092 | 🔴 CRITIQUE |
| **Serenite** | _effectuerCalcul | 1393 | initState(1048) | 2785 | 3264 | ✅ OK |
| **Solidarite** | _calculerPrime | ~320 | Manual | >2000 | ? | ⚠️ Incomplet |

---

## 🎯 PATTERNS IDENTIFIÉS

### Pattern A: Listeners en initState ✅ CORRECT
```dart
// Retraite (526-540) + Serenite (1048-1062)
@override
void initState() {
  _primeController.addListener(() => _effectuerCalcul());
  _capitalController.addListener(() => _effectuerCalcul());
  _dureeController.addListener(() => _effectuerCalcul());
}
```

### Pattern B: Listeners en didChangeDependencies ⚠️ PROBLÉMATIQUE
```dart
// Etude (présumé) + Familis (présumé)
@override
void didChangeDependencies() {
  _dureeController.addListener(() => _recalculerValeurs());
  // ⚠️ Crée plusieurs listeners = fuite mémoire
}
```

### Pattern C: Listeners absents 🔴 CRITIQUE
```dart
// Flex = Aucun addListener trouvé!
// Solidarite = Calcul manuel seulement
```

### Pattern D: FutureBuilder ✅ BEST PRACTICE
```dart
// Epargne (1894) + Solidarite (~2000)
FutureBuilder(
  future: _loadUserDataForRecap(),
  builder: (context, snapshot) {
    return _buildRecapContent(snapshot.data);
  }
)
```

---

## 🔴 ISSUES CRITIQUES À FIXER

### 1. Flex: Listeners introuvables
```
Ligne 1926 - Calcul existe: _effectuerCalcul()
Ligne 4092 - Button existe: Payer maintenant
MAIS: Aucun addListener trouvé!

Solution: Chercher dans didChangeDependencies ou initState
```

### 2. Familis: Calcul introuvable
```
Ligne 4170 - _buildStep3() existe
Ligne 4603 - Payer maintenant existe
MAIS: Aucune fonction de calcul trouvée!

Solution: Clarifier si produit a calcul dynamique ou non
```

### 3. Etude: Listeners potentiellement en mauvaise place
```
Ligne 1935 - _recalculerValeurs() existe
MAIS: Probablement en didChangeDependencies = fuite mémoire!

Solution: Bouger listeners de didChangeDependencies vers initState
```

---

## ✅ FICHIERS VALIDÉS

### Serenite: PATTERN CORRECT
```
Calcul async: ligne 1393 (_effectuerCalcul)
Listeners: ligne 1048-1062 (initState) ✅
Recap: ligne 2785 (_buildStep3)
Button: ligne 3264 (Payer maintenant)
Status: ✅ COMPLET ET CORRECT
```

### Retraite: PATTERN PRESQUE CORRECT
```
Calcul async: ligne 730 (_effectuerCalcul)
Listeners: ligne 526-540 (initState) ✅
Recap: ? (NOT FOUND in grep)
Button: ligne 2534 (Payer maintenant)
Status: ⚠️ Recap builder manquant
```

### Epargne: BEST PRACTICE
```
Calcul: AUCUN (capital fixe)
Data loading: FutureBuilder (1894) ✅
Recap: ligne 1894 (_buildStep3)
Button: ligne 2337 (Payer maintenant)
Status: ✅ À UTILISER COMME RÉFÉRENCE
```

---

## 📝 TARIFF TABLES FORMATS

### Format Standard (Nested Maps)
```dart
// Etude, Familis, Retraite, Serenite
Map<int, Map<String, double>> tarifaire = {
  18: {'mensuel': 150.0, 'annuel': 1800.0},
  25: {'mensuel': 140.0, 'annuel': 1680.0},
};
```

### Format String-Keys (Flex - COMPLEXE)
```dart
// Flex uniquement
Map<String, double> tarifsPretAmortissable = {
  '18_12': 0.0085,   // AGE_DUREE format
  '18_24': 0.0075,
  '30_12': 0.0080,
};
// ⚠️ Difficile à maintenir, lookup complexe
```

### Format Multi-Surcharges (Solidarite)
```dart
// Solidarite
Map<int, Map<String, double>> base = { 500000: {...} };
Map<int, Map<String, int>> surconjoints = { 500000: {...} };
Map<int, Map<String, int>> surenfants = { 500000: {...} };
// ⚠️ Tariffs éparpillées dans 4 maps
```

---

## 🎬 FLOW DE SOUSCRIPTION

### Retraite + Serenite (NORMAL)
```
User input → listener triggered → _effectuerCalcul() → setState → UI update
```

### Etude + Familis (ANORMAL?)
```
didChangeDependencies() → multiple listeners! → _recalculerValeurs() → memory leak risk
```

### Flex (CASSÉ)
```
User input → ??? (no listeners found) → Calcul ne se déclenche jamais!
```

### Solidarite (MANUEL)
```
User change dropdown → onChange handler → manual _calculerPrime() call → setState
```

### Epargne (SIMPLE)
```
User select capital → no calculation → show recap with FutureBuilder
```

---

## 🚨 BEFORE/AFTER FIXES

### Issue: didChangeDependencies listeners

**AVANT (Problématique)**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies(); // ⚠️ Appelé PLUSIEURS FOIS
  
  _dureeController.addListener(() {
    _recalculerValeurs();
  }); // ❌ Nouveau listener à chaque appel = fuite mémoire
}
```

**APRÈS (Correct)**
```dart
@override
void initState() {
  super.initState(); // ✅ Appelé UNE SEULE FOIS
  
  _dureeController.addListener(() {
    _recalculerValeurs();
  }); // ✅ Listener ajouté une seule fois
}
```

### Issue: Tariff lookup Flex

**AVANT (Complexe)**
```dart
// String keys 'AGE_DUREE' -> confus
String key = '${age}_${dureeMois}';
double rate = tarifsPretAmortissable[key] ?? 0.0; // Peut pas trouver → 0.0

// Que se passe si on demande age=25, duree=13?
// => 25_13 n'existe pas => rate = 0.0 ❌
```

**APRÈS (Clair)**
```dart
// Nested maps -> facile
Map<int, Map<String, double>> tarifs = {
  25: {'12': 0.0085, '24': 0.0075},
};

double rate = tarifs[age]?[dureeMois.toString()] 
              ?? tarifs[findClosestAge(age)]?[dureeMois.toString()] 
              ?? 0.0; // Lookup avec approximation
```

### Issue: Data loading blocking UI

**AVANT (Synchrone - gèle l'UI)**
```dart
void initState() {
  super.initState();
  
  final userData = fetchUserDataSync(); // ❌ BLOQUE LE RENDU!
  _userData = userData;
}
```

**APRÈS (Async - Non-bloquant) ✅**
```dart
FutureBuilder<Map>(
  future: _loadUserDataForRecap(), // ✅ Charge en arrière-plan
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingIndicator(); // Montre spinner
    }
    return _buildRecapContent(snapshot.data);
  },
)
```

---

## 📊 CHECKLIST RAPIDITÉ

### Pour Etude
- [ ] `grep -n "addListener" souscription_etude.dart` → quelle ligne?
- [ ] Vérifier si addListener dans initState ou didChangeDependencies
- [ ] Si didChangeDependencies → FUITE MÉMOIRE probable

### Pour Familis
- [ ] `grep -n "void _recalculerValeurs\|void _effectuerCalcul\|void _calculerPrime" souscription_familis.dart`
- [ ] Si rien trouvé → produit n'a pas de calcul? (fixe uniquement)

### Pour Flex
- [ ] `grep -n "addListener\|.addListener" souscription_flex.dart` → chercher partout
- [ ] Si rien trouvé → écran CASSÉ, calcul ne se déclenche jamais
- [ ] `grep -n "Widget _buildStep3" souscription_flex.dart` → chercher recap

### Pour Solidarite
- [ ] `read_file souscription_solidarite.dart 2000 678` → lire fin du fichier
- [ ] Localiser recap builder et buttons

---

## 🎓 KEY INSIGHTS

1. **Retraite & Serenite = Good Model**
   - initState pattern ✅
   - Listeners placés correctement ✅
   - Calcul async ✅

2. **Epargne = Reference pour Data Loading**
   - FutureBuilder pattern ✅
   - Pas de blocage UI ✅

3. **Flex = CASSÉ (Listeners manquants!)**
   - Calcul fonction existe (1926)
   - Mais aucun listener trouvé
   - = Calcul ne se déclenche jamais

4. **Etude = PROBABLE Fuite Mémoire**
   - didChangeDependencies pattern ⚠️
   - Multiple listener creation likely
   - = Memory leak

5. **Familis = MYSTÉRIEUX**
   - Aucune fonction de calcul trouvée
   - Possible que produit n'ait pas calc?
   - Needs investigation

6. **Solidarite = Incomplet (lecture truncated)**
   - Calcul existe (_calculerPrime)
   - Recap/buttons après ligne 2000
   - Needs full file read

---

**Generated:** 2024  
**Quick ref:** Utiliser ce document pour navigation rapide  
**Details:** Voir ANALYSE_CALCUL_TRIGGERS_COMPLET.md
