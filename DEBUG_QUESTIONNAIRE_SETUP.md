# 🔍 DEBUG SETUP: Questionnaire Médical - Diagnostic Complet

## 📋 Vue d'ensemble
Ce document explique comment tester et diagnostiquer le flux complet du questionnaire médical avec les logs détaillés maintenant en place.

---

## 🚀 Configuration des Logs Ajoutés

### Backend (Node.js/Express)

#### 1️⃣ **saveQuestionnaireMedical** (`subscriptionController.js`)
```javascript
💾 Sauvegarde questionnaire médical pour souscription: [ID]
📝 Nombre de réponses: [COUNT]
📋 Réponses reçues: [JSON]
📝 Traitement question [ID]: réponse=[VALUE]
✏️ Question [ID] MISE À JOUR
✅ Question [ID] INSÉRÉE - ID: [ID]
✅ Questionnaire médical sauvegardé - X/Y réponses enregistrées
🔍 VÉRIFICATION: Z réponses totales en BD pour souscription [ID]
```

#### 2️⃣ **getQuestionnaireMedical** (`subscriptionController.js`)
```javascript
🔍 Récupération questionnaire pour souscription: [ID]
✅ Questionnaire récupéré: X réponses trouvées
📋 Réponses: [JSON détail]
⚠️ Aucune réponse trouvée pour cette souscription
  1. Question "Avez-vous des antécédents?" → NON
  2. Question "Fumez-vous?" → OUI
```

#### 3️⃣ **getSubscriptionWithUserDetails** (`subscriptionController.js`)
```javascript
=== RÉCUPÉRATION DÉTAILS SUBSCRIPTION/CONTRAT ===
📋 ID: [ID]
👤 User ID: [ID]
🎭 Role: [ROLE]
📋 QUESTIONNAIRE MÉDICAL: X réponses récupérées pour souscription [ID]
📝 Détail questionnaire:
  1. "Avez-vous des antécédents?" → NON
  2. "Fumez-vous?" → OUI
✅ RETOUR COMPLET: subscription + user + X questionnaire_reponses
```

### Frontend (Flutter/Dart)

#### 4️⃣ **_loadSubscriptionData()** (`proposition_detail_page.dart`)
```
📥 Chargement détails proposition [ID]...
=== DONNÉES REÇUES DU SERVEUR ===
✅ Subscription reçue: OUI/NON
✅ User reçue: OUI/NON
✅ questionnaire_reponses reçue: OUI/NON
📋 Détail questionnaire_reponses:
  - Type: List avec X éléments
    Q: "Avez-vous des antécédents?" → NON
    Q: "Fumez-vous?" → OUI
```

#### 5️⃣ **_getQuestionnaireMedicalReponses()** (`proposition_detail_page.dart`)
```
🔍 _getQuestionnaireMedicalReponses() appelé
  - _subscriptionData type: Map<String, dynamic>
  - reponses (questionnaire_reponses): [VALUE]
  ✅ questionnaire_reponses trouvé: List
  ✅ Format liste détecté: X réponses
    - Q: "Avez-vous des antécédents?" → R: NON
    - Q: "Fumez-vous?" → R: OUI
```

---

## 🧪 PROCÉDURE DE TEST COMPLÈTE

### Phase 1: Remplir le Questionnaire
1. Ouvrir l'application Flutter
2. **Créer une nouvelle souscription** (ex: Étude, Familis, ou Sérénité)
3. **Remplir le questionnaire médical** avec au moins une réponse (OUI ou NON)
4. **Valider le formulaire**

#### ✅ Vérifier les logs
**Console Flutter:**
```
✅ Questionnaire valid, réponses: {...}
```

**Terminal Backend (si visible):**
```
💾 Sauvegarde questionnaire médical pour souscription: [ID]
📝 Nombre de réponses: X
✅ Questionnaire médical sauvegardé - X/Y réponses enregistrées
```

---

