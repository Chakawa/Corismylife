# Patterns de Correction - Référence pour Futures Modifications

## Pattern 1: Parsing Multi-Format JSON pour Profil Utilisateur

### Problème
L'API retourne plusieurs formats possibles de réponse utilisateur selon le contexte. Le code doit accepter tous les formats.

### Formats Supportés
```json
// Format 1 (RÉEL):
{
  "success": true,
  "data": {
    "id": 3,
    "civilite": "Monsieur",
    "nom": "FOFANA",
    "prenom": "MOUSSA",
    "email": "user@example.com",
    ...
  }
}

// Format 2 (ALTERNATIF):
{
  "success": true,
  "data": {
    "user": {
      "id": 3,
      "email": "user@example.com",
      ...
    }
  }
}

// Format 3 (ANCIEN):
{
  "success": true,
  "user": {
    "id": 3,
    ...
  }
}

// Format 4 (DIRECT):
{
  "id": 3,
  "email": "user@example.com",
  ...
}
```

### Code Correct (Ordre de Priorité)
```dart
static Future<Map<String, dynamic>> getProfile() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Priorité 1: Format réel - data['data'] with user props
      if (data['success'] == true &&
          data['data'] != null &&
          data['data'].containsKey('id')) {
        debugPrint('✅ Format prioritaire trouvé (data[data] avec id)');
        return data['data'];
      }

      // Priorité 2: Format alternatif - data['data']['user']
      if (data['data'] != null && data['data']['user'] != null) {
        debugPrint('✅ Format alternatif trouvé (data[data][user])');
        return data['data']['user'];
      }

      // Priorité 3: Ancien format - data['user']
      if (data['user'] != null) {
        debugPrint('✅ Format ancien trouvé (data[user])');
        return data['user'];
      }

      // Priorité 4: Direct user object
      if (data.containsKey('id')) {
        debugPrint('✅ Format direct trouvé (user object)');
        return data;
      }

      // Aucun format reconnu
      debugPrint('❌ Format inattendu: ${response.body}');
      return {};
    }

    debugPrint('❌ HTTP Error: ${response.statusCode}');
    return {};
  } catch (e) {
    debugPrint('❌ Exception: $e');
    return {};
  }
}
```

---

## Pattern 2: Gating Conditionnel pour Affichage Récapitulatif

### Problème
Certains champs (prime, rente) ne sont calculés que pour les commerciaux dans l'étape 1-2. Les clients n'ont jamais ces champs. La condition de gating doit donc être conditionnelle elle-même.

### ❌ Code Incorrect (Bloque tout le monde)
```dart
if (primeDisplay == 0 || renteDisplay == 0) {
  return Center(child: Text('Calcul en cours...'));
}
// Afficher le récap...
```

### ✅ Code Correct (Bloque uniquement les commerciaux)
```dart
// Pour les COMMERCIAUX SEULEMENT: vérifier que les calculs sont faits
if (_isCommercial && (primeDisplay == 0 || renteDisplay == 0)) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: rougeCoris),
        SizedBox(height: 16),
        Text('Calcul en cours...'),
        // ...
      ],
    ),
  );
}

// Pour les CLIENTS: afficher directement, pour les COMMERCIAUX: afficher si calculs faits
return ListView(
  children: [
    // Contenu du récap...
  ],
);
```

### Logique
```dart
bool shouldBlockDisplay = _isCommercial && (primeDisplay == 0 || renteDisplay == 0);

if (shouldBlockDisplay) {
  // Afficher "Calcul en cours..."
} else {
  // Afficher le récap
}
```

---

## Pattern 3: Chargement de Données Utilisateur en Async pour Clients

### Problème
Les clients connectés doivent avoir leurs données chargées depuis la base de données. Les commerciaux qui saisissent des infos client manuellement n'en ont pas besoin.

