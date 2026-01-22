# 🎯 GUIDE D'UTILISATION - WIDGETS REFACTORISÉS

## 📦 Fichiers créés

### 1. **payment_method_widget.dart**
Gestion complète des modes de paiement

### 2. **beneficiary_contact_widget.dart**
Gestion des bénéficiaires et contacts d'urgence

### 3. **form_validators.dart**
Validateurs de formulaires réutilisables

---

## 💡 EXEMPLES D'UTILISATION

### 1. Modes de Paiement

#### Import
```dart
import 'package:mycorislife/features/souscription/presentation/widgets/payment_method_widget.dart';
```

#### Dans votre State class
```dart
class _SouscriptionRetraiteScreenState extends State<SouscriptionRetraiteScreen> {
  // AVANT: 6 controllers individuels
  // final _banqueController = TextEditingController();
  // final _ribUnifiedController = TextEditingController();
  // final _numeroMobileMoneyController = TextEditingController();
  // ... etc

  // APRÈS: 1 seul objet
  final _paymentControllers = PaymentMethodControllers();
  String? _selectedModePaiement;

  @override
  void dispose() {
    _paymentControllers.dispose(); // Dispose automatique de tous les controllers
    super.dispose();
  }
}
```

#### Dans le build()
```dart
// Sélection du mode
PaymentMethodSelector(
  selectedMode: _selectedModePaiement,
  onChanged: (mode) {
    setState(() {
      _selectedModePaiement = mode;
      _paymentControllers.clearAll(); // Clear automatique
    });
  },
),

const SizedBox(height: 20),

// Champs selon le mode sélectionné
if (_selectedModePaiement != null)
  PaymentMethodFields(
    modePaiement: _selectedModePaiement!,
    controllers: _paymentControllers,
  ),
```

#### Validation
```dart
bool _validatePayment() {
  final error = PaymentMethodValidator.validate(
    _selectedModePaiement ?? '',
    _paymentControllers,
  );
  
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
    return false;
  }
  return true;
}
```

#### Paiement final (Modal)
```dart
void _showPaymentOptions() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaymentBottomSheet(
      onPayNow: _processPayment,
      onPayLater: _saveAsProposition,
    ),
  );
}
```

#### Construction des données pour l'API
```dart
final subscriptionData = {
  'mode_paiement': _selectedModePaiement,
  'infos_paiement': PaymentDataBuilder.build(
    _selectedModePaiement ?? '',
    _paymentControllers,
  ),
  // ... autres données
};
```

---

### 2. Bénéficiaires & Contacts d'urgence

#### Import
```dart
import 'package:mycorislife/features/souscription/presentation/widgets/beneficiary_contact_widget.dart';
```

#### Dans votre State class
```dart
class _SouscriptionRetraiteScreenState extends State<SouscriptionRetraiteScreen> {
  // AVANT: 8 controllers + 4 variables
  // final _beneficiaireNomController = TextEditingController();
  // final _beneficiaireContactController = TextEditingController();
  // String? _selectedBeneficiaireIndicatif = '+225';
  // String? _selectedLienParente;
  // ... etc (4 de plus pour contact urgence)

  // APRÈS: 1 seul objet
  final _beneficiaryControllers = BeneficiaryContactControllers();

  @override
  void dispose() {
    _beneficiaryControllers.dispose();
    super.dispose();
  }
}
```

#### Dans le build()
```dart
// Formulaire bénéficiaire
BeneficiaryFormFields(
  controllers: _beneficiaryControllers,
  onUpdate: setState, // Pour mettre à jour l'UI
),

const SizedBox(height: 24),

// Formulaire contact d'urgence
EmergencyContactFormFields(
  controllers: _beneficiaryControllers,
  onUpdate: setState,
),
```

#### Validation
```dart
bool _validateBeneficiaryContact() {
  final error = BeneficiaryContactValidator.validate(_beneficiaryControllers);
  
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
    return false;
  }
  return true;
}
```

#### Construction des données pour l'API
```dart
final subscriptionData = {
  'beneficiaire': BeneficiaryContactDataBuilder.buildBeneficiaryData(
    _beneficiaryControllers,
  ),
  'contact_urgence': BeneficiaryContactDataBuilder.buildEmergencyContactData(
    _beneficiaryControllers,
  ),
  // ... autres données
};
```

#### Charger des données existantes (modification)
```dart
@override
void initState() {
  super.initState();
  if (widget.subscriptionId != null) {
    _loadExistingData();
  }
}

Future<void> _loadExistingData() async {
  // ... récupérer les données depuis l'API
  final data = await _fetchSubscription(widget.subscriptionId);
  
  // Charger automatiquement dans les controllers
  _beneficiaryControllers.loadFromData(data['souscriptiondata']);
  setState(() {});
}
```

---

### 3. Validateurs de formulaires

#### Import
```dart
import 'package:mycorislife/core/utils/form_validators.dart';
```

