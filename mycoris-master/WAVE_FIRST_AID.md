# 🚨 FIRST AID - AIDE D'URGENCE WAVE

**À lire en cas de problème**  
**Réponses en < 2 minutes**

---

## 🔴 "Rien ne se passe quand je clique PAYER"

**Cause #1:** .env pas mis à jour
```
✓ Ouvrir .env
✓ Chercher "votre-domaine" → Doit PAS être présent
✓ Remplacer par votre URL réelle
✓ Sauvegarder (Ctrl+S)
✓ Redémarrer npm start
✓ Retester
```

**Cause #2:** Serveur pas redémarré après changement .env
```
✓ Arrêter: Ctrl+C dans le terminal
✓ Attendre 3 secondes
✓ Relancer: npm start
✓ Retester
```

**Cause #3:** WAVE_API_KEY incorrect
```
✓ Vérifier que WAVE_API_KEY commence par: wave_ci_prod_
✓ Vérifier qu'il n'y a pas d'espace avant/après
✓ Redémarrer serveur
✓ Retester
```

---

## 🔴 "Erreur: port 5000 déjà utilisé"

**Solution rapide:**
```
✓ Appuyer Ctrl+C pour arrêter tout
✓ Attendre 10 secondes
✓ npm start
```

**Solution alternative:**
```
✓ Utiliser un autre port:
  PORT=3001 npm start
```

---

## 🔴 "Erreur: colonne user_id n'existe pas"

**C'est une erreur base de données**

```
✓ Vérifier que les migrations ont roulé:
  $env:PGPASSWORD = "Corisvie2025"
  psql -h 185.98.138.168 -p 5432 -U db_admin -d mycorisdb \
    -f "migrations\fix_notifications_user_id.sql"

✓ Redémarrer le serveur
✓ Retester
```

---

## 🔴 "Erreur: Impossible d'ouvrir Wave"

**Cause:** Backend ne retourne pas l'URL

```
✓ Vérifier les logs du serveur
✓ Chercher: "Session Wave" dans les logs
✓ Si absent: le backend n'appelle pas Wave API

Vérifier:
✓ WAVE_API_KEY = present et correct (wave_ci_prod_...)
✓ WAVE_DEV_MODE = false (production)
✓ Redémarrer serveur
✓ Retester
```

---

## 🔴 "Page success/error ne s'affiche pas"

**Cause:** Routes /wave-success ou /wave-error manquent

```
✓ Tester directement dans navigateur:
  http://localhost:5000/wave-success
  http://localhost:5000/wave-error

✓ Vérifier que fichier existe:
  routes/waveResponseRoutes.js

✓ Vérifier que intégré dans server.js:
  app.use('/', require('./routes/waveResponseRoutes'));

✓ Redémarrer serveur
✓ Retester
```

---

## 🟡 "Paiement fonctionne mais contrat pas créé"

**Cause:** Statut paiement pas reconnu

```
✓ Vérifier dans base de données:
  SELECT * FROM payment_transactions 
  WHERE created_at > now() - interval '1 minute'
  ORDER BY created_at DESC;

✓ Vérifier statut = 'paid' ou 'completed'
✓ Si autre: vérifier logs backend
```

---

## 🟡 "Notification pas reçue après paiement"

**Cause:** Erreur dans notificationHelper

```
✓ Vérifier que colonne updated_at existe:
  $env:PGPASSWORD = "Corisvie2025"
  psql -h 185.98.138.168 -p 5432 -U db_admin -d mycorisdb \
    -c "SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'notifications' AND column_name = 'updated_at'"

✓ Vérifier logs: "Notification créée" doit être visible
✓ Si erreur: redémarrer serveur
```

---

## 📋 VÉRIF RAPIDE (5 CHECKPOINTS)

```
Checkpoint 1:.env
  [ ] WAVE_SUCCESS_URL ne contient PAS "votre-domaine"
  [ ] WAVE_ERROR_URL ne contient PAS "votre-domaine"
  [ ] WAVE_WEBHOOK_URL ne contient PAS "votre-domaine"
  [ ] WAVE_API_KEY commence par "wave_ci_prod_"

Checkpoint 2: Serveur
  [ ] npm start sans erreur
  [ ] Pas de message ❌ au démarrage
  [ ] Port 5000 libre (ou le port configuré)

Checkpoint 3: Routes
  [ ] http://localhost:5000/wave-success retourne HTML
  [ ] http://localhost:5000/wave-error retourne HTML

Checkpoint 4: Base de Données
  [ ] SELECT * FROM payment_transactions LIMIT 1; (donne des résultats)
  [ ] Column user_id existe dans notifications
  [ ] Column updated_at existe dans notifications

Checkpoint 5: App Flutter
  [ ] Créer souscription → Sélectionner Wave → Cliquer Payer
  [ ] URL s'ouvre OU message d'erreur clair s'affiche
```

Si tous les ✅, le problème est ailleurs.

---

## 🔍 DIAGNOSTIC COMPLET (en cas de vraiment bloqué)

**Copier-coller ces commandes une par une:**

```powershell
# 1. Vérifier que PostgreSQL est accessible
$env:PGPASSWORD = "Corisvie2025"
psql -h 185.98.138.168 -p 5432 -U db_admin -d mycorisdb -c "SELECT version();"

# 2. Vérifier colonnes notifications
psql -h 185.98.138.168 -p 5432 -U db_admin -d mycorisdb \
  -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'notifications' ORDER BY column_name;"

# 3. Vérifier colonnes payment_transactions
psql -h 185.98.138.168 -p 5432 -U db_admin -d mycorisdb \
  -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'payment_transactions' ORDER BY column_name;"

# 4. Vérifier que server.js chargé new route
cd d:\CORIS\app_coris\mycoris-master
grep -n "waveResponseRoutes" server.js

# 5. Vérifier que .env a nouvelle config
grep "WAVE_SUCCESS_URL" .env
```

Si une commande échoue, c'est le problème!

---

## 📞 ESCALADE

Si rien ne marche après ça:

1. Lire `WAVE_DEPLOYMENT_GUIDE.md` (section Dépannage)
2. Lire `COMPLETE_SUMMARY.md` (pour contexte)
3. Vérifier que TOUS les fichiers ont été modifiés
4. Vérifier que git pull l'a bien fait
5. Vérifier que npm install a installé toutes dépendances

---

## ⏱️ SI TRÈS PRESSÉ

```
1. Ctrl+F dans .env "votre-domaine"
   → Si trouvé: MAUVAIS, remplacer tout de suite
   
2. npm start
   → Si erreur: attend 10 secondes, retry
   
3. Test dans navigateur: localhost:5000/wave-success
   → Si erreur HTML: grande baïe!
   
4. Créer souscription, paiement Wave
   → Doit ouvrir URL ou erreur claire
```

Si ces 4 étapes marchent, c'est bon!

---

## 📌 IMPORTANT À SE RAPPELER

❌ **Ne pas ignorer:** Remplacer les URLs dans .env  
❌ **Ne pas oublier:** Redémarrer après changement .env  
❌ **Ne pas faire:** Garder "votre-domaine.com" en production  
✅ **À faire:** Tester CHAQUE fois après changement  
✅ **À vérifier:** Les logs du serveur

---

**Document:** AIDE D'URGENCE  
**Créé:** 24/02/2026  
**À lire:** En cas de problème  
**Temps:** < 5 min pour trouver solution