### Phase 2: Vérifier la Base de Données
1. **Connecter à PostgreSQL**
   ```sql
   psql -U [user] -d mycorisdb
   ```

2. **Vérifier les réponses enregistrées**
   ```sql
   SELECT * FROM souscription_questionnaire 
   WHERE subscription_id = [ID];
   ```
   
   ✅ Résultat attendu: Voir au minimum 1 ligne avec:
   - `subscription_id`: correspond à votre souscription
   - `question_id`: l'ID de la question
   - `reponse_oui_non`: 'OUI' ou 'NON'
   - `reponse_text`: texte si applicable

3. **Vérifier les questions**
   ```sql
   SELECT id, libelle, type_question, obligatoire FROM questionnaire_medical 
   WHERE actif = true;
   ```
   
   ✅ Résultat attendu: Voir plusieurs questions avec `actif = true`

---

### Phase 3: Charger les Détails de la Proposition
1. **Naviguer vers "Mes Propositions"**
2. **Cliquer sur une proposition** qui a des réponses au questionnaire
3. **Observer les logs**

#### ✅ Vérifier dans Console Flutter

**Logs attendus:**
```
📥 Chargement détails proposition [ID]...
=== DONNÉES REÇUES DU SERVEUR ===
✅ Subscription reçue: OUI
✅ User reçue: OUI
✅ questionnaire_reponses reçue: OUI
📋 Détail questionnaire_reponses:
  - Type: List avec X éléments
    Q: "Avez-vous des antécédents?" → NON
    Q: "Fumez-vous?" → OUI

🔍 _getQuestionnaireMedicalReponses() appelé
  ✅ questionnaire_reponses trouvé: List
  ✅ Format liste détecté: X réponses
```

#### ✅ Vérifier Backend Logs (Terminal)

**Logs attendus:**
```
=== RÉCUPÉRATION DÉTAILS SUBSCRIPTION/CONTRAT ===
📋 ID: [ID]
👤 User ID: [ID]
📋 QUESTIONNAIRE MÉDICAL: X réponses récupérées pour souscription [ID]
✅ RETOUR COMPLET: subscription + user + X questionnaire_reponses
```

---

### Phase 4: Vérifier l'Affichage Visual
1. **Sur la page de détails de proposition**, chercher la section **"Questionnaire Médical"**
2. **Observer le contenu**:
   - ✅ Chaque question doit apparaître dans une **boîte numérotée**
   - ✅ Le texte de la question doit être en **BOLD bleu** (bleuCoris)
   - ✅ La réponse doit s'afficher en **VERT** (vertSucces) sous la question
   - ✅ Format: `1. [Question]` puis `Réponse: [Valeur]`

**Exemple attendu:**
```
1. Avez-vous des antécédents?
   Réponse: NON

2. Fumez-vous?
   Réponse: OUI - Depuis 5 ans
```

---

## 🐛 DIAGNOSTIQUE DES PROBLÈMES

### ❌ "Questionnaire non affiché dans la proposition"

**Étapes de diagnostic:**

1. **Vérifier le log Flutter:**
   ```
   ✅ questionnaire_reponses reçue: OUI/NON ?
   ```
   - Si **NON**: le backend ne retourne pas les données
   - Si **OUI**: il y a un problème d'affichage

2. **Si NON:** Vérifier le log Backend
   ```
   📋 QUESTIONNAIRE MÉDICAL: X réponses récupérées ?
   ```
   - Si **0 réponses**: aucune donnée en BD → relancer Phase 1 & 2
   - Si **X réponses > 0**: il y a un bug dans `getSubscriptionWithUserDetails`

3. **Si OUI:** Vérifier le log `_getQuestionnaireMedicalReponses()`
   ```
   ✅ Format liste détecté: X réponses
   ```
   - Si **X > 0**: le rendu doit marcher → vérifier CSS/layout
   - Si **X = 0**: format data incorrect → check le log du champ reponses

---

