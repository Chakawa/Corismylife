# 🎨 VISUALISATION: Comment le Questionnaire s'Affiche

## 📱 Exemple Complet: Proposition Details Page

### 1️⃣ En Haut: Informations Personnelles
```
┌─────────────────────────────────────────┐
│ INFORMATIONS PERSONNELLES               │
├─────────────────────────────────────────┤
│ Civilité        : M.                    │
│ Nom             : DUPONT                │
│ Prénom          : Jean                  │
│ Téléphone       : +33 6 12 34 56 78     │
│ Email           : jean@example.com      │
└─────────────────────────────────────────┘
```

### 2️⃣ Au Milieu: Détails du Contrat
```
┌─────────────────────────────────────────┐
│ DÉTAILS DU CONTRAT                      │
├─────────────────────────────────────────┤
│ Produit         : Étude Serein           │
│ Prime annuelle  : 450,00 €              │
│ Capital garanti : 25 000,00 €           │
│ Durée           : 5 ans                 │
└─────────────────────────────────────────┘
```

### 3️⃣ Documents (Identité, etc.)
```
┌─────────────────────────────────────────┐
│ 📎 DOCUMENTS                            │
├─────────────────────────────────────────┤
│ 📄 MA_CARTE_IDENTITE.jpg ✓              │
│ 📄 MON_RIB.pdf ✓                        │
└─────────────────────────────────────────┘
```

### 4️⃣ 🎯 **QUESTIONNAIRE MÉDICAL** (CE QUE VOUS VOYEZ)

```
╔═════════════════════════════════════════════════════════╗
║ 📋 QUESTIONNAIRE MÉDICAL                                ║
╠═════════════════════════════════════════════════════════╣
║                                                         ║
║ ┌─────────────────────────────────────────────────┐    ║
║ │ 1. Avez-vous des antécédents médicaux?         │    │
║ │    (Diabète, tension, cholestérol...)          │    │
║ │                                                 │    ║
║ │ NON                                             │    ║
║ └─────────────────────────────────────────────────┘    ║
║                                                         ║
║ ┌─────────────────────────────────────────────────┐    ║
║ │ 2. Fumez-vous ou avez-vous fumé?               │    ║
║ │                                                 │    ║
║ │ OUI — Depuis 5 ans - 10 cigarettes par jour    │    ║
║ └─────────────────────────────────────────────────┘    ║
║                                                         ║
║ ┌─────────────────────────────────────────────────┐    ║
║ │ 3. Consommez-vous de l'alcool?                 │    ║
║ │                                                 │    ║
║ │ NON                                             │    ║
║ └─────────────────────────────────────────────────┘    ║
║                                                         ║
║ ┌─────────────────────────────────────────────────┐    ║
║ │ 4. Avez-vous des allergies?                    │    ║
║ │                                                 │    ║
║ │ OUI — Pénicilline, Cacahuètes                  │    ║
║ └─────────────────────────────────────────────────┘    ║
║                                                         ║
║ ┌─────────────────────────────────────────────────┐    ║
║ │ 5. Pratiquez-vous un sport?                    │    ║
║ │                                                 │    ║
║ │ OUI — Tennis 2x/semaine                        │    ║
║ └─────────────────────────────────────────────────┘    ║
║                                                         ║
╚═════════════════════════════════════════════════════════╝
```

---

## 🎨 ANATOMIE DE L'AFFICHAGE

### Structure Visuelle
```
┌─── Boîte Conteneur ───────────────────┐
│ (Gris clair avec bordure bleu léger)   │
│                                        │
│  📍 NUMÉRO + QUESTION (Gras Bleu)     │  ← Texte principal
│  "1. Avez-vous des antécédents?"      │
│                                        │
│  RÉPONSE (Vert + Détails)             │  ← Texte réponse
│  "NON"                                │
│  ou                                   │
│  "OUI — Depuis 5 ans - 10 cig/jour"  │
│                                        │
└────────────────────────────────────────┘
    ▼
    Espacement 12px
    ▼
┌─── Boîte Conteneur Suivante ──────────┐
│ ...                                    │
```