#### Utilisation avec TextFormField
```dart
TextFormField(
  controller: _emailController,
  decoration: InputDecoration(labelText: 'Email'),
  validator: FormValidators.email,
),

TextFormField(
  controller: _phoneController,
  decoration: InputDecoration(labelText: 'Téléphone'),
  validator: (value) => FormValidators.phone(value, fieldName: 'le téléphone'),
),

TextFormField(
  controller: _nameController,
  decoration: InputDecoration(labelText: 'Nom'),
  validator: (value) => FormValidators.name(value, fieldName: 'le nom'),
),
```

#### Validation manuelle
```dart
bool _validateForm() {
  // Email
  final emailError = FormValidators.email(_emailController.text);
  if (emailError != null) {
    _showError(emailError);
    return false;
  }

  // Téléphone
  final phoneError = FormValidators.phone(
    _phoneController.text,
    fieldName: 'le numéro de téléphone',
  );
  if (phoneError != null) {
    _showError(phoneError);
    return false;
  }

  // Montant avec limites
  final amountError = FormValidators.amount(
    _primeController.text,
    fieldName: 'la prime',
    min: 5000,
    max: 1000000,
  );
  if (amountError != null) {
    _showError(amountError);
    return false;
  }

  return true;
}
```

#### Validation combinée
```dart
TextFormField(
  controller: _nameController,
  validator: (value) => FormValidators.combine(value, [
    (v) => FormValidators.required(v, fieldName: 'le nom'),
    (v) => FormValidators.minLength(v, 3, fieldName: 'le nom'),
    (v) => FormValidators.maxLength(v, 50, fieldName: 'le nom'),
  ]),
),
```

---

## ✅ CHECKLIST MIGRATION PAR PRODUIT

### Pour chaque fichier de souscription:

#### Phase 1: Modes de paiement
- [ ] Remplacer les 6 controllers individuels par `PaymentMethodControllers()`
- [ ] Remplacer le dropdown mode de paiement par `PaymentMethodSelector`
- [ ] Remplacer les champs conditionnels par `PaymentMethodFields`
- [ ] Remplacer la validation manuelle par `PaymentMethodValidator.validate()`
- [ ] Remplacer `PaymentBottomSheet` local par celui du widget
- [ ] Remplacer la construction des données par `PaymentDataBuilder.build()`
- [ ] Supprimer l'ancien code (garder en commentaire au début)

#### Phase 2: Bénéficiaires & Contacts
- [ ] Remplacer les 8 controllers par `BeneficiaryContactControllers()`
- [ ] Remplacer le formulaire bénéficiaire par `BeneficiaryFormFields`
- [ ] Remplacer le formulaire contact urgence par `EmergencyContactFormFields`
- [ ] Remplacer la validation par `BeneficiaryContactValidator.validate()`
- [ ] Remplacer la construction des données par `BeneficiaryContactDataBuilder`
- [ ] Supprimer l'ancien code

#### Phase 3: Validateurs
- [ ] Remplacer les validations manuelles par `FormValidators.*`
- [ ] Simplifier le code de validation

---

## 📊 COMPARAISON AVANT/APRÈS

### Nombre de lignes par fichier de souscription

| Composant | Avant | Après | Gain |
|-----------|-------|-------|------|
| Controllers (déclaration) | 15 lignes | 2 lignes | -87% |
| Controllers (dispose) | 8 lignes | 1 ligne | -88% |
| Mode paiement (UI) | ~150 lignes | ~10 lignes | -93% |
| Mode paiement (validation) | ~80 lignes | 5 lignes | -94% |
| Bénéficiaire (UI) | ~100 lignes | ~5 lignes | -95% |
| Contact urgence (UI) | ~100 lignes | ~5 lignes | -95% |
| **TOTAL PAR FICHIER** | **~450 lignes** | **~30 lignes** | **-93%** |

### Pour 7 fichiers
- **Avant**: ~3,150 lignes dupliquées
- **Après**: ~210 lignes + ~800 lignes de widgets réutilisables
- **Gain total**: ~2,140 lignes éliminées ✨

---

## 🚀 ORDRE DE MIGRATION RECOMMANDÉ

1. **souscription_retraite.dart** (fichier de test)
2. **souscription_serenite.dart**
3. **souscription_familis.dart**
4. **souscription_etude.dart**
5. **souscription_epargne.dart**
6. **souscription_mon_bon_plan.dart**
7. **souscription_assure_prestige.dart**

---

## ⚠️ POINTS D'ATTENTION

1. **Tests**: Tester chaque produit après migration
2. **Sauvegarde**: Garder l'ancien code en commentaire temporairement
3. **Git**: Commit après chaque fichier migré
4. **Données existantes**: Vérifier que loadFromData() fonctionne
5. **UI**: Vérifier que le rendu visuel est identique

---

## 📞 PROCHAINES ÉTAPES

### À créer (si besoin):
- `client_info_widget.dart` (infos client pour commercial)
- `date_picker_widget.dart` (sélection de dates)
- `document_picker_widget.dart` (sélection de pièces)

### Améliorations futures:
- State management (Provider/Riverpod)
- Tests unitaires pour chaque widget
- Documentation API complète
