# Guide d'utilisation - Récapitulatif des Propositions

## 🎯 Objectif

Lorsqu'un utilisateur clique sur une proposition dans l'onglet "Mes propositions", il voit maintenant **exactement le même récapitulatif** que celui affiché lors de la souscription avant le paiement.

## 🚀 Démarrage rapide

### Backend

1. **Démarrer le serveur** :
   ```bash
   cd mycoris-master
   npm install  # Si ce n'est pas déjà fait
   npm start
   ```

2. **Vérifier que le serveur fonctionne** :
   - Le serveur devrait être accessible sur `http://localhost:3000` (ou votre port configuré)

3. **(Optionnel) Tester les routes** :
   ```bash
   # Configurer d'abord AUTH_TOKEN dans test-proposition-routes.js
   node test-proposition-routes.js
   ```

### Frontend Flutter

1. **Installer les dépendances** :
   ```bash
   cd mycorislife-master
   flutter pub get
   ```

2. **Lancer l'application** :
   ```bash
   flutter run
   ```

## 📱 Comment utiliser la fonctionnalité

### Depuis l'application mobile

1. **Créer une proposition** :
   - Allez dans "Produits" ou "Simulations"
   - Remplissez le formulaire de souscription
   - À l'étape finale, choisissez "Payer plus tard"
   - ✅ Une proposition est créée

2. **Voir les propositions** :
   - Allez dans l'onglet **"Mes Propositions"**
   - Vous verrez la liste de toutes vos propositions en attente

3. **Voir le récapitulatif** :
   - **Cliquez sur une proposition**
   - 🎉 Le récapitulatif complet s'affiche (identique à celui de la souscription)

4. **Affichage du récapitulatif** :
   - ✅ Informations Personnelles
   - ✅ Détails du Produit (capital, prime, durée, etc.)
   - ✅ Bénéficiaires et Contacts d'urgence
   - ✅ Documents joints
   - ✅ Avertissement de vérification

5. **Actions disponibles** :
   - **Refuser** : Refuse la proposition
   - **Accepter et Payer** : Affiche les options de paiement (Wave, Orange Money)

## 🔧 Configuration

### Configuration du backend

Le fichier `mycoris-master/controllers/subscriptionController.js` contient toutes les fonctions nécessaires.

**Aucune configuration supplémentaire requise** si votre base de données est déjà configurée.

### Configuration du frontend

Le fichier `mycorislife-master/lib/config/app_config.dart` doit pointer vers votre serveur backend :

```dart
class AppConfig {
  static const String baseUrl = 'http://localhost:3000'; // Ajustez selon votre configuration
}
```

## 🎨 Personnalisation

### Ajouter le support d'un nouveau produit

Pour afficher un récapitulatif personnalisé pour un nouveau produit :

1. **Ouvrir** `mycorislife-master/lib/core/widgets/subscription_recap_widgets.dart`

2. **Créer une nouvelle méthode** :
   ```dart
   static Widget buildMonNouveauProduitSection({
     required String productName,
     required dynamic prime,
     // ... autres paramètres
   }) {
     return buildRecapSection(
       'Produit Souscrit',
       Icons.mon_icone,
       maCouleur,
       [
         buildCombinedRecapRow('Label 1', valeur1, 'Label 2', valeur2),
         // ... autres lignes
       ],
     );
   }
   ```

3. **Utiliser dans** `proposition_detail_page.dart` :
   ```dart
   Widget _buildProductSection() {
     final productType = _getProductType().toLowerCase();
     
     if (productType.contains('mon_produit')) {
       return SubscriptionRecapWidgets.buildMonNouveauProduitSection(
         // ... paramètres
       );
     }
     
     // ... autres produits
   }
   ```

### Modifier les couleurs

Les couleurs sont définies dans `subscription_recap_widgets.dart` :