### Couleurs Appliquées

| Élément | Couleur | Hex | Usage |
|---------|---------|-----|-------|
| Question | Bleu (gras) | #002B6B | `bleuCoris` |
| Réponse | Vert | #10B981 | `vertSucces` |
| Boîte | Gris | #F1F5F9 | `grisLeger` |
| Bordure | Bleu léger | #1E4A8C (30%) | `bleuSecondaire` + alpha |

### Typographie

| Élément | Poids | Taille | Hauteur |
|---------|-------|--------|---------|
| Question | Bold (700) | 13px | 1.4x |
| Réponse | SemiBold (600) | 12px | Auto |

---

## 🔍 CAS D'USAGE: DIFFÉRENTS TYPES DE RÉPONSES

### ✅ Cas 1: Réponse OUI/NON Simple
```
┌─────────────────────────────────┐
│ 1. Fumez-vous?                  │ ← Question
│                                 │
│ NON                             │ ← Réponse simple
└─────────────────────────────────┘
```

### ✅ Cas 2: OUI/NON + Détails
```
┌──────────────────────────────────────────────────┐
│ 2. Fumez-vous?                                   │ ← Question
│                                                  │
│ OUI — Depuis 5 ans - 10 cigarettes par jour     │ ← Réponse + détails
└──────────────────────────────────────────────────┘
```

### ✅ Cas 3: Réponse Texte Libre
```
┌──────────────────────────────────────────────────┐
│ 3. Quel est votre sport principal?               │ ← Question
│                                                  │
│ Tennis et natation                               │ ← Texte libre
└──────────────────────────────────────────────────┘
```

### ✅ Cas 4: Réponse Complexe (Multiple Détails)
```
┌──────────────────────────────────────────────────┐
│ 4. Avez-vous des allergies?                      │ ← Question
│                                                  │
│ OUI — Pénicilline / Cacahuètes / Pollen        │ ← Détails séparés
└──────────────────────────────────────────────────┘
```

---

## 🚫 CE QUE VOUS NE VERREZ PAS

### ❌ Format "Question 1 Résultat"
```
MAUVAIS ❌ :
Question 1 Avez-vous des antécédents? Résultat NON Question 2 Fumez-vous? Résultat OUI
```

### ❌ Format Compressé
```
MAUVAIS ❌ :
Q1: Antécédents → NON | Q2: Fumez-vous → OUI | Q3: Allergies → OUI
```

### ❌ Sans Séparation Visuelle
```
MAUVAIS ❌ :
1. Avez-vous des antécédents? NON
2. Fumez-vous? OUI — Depuis 5 ans
```

### ✅ CE QUE VOUS VERREZ À LA PLACE

**Boîtes Numérotées avec Séparation:**
```
┌─────────────────────┐
│ 1. Question 1       │
│ Réponse 1           │
└─────────────────────┘

┌─────────────────────┐
│ 2. Question 2       │
│ Réponse 2           │
└─────────────────────┘
```

---

## 📍 OÙ LE QUESTIONNAIRE APPARAÎT

### 1️⃣ Recaps de Souscription (En cours de remplissage)
- Étude → Questionnaire visible après validation
- Familis → Questionnaire visible après validation
- Sérénité → Questionnaire visible après validation
- Etc. pour tous les 9 produits

### 2️⃣ Page "Mes Propositions" → Détails
- Clic sur proposition
- Section "Questionnaire Médical" visible
- Affichage structuré avec boîtes
- Toutes les Q-R affichées

### 3️⃣ Page "Récapitulatif" avant paiement
- Même affichage structuré
- Vérification avant confirmation
- Options pour modifier

---

## 🎯 CODE SOURCE: Où voir l'Implémentation

