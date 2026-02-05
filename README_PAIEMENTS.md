# 🔔 Système de Gestion des Paiements - CORIS

## Démarrage rapide

### Pour déployer en 20 minutes
```bash
# 1. Consulter le guide rapide
cat QUICK_DEPLOY.md

# 2. Exécuter la migration SQL
psql -U postgres -d mycoris -f update_contrats_table.sql

# 3. Installer et redémarrer
cd mycoris-master
npm install node-cron
node server.js

# 4. Rebuild Flutter
cd mycorislife-master
flutter clean && flutter pub get && flutter run
```

---

## Documentation complète

📚 **[INDEX GÉNÉRAL](./PAYMENT_TRACKING_INDEX.md)** - Naviguez dans toute la documentation

📋 **[GUIDE RAPIDE](./QUICK_DEPLOY.md)** - Déploiement en 20 minutes

📖 **[GUIDE COMPLET](./PAYMENT_TRACKING_DEPLOYMENT.md)** - Documentation détaillée

📊 **[RÉCAPITULATIF](./PAYMENT_TRACKING_SUMMARY.md)** - Vue d'ensemble technique

✅ **[CHECKLIST](./VERIFICATION_CHECKLIST.md)** - Validation post-déploiement

---

## Qu'est-ce qui a été ajouté ?

### Fonctionnalités
- ✅ Calcul automatique des prochaines dates de paiement
- ✅ Notifications SMS/Email 5 jours avant échéance
- ✅ Alertes visuelles dans l'application mobile
- ✅ Tri des contrats par urgence (retard > échéance proche > à jour)
- ✅ Dashboard de suivi pour les administrateurs

### Modifications
- **Base de données:** 7 colonnes + 2 fonctions + 2 triggers + 2 vues
- **Backend:** 1 service + 1 cron job + 2 routes API
- **Frontend:** 1 modèle enrichi + 1 page améliorée

### Aucune donnée perdue
✅ Migration additive (ALTER TABLE ADD COLUMN)  
✅ Backward compatible  
✅ Toutes les données existantes préservées

---

## Support

**Documentation:** Voir [PAYMENT_TRACKING_INDEX.md](./PAYMENT_TRACKING_INDEX.md)  
**Questions:** Consulter la section FAQ dans chaque guide  
**Problèmes:** Section Troubleshooting dans [QUICK_DEPLOY.md](./QUICK_DEPLOY.md)

---

**Version:** 1.0.0 | **Date:** 12 Janvier 2026 | **Status:** ✅ Production Ready