```dart
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color bleuSecondaire = Color(0xFF1E4A8C);
const Color blanc = Colors.white;
const Color fondCarte = Color(0xFFF8FAFC);
const Color grisTexte = Color(0xFF64748B);
const Color grisLeger = Color(0xFFF1F5F9);
const Color vertSucces = Color(0xFF10B981);
const Color orangeWarning = Color(0xFFF59E0B);
```

Modifiez ces valeurs pour changer les couleurs de l'application.

## 🐛 Dépannage

### Erreur "Token invalide" ou 401

**Cause** : Le token JWT est expiré ou invalide.

**Solution** :
1. Déconnectez-vous de l'application
2. Reconnectez-vous
3. Réessayez

### Erreur "Souscription non trouvée" ou 404

**Cause** : L'ID de la souscription est incorrect ou la souscription n'appartient pas à l'utilisateur connecté.

**Solution** :
1. Vérifiez que vous êtes connecté avec le bon compte
2. Vérifiez que la proposition existe bien

### Le récapitulatif ne s'affiche pas correctement

**Cause** : Les données sont mal formatées dans la base de données.

**Solution** :
1. Vérifiez la structure des données dans `souscriptiondata` (JSONB)
2. Assurez-vous que les champs requis sont présents :
   - `capital`
   - `prime`
   - `duree`
   - `duree_type`
   - `periodicite`
   - `beneficiaire` (nom, contact, lien_parente)
   - `contact_urgence` (nom, contact, lien_parente)

### Le serveur backend ne démarre pas

**Causes possibles** :
1. Port déjà utilisé
2. Problème de connexion à la base de données
3. Dépendances manquantes

**Solutions** :
1. Changez le port dans la configuration
2. Vérifiez les credentials de la base de données dans `db.js`
3. Exécutez `npm install`

## 📊 Structure des données

### Format de `souscriptiondata` (JSONB)

```json
{
  "capital": 5000000,
  "prime": 250000,
  "duree": 10,
  "duree_type": "années",
  "periodicite": "annuel",
  "date_effet": "2025-01-01T00:00:00.000Z",
  "date_echeance": "2035-01-01T00:00:00.000Z",
  "beneficiaire": {
    "nom": "Dupont Marie",
    "contact": "+225 01 02 03 04 05",
    "lien_parente": "Conjoint"
  },
  "contact_urgence": {
    "nom": "Dupont Paul",
    "contact": "+225 06 07 08 09 10",
    "lien_parente": "Parent"
  },
  "piece_identite": "CNI_12345.pdf"
}
```

## 📝 Changelog

### Version 1.0 (Octobre 2025)

#### Backend
- ✅ Ajout de `getSubscriptionWithUserDetails` pour récupérer proposition + utilisateur
- ✅ Ajout de `updatePaymentStatus` pour gérer les paiements
- ✅ Nouvelles routes : `GET /subscriptions/:id` et `PUT /subscriptions/:id/payment-status`

#### Frontend
- ✅ Création de `subscription_recap_widgets.dart` (widgets réutilisables)
- ✅ Refonte complète de `proposition_detail_page.dart`
- ✅ Interface identique au récapitulatif de souscription
- ✅ Support de tous les produits CORIS

## 🔗 Liens utiles

- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Express.js](https://expressjs.com/)
- [Documentation PostgreSQL JSONB](https://www.postgresql.org/docs/current/datatype-json.html)

## 💡 Conseils

1. **Testez toujours** avec de vraies données avant de déployer en production
2. **Sauvegardez** régulièrement votre base de données
3. **Utilisez** le fichier `test-proposition-routes.js` pour tester les routes backend
4. **Personnalisez** les widgets selon vos besoins spécifiques
5. **Documentez** vos modifications pour faciliter la maintenance

## 🆘 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs du serveur backend
2. Vérifiez les logs de l'application Flutter (console)
3. Consultez le fichier `MODIFICATIONS_RECAPITULATIF.md` pour plus de détails techniques

---

**Bon développement ! 🚀**
















