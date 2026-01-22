# 📊 OÙ TROUVER LA COURBE D'UTILISATION ?

## 🎯 Localisation

La courbe se trouve dans la **PAGE TABLEAU DE BORD** (DashboardPage), PAS dans la page Utilisateurs.

### Étapes pour la trouver :

1. **Connectez-vous au Dashboard Admin** (http://localhost:3000 ou http://localhost:5173)

2. **Cliquez sur "Tableau de bord"** dans le menu à gauche (icône 📊)

3. **Faites défiler vers le BAS de la page**

4. **Cherchez la section avec le titre :**
   ```
   📱 Utilisation de l'Application Mobile
   Connexions réelles des clients sur les 12 derniers mois
   ```

5. **Juste en dessous, vous devriez voir :**
   - Soit un **graphique avec 2 lignes** (bleue et verte)
   - Soit un **message** : "Aucune donnée disponible"

---

## 🔍 Comment vérifier si ça fonctionne ?

### Option 1 : Console Navigateur (RECOMMANDÉ)

1. **Ouvrez les Outils de Développement** :
   - Appuyez sur `F12` dans Chrome/Edge
   - Ou clic droit > "Inspecter"

2. **Cliquez sur l'onglet "Console"**

3. **Rafraîchissez la page** (F5)

4. **Cherchez ces messages** dans la console :

```
📊 Données chargées: {...}
✅ Connexions mensuelles chargées: 1 mois
📈 Données détaillées: [...]
🔍 RENDU COURBE - connexionsMensuelles.length: 1
🔍 RENDU COURBE - données: [...]
```

**SI VOUS VOYEZ :**
- ✅ `connexionsMensuelles.length: 1` ou plus → **La courbe DEVRAIT s'afficher**
- ❌ `connexionsMensuelles.length: 0` → **Pas de données, normal de ne rien voir**
- ❌ `ERREUR: Pas de données de connexion` → **Problème API**

---

### Option 2 : Vérifier la base de données

```sql
-- Ouvrir pgAdmin ou exécuter dans psql
SELECT COUNT(*) FROM user_activity_logs WHERE type = 'login';
```

**Résultat attendu :** Au moins 1 connexion enregistrée

Si 0, c'est normal que la courbe ne s'affiche pas.

---

## 🎨 À quoi ressemble la courbe ?

### Si DONNÉES DISPONIBLES :
```
┌─────────────────────────────────────────────┐
│ 📱 Utilisation de l'Application Mobile      │
│    Connexions réelles des clients...        │
│    🔄 21 connexions                         │
├─────────────────────────────────────────────┤
│                                             │
│     📊 GRAPHIQUE AVEC :                     │
│     - Ligne bleue foncée (Total connexions)│
│     - Ligne verte (Utilisateurs uniques)   │
│     - Axe X : Jan, Fév, Mar...             │
│     - Axe Y : Nombre de connexions         │
│                                             │
└─────────────────────────────────────────────┘
```

### Si PAS DE DONNÉES :
```
┌─────────────────────────────────────────────┐
│ 📱 Utilisation de l'Application Mobile      │
│    Connexions réelles des clients...        │
│    🔄 0 connexions                          │
├─────────────────────────────────────────────┤
│                                             │
│              🔄 (Icône grise)              │
│        Aucune donnée disponible             │
│  Les statistiques de connexion s'afficheront│
│  dès que des utilisateurs se connecteront   │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🧪 Test rapide

### Pour générer des données de test :

1. **Connectez-vous 3-4 fois** depuis l'application Flutter

2. **Attendez 10 secondes**

3. **Rafraîchissez le Dashboard Admin** (F5)

4. **La courbe devrait apparaître** avec un point pour janvier 2026

---

## 🚨 Dépannage

### La courbe ne s'affiche toujours pas ?

**1. Vérifiez que vous êtes sur la bonne page :**
   - URL doit être : `http://localhost:3000/` (ou 5173)
   - Titre de la page : "Tableau de bord"
   - Vous voyez d'autres graphiques (Revenus, Activités, etc.)

**2. Vérifiez la console navigateur (F12) :**
   - Regardez s'il y a des erreurs en rouge
   - Copiez-collez les messages d'erreur

**3. Vérifiez l'API :**
   - Ouvrez un nouvel onglet
   - Collez cette URL (avec votre token admin) :
     ```
     http://localhost:5000/api/admin/stats/connexions-mensuelles?months=12
     ```
   - Vous devriez voir du JSON avec `"success": true`

**4. Vérifiez la base de données :**
   ```sql
   SELECT * FROM user_activity_logs 
   WHERE type = 'login' 
   ORDER BY created_at DESC 
   LIMIT 5;
   ```
   
   Si vide, connectez-vous depuis l'app Flutter.

---

## 📸 Capture d'écran attendue

La section se trouve **APRÈS** :
- Les cartes de statistiques (en haut)
- Le graphique "Revenus mensuels"
- Le graphique "Répartition par type de produit"
- Le graphique "Statut des souscriptions"

Et **AVANT** :
- Le graphique "Utilisation de l'application (30 derniers jours)" - celui avec les barres

---

## ✅ Checklist rapide

- [ ] Je suis sur la page "Tableau de bord" (pas "Utilisateurs")
- [ ] J'ai fait défiler vers le bas de la page
- [ ] J'ai ouvert la console (F12) pour voir les logs
- [ ] Je me suis connecté au moins 1 fois depuis l'app Flutter
- [ ] J'ai rafraîchi la page (F5)
- [ ] Je vois le titre "📱 Utilisation de l'Application Mobile"
- [ ] Je vois soit un graphique, soit "Aucune donnée disponible"

---

**Si après tout ça, la courbe ne s'affiche toujours pas, envoyez-moi :**
1. Les messages de la console (F12)
2. Le résultat de `SELECT COUNT(*) FROM user_activity_logs WHERE type='login';`
3. Une capture d'écran de votre page Tableau de bord
