# ✅ CHECKLIST: Questionnaire Médical - Points de Vérification

## 🚀 AVANT DE TESTER

- [ ] Backend Node.js en cours d'exécution
- [ ] PostgreSQL/mycorisdb accessible
- [ ] App Flutter compilée et prête
- [ ] Console/Logs visibles (ou terminal actif)

---

## 📥 PHASE 1: Remplir & Sauvegarder le Questionnaire

### Frontend (Flutter)
- [ ] Créer une nouvelle souscription (Étude/Familis/Sérénité)
- [ ] Naviguer jusqu'au questionnaire médical
- [ ] Remplir au minimum 2 questions (OUI et NON)
- [ ] Cliquer "Valider" ou "Suivant"

### ✅ Vérifier les Logs
- [ ] Console Flutter affiche: `✅ Questionnaire valid, réponses: {...}`
- [ ] Backend log: `💾 Sauvegarde questionnaire médical pour souscription:`
- [ ] Backend log: `✅ Questionnaire médical sauvegardé - X/Y réponses enregistrées`

---

## 💾 PHASE 2: Vérifier la Base de Données

### Requête SQL
```sql
SELECT id, subscription_id, question_id, reponse_oui_non, reponse_text 
FROM souscription_questionnaire 
WHERE subscription_id = [VOTRE_ID]
ORDER BY id;
```

### ✅ Vérifier les Résultats
- [ ] Au moins 1 ligne trouvée
- [ ] `subscription_id` correspond à la souscription créée
- [ ] `reponse_oui_non` contient 'OUI' ou 'NON'
- [ ] Colonnes matchent: `reponse_text`, `reponse_detail_1/2/3` (pas `reponse_texte`)

---

## 🔄 PHASE 3: Charger les Détails de la Proposition

### Frontend (Flutter)
- [ ] Naviguer vers "Mes Propositions"
- [ ] Cliquer sur la proposition remplie au Phase 1
- [ ] Attendre le chargement complet

### ✅ Vérifier les Logs Flutter
- [ ] Console affiche: `📥 Chargement détails proposition [ID]...`
- [ ] Console affiche: `✅ questionnaire_reponses reçue: OUI`
- [ ] Console affiche: `📋 Détail questionnaire_reponses:`
- [ ] Console affiche: `✅ Format liste détecté: X réponses`

### ✅ Vérifier les Logs Backend
- [ ] Terminal affiche: `📋 QUESTIONNAIRE MÉDICAL: X réponses récupérées`
- [ ] Terminal affiche: `📝 Détail questionnaire:` avec questions/réponses
- [ ] Terminal affiche: `✅ RETOUR COMPLET: subscription + user + X questionnaire_reponses`

---

## 🎨 PHASE 4: Vérifier l'Affichage Visual

### Sur la Page de Détails de Proposition
- [ ] Section "Questionnaire Médical" est visible
- [ ] Les questions apparaissent avec numéros (1, 2, 3...)
- [ ] Les questions sont en **BOLD BLEU** (bleuCoris)
- [ ] Les réponses s'affichent en **VERT** (vertSucces)
- [ ] Format correct: Question sur une ligne, réponse en-dessous

### Exemple Attendu:
```
📋 Questionnaire Médical

1. Avez-vous des antécédents?
   Réponse: NON

2. Fumez-vous?
   Réponse: OUI - Depuis 5 ans
```

---

## 🐛 DÉPANNAGE RAPIDE

### ❌ Questionnaire ne s'affiche pas

1. [ ] Vérifier Flutter log: `questionnaire_reponses reçue: OUI` ?
   - Si **NON**: Vérifier BD si données existent
   - Si **OUI**: Vérifier layout/CSS

2. [ ] Vérifier Backend log: `X réponses récupérées` > 0 ?
   - Si **0**: Aucune donnée en BD
   - Si **> 0**: Problème transmission

3. [ ] Relancer l'app: `flutter clean && flutter pub get && flutter run`

### ❌ Données en BD mais pas retrievable

1. [ ] SQL Verify:
   ```sql
   SELECT COUNT(*) FROM souscription_questionnaire 
   WHERE subscription_id = [ID];
   ```
   [ ] Résultat: > 0

2. [ ] Vérifier les noms colonnes:
   ```sql
   \d souscription_questionnaire
   ```
   [ ] Confirmer: `subscription_id`, `reponse_text`, `reponse_detail_1/2/3`
   [ ] JAMAIS: `souscription_id`, `reponse_texte`, `detail_1/2/3`

### ❌ Validation questionnaire échoue

1. [ ] Vérifier Flutter log: `✅ Questionnaire valid` ?
   - Si absent: Widget validation bug
   
2. [ ] Vérifier réponses envoyées:
   ```
   📝 Nombre de réponses: X
   ```
   [ ] X > 0 et X = nombre questions

---

## 📊 RECAP DES POINTS DE VÉRIFICATION

| # | Point | Status | Notes |
|----|-------|--------|-------|
| 1 | Flutter: Questionnaire remplit | ☐ | Min 2 réponses |
| 2 | Backend: Save logs OK | ☐ | Doit voir `✅ Questionnaire médical sauvegardé` |
| 3 | BD: Données present | ☐ | SQL SELECT retourne lignes |
| 4 | Backend: Retrieve logs OK | ☐ | Doit voir `X réponses récupérées` |
| 5 | Flutter: Data reçue | ☐ | `questionnaire_reponses reçue: OUI` |
| 6 | Flutter: Parse OK | ☐ | `Format liste détecté: X réponses` |
| 7 | Visual: Affichage correct | ☐ | Boîtes numérotées, questions en bleu, réponses en vert |

---

## 🎯 VALIDATION FINALE

Si tous les points ☑️, alors:

✅ **Le questionnaire fonctionne end-to-end:**
1. ✅ Réponses sont sauvegardées en BD
2. ✅ Réponses sont retrievées du BD avec tous les détails
3. ✅ Réponses sont envoyées à Flutter correctement
4. ✅ Flutter parse et affiche les réponses structurées
5. ✅ UI présente les questions et réponses de façon lisible

**SYSTÈME VALIDE ET PRÊT POUR PRODUCTION!**

---

## 🆘 BESOIN D'AIDE?

Si vous rencontrez un problème:
1. Consulter la section "Dépannage Rapide" ci-dessus
2. Vérifier le log correspondant dans `DEBUG_QUESTIONNAIRE_SETUP.md`
3. Vérifier la BD avec les requêtes SQL fournies
4. Si toujours bloqué: collecter tous les logs et les envoyer