### Code Correct
```dart
Widget _buildStep3() {
  return FutureBuilder<Map<String, dynamic>>(
    // Pour commerciaux: null (pas de chargement)
    // Pour clients: _loadUserDataForRecap() (charger depuis BDD)
    future: _isCommercial ? null : _loadUserDataForRecap(),
    builder: (context, snapshot) {
      // Si commercial: utiliser directement _userData
      if (_isCommercial) {
        return _buildRecapContent();
      }

      // Si client en attente: spinner
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      // Si erreur: essayer utiliser _userData si disponible
      if (snapshot.hasError) {
        if (_userData.isNotEmpty) {
          return _buildRecapContent(userData: _userData);
        }
        return ErrorWidget();
      }

      // Succès: utiliser snapshot.data
      final userData = snapshot.data ?? _userData;
      return _buildRecapContent(userData: userData);
    },
  );
}

Future<Map<String, dynamic>> _loadUserDataForRecap() async {
  try {
    final userData = await UserService.getProfile();
    
    // Valider que le format attendu est présent
    if (userData.containsKey('id') && userData.containsKey('nom')) {
      _userData = userData; // Cache pour réutilisation
      return userData;
    }

    debugPrint('❌ Format profil invalide: $userData');
    return {};
  } catch (e) {
    debugPrint('❌ Erreur chargement profil: $e');
    return {};
  }
}
```

---

## Pattern 4: Navigation Entre Étapes (Récap → Paiement)

### Bouton d'Action Dynamique
```dart
Widget _buildNavigationButtons() {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            // Déterminer quelle est l'étape final (récap)
            int finalStep = _isCommercial ? 3 : 2;
            
            if (_currentStep == finalStep) {
              // Étape récap: bouton "Finaliser" → Navigue vers paiement
              _nextStep();
            } else if (_currentStep == finalStep + 1) {
              // Étape paiement: bouton "Payer" → Traiter paiement
              _showPaymentOptions();
            } else {
              // Autres étapes: bouton "Suivant"
              _nextStep();
            }
          },
          child: Text(
            () {
              int finalStep = _isCommercial ? 3 : 2;
              if (_currentStep == finalStep) {
                return 'Finaliser';
              } else if (_currentStep == finalStep + 1) {
                return 'Payer maintenant';
              } else {
                return 'Suivant';
              }
            }(),
          ),
        ),
      ),
    ],
  );
}

void _nextStep() {
  _pageController.nextPage(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

### Explication du Flux
```
CLIENT:
Étape 0 → Étape 1 (Récap, finalStep=2)
  ↓       ↓
Suivant Suivant  (goto Étape 2)
  ↓       ↓
Étape 1 → Étape 2 (Récap)
  ↓       ↓
Suivant Finaliser (goto Étape 3)
  ↓       ↓
Étape 2 → Étape 3 (Paiement, finalStep+1)
          ↓
        Payer maintenant

COMMERCIAL:
Étape 0 → Étape 1 → Étape 2 → Étape 3 (Récap, finalStep=3)
  ↓       ↓       ↓       ↓
Suivant Suivant Suivant Finaliser (goto Étape 4)
  ↓       ↓       ↓       ↓
... → ... → ... → Étape 4 (Paiement)
                    ↓
                Payer maintenant
```

---

## Checklist d'Application (Pour Futures Corrections)

- [ ] Identifier le problème (parsing JSON, gating display, etc.)
- [ ] Chercher le pattern exact dans `souscription_etude.dart`
- [ ] Vérifier si d'autres écrans ont le même problème (`grep_search`)
- [ ] Appliquer la correction à ALL produits (ne pas oublier 1 seul)
- [ ] Tester `flutter analyze` pour valider compilation
- [ ] Tester app avec `flutter run` pour vérifier behavior
- [ ] Vérifier logs pour "✅" et "❌" messages
- [ ] Tester tous les 7 produits (étude, familis, retraite, flex, serenite, solidarite, epargne)
- [ ] Tester flux commercial ET flux client pour chaque produit
- [ ] Documenter les changements pour future reference