### Widget d'Affichage
```dart
File: lib/core/widgets/subscription_recap_widgets.dart
Function: buildQuestionnaireMedicalSection(List<Map<String, dynamic>>? reponses)
Lines: 740-825
```

**Logique:**
1. Pour chaque réponse dans la liste
2. Extraire question (libelle), réponse (oui_non ou text), détails
3. Créer Container avec:
   - Fond gris clair
   - Bordure bleu pâle
   - Intérieur: Question (bleu gras) + Réponse (vert)
4. Espacement entre conteneurs

### Service de Récupération
```dart
File: lib/services/questionnaire_medical_service.dart
Function: getReponses(int subscriptionId)
```

Appelle API `/subscriptions/:id/questionnaire` pour récupérer les réponses.

### Page qui Affiche
```dart
File: lib/features/client/presentation/screens/proposition_detail_page.dart
Function: _getQuestionnaireMedicalReponses()
         buildQuestionnaireMedicalSection()
```

1. Charge les données via `getSubscriptionDetail()`
2. Parse les réponses via `_getQuestionnaireMedicalReponses()`
3. Affiche via `buildQuestionnaireMedicalSection()` widget

---

## 📊 TABLEAU RÉCAPITULATIF

| Aspect | Spécification | Validation |
|--------|--------------|-----------|
| **Format** | Boîtes numérotées | ✅ Implémenté |
| **Question** | Gras + Bleu (#002B6B) | ✅ Implémenté |
| **Réponse** | Vert (#10B981) | ✅ Implémenté |
| **Détails** | OUI séparés par " / " | ✅ Implémenté |
| **Espacement** | 12px entre boîtes | ✅ Implémenté |
| **Bordure** | Gris clair + Bleu léger | ✅ Implémenté |
| **Numérotation** | Auto-incrémentée (1, 2, 3...) | ✅ Implémenté |
| **Lieux d'affichage** | Recaps + Proposition Details | ✅ Implémenté |
| **BD Persistance** | Transaction ACID | ✅ Implémenté |
| **Logs Diagnostic** | 39 logs end-to-end | ✅ Implémenté |

---

## 🎬 FLUX COMPLET: De la Remplissage à l'Affichage

```
1. USER: Remplit questionnaire dans widget
   ↓
2. FLUTTER: Valide responses + affiche recap
   ├─ Widget affiche déjà questions/réponses en boîtes
   ├─ Questions numérotées bleu gras
   ├─ Réponses en vert
   ↓
3. FLUTTER: Clique "Valider" → Sauvegarde
   ├─ Appelle POST /subscriptions/:id/questionnaire
   ├─ Backend enregistre dans souscription_questionnaire
   ↓
4. USER: Navigue à "Propositions" → Clique sur proposition
   ├─ Flutter charge /subscriptions/:id/details
   ├─ Backend retourne avec questionnaire_reponses
   ↓
5. FLUTTER: Affiche page Proposition Details
   ├─ _getQuestionnaireMedicalReponses() parse les données
   ├─ buildQuestionnaireMedicalSection() affiche en boîtes
   ├─ Questions numérotées bleu gras
   ├─ Réponses en vert
   ↓
6. USER: Voit questionnaire structuré dans propositions
   ├─ Chaque Q dans boîte
   ├─ Chaque R en-dessous en vert
   ├─ Pas de compression, bien lisible
   ✅ COMPLETE
```

---

## ✨ RÉSUMÉ VISUEL

```
Avant (PAS comme ça) ❌:
Question 1 Résultat Question 2 Résultat...

Maintenant (Comme ça) ✅:
┌─────────────────┐
│ 1. Question     │
│ Réponse         │
└─────────────────┘
┌─────────────────┐
│ 2. Question     │
│ Réponse         │
└─────────────────┘
```

**SYSTÈME 100% OPÉRATIONNEL POUR AFFICHAGE STRUCTURÉ!**