### ❌ "Base de données vide: aucune réponse enregistrée"

**Étapes de diagnostic:**

1. **Vérifier le log Backend save:**
   ```
   💾 Sauvegarde questionnaire médical pour souscription: [ID]
   📝 Nombre de réponses: 0
   ```
   - Si **0 réponses**: Flutter n'envoie rien → check widget validation
   - Si **> 0 réponses**: check le log COMMIT

2. **Vérifier dans BD:**
   ```sql
   SELECT COUNT(*) FROM souscription_questionnaire 
   WHERE subscription_id = [ID];
   ```
   - Si **0**: transaction n'a pas committé → check logs pour ROLLBACK
   - Si **> 0**: données présentes mais pas retrievable?

---

### ❌ "Les données sont en BD mais ne s'affichent pas"

**Étapes de diagnostic:**

1. **Vérifier le SQL backend:**
   ```
   🔍 VÉRIFICATION: Z réponses totales en BD pour souscription [ID]
   ```
   - Doit être **> 0**

2. **Vérifier le retrieval:**
   ```
   📋 QUESTIONNAIRE MÉDICAL: X réponses récupérées pour souscription [ID]
   ```
   - Doit être **> 0** et égal au compte BD

3. **Si les 2 affichent 0**: Il y a un problème de **WHERE clause** dans le SQL
   - Vérifier que `subscription_id` est correct (pas `souscription_id`)
   - Vérifier que les types de colonnes matchent

---

## 📊 TABLEAU RÉCAPITULATIF

| Étape | Log Attendu | Bon Signe | Mauvais Signe |
|-------|-----------|-----------|--------------|
| **Save** | `💾 Sauvegarde...` | `✅ Questionnaire médical sauvegardé - X/Y` | `❌ 0/0 réponses` |
| **DB Check** | `SELECT * FROM souscription_questionnaire` | Lignes présentes | Aucune ligne |
| **Retrieve** | `📋 QUESTIONNAIRE MÉDICAL: X réponses` | `X > 0` | `0 réponses` |
| **Send Flutter** | `✅ questionnaire_reponses reçue: OUI` | Data présente | Data null |
| **Parse Flutter** | `✅ Format liste détecté: X réponses` | `X > 0` | `X = 0` |
| **Render** | Visual section apparaît | Boîtes + texte | Rien ou erreur |

---

## 🔧 SOLUTIONS RAPIDES

### Si questionnaire ne s'affiche pas:

1. **Effacer le cache Flutter**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Vérifier les types PostgreSQL**
   ```sql
   \d souscription_questionnaire
   ```
   Confirmer que `subscription_id` est INT ou BIGINT

3. **Forcer un rechargement**
   - Relancer l'app
   - Accéder à nouveau à la proposition

4. **Vérifier la session utilisateur**
   - Le backend doit avoir `req.user.id` valide
   - Vérifier permission (propriétaire ou commercial)

---

## 📝 NOTES IMPORTANTES

1. **Les logs incluent:**
   - 💾 Timestamp implicite (serveur logs timestamp automatiquement)
   - 📋 Détails de chaque réponse
   - 🔍 Vérifications de cohérence BD
   - ✅ Confirmations de succès

2. **Pour désactiver les logs:**
   - Remplacer `print()` par commentaires `// print()`
   - Remplacer `console.log()` par commentaires `// console.log()`

3. **Pour activer logs en production:**
   - Garder les logs avec emojis pour visibilité
   - Ignorer les logs techniques (developer.log)

---

## 🎯 OBJECTIF FINAL

Une fois tous les logs ✅:
1. ✅ Données sauvegardées en BD avec vérification
2. ✅ Données retrievées du BD avec log détail
3. ✅ Données envoyées à Flutter complètes
4. ✅ Flutter parse les données correctement
5. ✅ UI affiche les questions et réponses structurées
6. ✅ Test end-to-end réussi

**Si tous les logs affichent ✅, le système fonctionne correctement!**

