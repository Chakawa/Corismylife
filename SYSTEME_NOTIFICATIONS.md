# 🔔 SYSTÈME DE NOTIFICATIONS - MYCORIS

## Vue d'ensemble

Le système de notifications permet d'informer automatiquement les clients sur les actions importantes effectuées sur leur compte.

---

## 📋 Types de notifications implémentées

### 1. **Souscription créée** ✅
- **Quand** : Dès qu'un client (ou un commercial pour un client) crée une souscription
- **Message** : "Votre souscription [PRODUIT] ([CODE]) a été enregistrée avec succès. Vous recevrez bientôt votre proposition."

### 2. **Paiement en attente** ⏳
- **Quand** : Immédiatement après la création de souscription (statut = proposition)
- **Message** : "Votre souscription [PRODUIT] est en attente de paiement. Montant : [MONTANT] FCFA. Veuillez effectuer le paiement pour activer votre contrat."

### 3. **Paiement confirmé** ✅
- **Quand** : Après validation du paiement par Wave, Orange Money ou autre
- **Message** : "Votre paiement de [MONTANT] FCFA via [MÉTHODE] pour [PRODUIT] a été confirmé. Votre contrat sera bientôt activé."

### 4. **Changement de mot de passe** 🔒
- **Quand** : Après modification réussie du mot de passe
- **Message** : "Votre mot de passe a été modifié avec succès. Si vous n'êtes pas à l'origine de cette modification, contactez immédiatement le support."

### 5. **Proposition générée** 📝
- **Quand** : Quand la proposition est prête pour consultation
- **Message** : "Votre proposition [PRODUIT] ([NUMÉRO]) est prête. Consultez-la dans 'Mes Propositions' et procédez au paiement pour activer votre contrat."

### 6. **Contrat généré** 📋
- **Quand** : Après validation et génération du contrat final
- **Message** : "Votre contrat [PRODUIT] ([NUMÉRO]) est disponible. Vous pouvez le consulter dans la section 'Mes Contrats'."

### 7. **Souscription modifiée** 🔄
- **Quand** : Après modification d'une souscription existante
- **Message** : "Votre souscription [PRODUIT] a été modifiée avec succès. Une nouvelle proposition sera générée."

---

## 🛠️ Architecture technique

### Fichiers créés/modifiés :

1. **`services/notificationHelper.js`** (NOUVEAU)
   - Helper contenant toutes les fonctions pour créer des notifications facilement
   - Fonctions disponibles :
     - `notifySubscriptionCreated()`
     - `notifyPaymentPending()`
     - `notifyPaymentSuccess()`
     - `notifyPaymentFailed()`
     - `notifyPasswordChanged()`
     - `notifyPropositionGenerated()`
     - `notifyContractGenerated()`
     - `notifySubscriptionModified()`
     - `notifyProfileUpdated()`
     - `notifyDocumentUploaded()`

2. **`controllers/subscriptionController.js`** (MODIFIÉ)
   - Ajout de notifications lors de :
     - Création de souscription
     - Paiement en attente automatiquement

3. **`controllers/authController.js`** (MODIFIÉ)
   - Ajout de notification lors du changement de mot de passe

4. **`services/notification_service.dart`** (EXISTANT - Flutter)
   - Déjà fonctionnel
   - Récupère et affiche les notifications

5. **`features/client/presentation/screens/notifications_screen.dart`** (EXISTANT - Flutter)
   - Interface utilisateur pour afficher les notifications
   - Déjà opérationnelle

---

## 📊 Table de base de données

La table `notifications` existe déjà avec la structure suivante :

```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🚀 Comment ajouter de nouvelles notifications

### Étape 1 : Ajouter le type dans `notificationHelper.js`

```javascript
const NOTIFICATION_TYPES = {
  // ... types existants
  VOTRE_NOUVEAU_TYPE: 'votre_nouveau_type',
};
```

### Étape 2 : Créer une fonction helper

```javascript
async function notifyVotreNouvelleAction(userId, param1, param2) {
  const title = '🎉 Titre de votre notification';
  const message = `Message avec ${param1} et ${param2}`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.VOTRE_NOUVEAU_TYPE,
    title,
    message
  );
}
```

### Étape 3 : Utiliser dans le contrôleur approprié

```javascript
const { notifyVotreNouvelleAction } = require('../services/notificationHelper');

// Dans votre fonction
try {
  await notifyVotreNouvelleAction(userId, param1, param2);
} catch (error) {
  console.error('❌ Erreur notification:', error);
  // Ne pas bloquer l'opération principale
}
```

---

## 📱 Côté Flutter (Client)

### Comment les notifications s'affichent :

1. **Badge sur l'icône** : Nombre de notifications non lues
2. **Page dédiée** : `notifications_screen.dart` avec liste complète
3. **Marquage automatique** : Les notifications deviennent "lues" quand on clique dessus

### Code Flutter déjà en place :

```dart
// Récupérer les notifications
final data = await NotificationService.getNotifications();

// Compter les non lues
final count = await NotificationService.getUnreadCount();

// Marquer comme lue
await NotificationService.markAsRead(notificationId);

// Tout marquer comme lu
await NotificationService.markAllAsRead();
```

---

## 🔄 Notifications futures à implémenter

### Suggérées pour compléter le système :

1. **Document téléchargé** 📄
   - Quand le client upload sa pièce d'identité

2. **Profil mis à jour** ✏️
   - Quand le client modifie ses informations personnelles

3. **Paiement échoué** ❌
   - En cas d'échec du paiement Wave/Orange Money

4. **Rappel de paiement** ⏰
   - X jours après création si paiement non effectué

5. **Anniversaire de contrat** 🎂
   - Notification annuelle de renouvellement

### Implémentation :

Modifier les contrôleurs concernés en ajoutant :

```javascript
const { notifyDocumentUploaded } = require('../services/notificationHelper');

// Après upload de document
await notifyDocumentUploaded(userId, 'Pièce d\'identité');
```

---

## ✅ Tests à effectuer

1. **Créer une souscription** → Vérifier notification "Souscription créée" + "Paiement en attente"
2. **Changer le mot de passe** → Vérifier notification "Mot de passe modifié"
3. **Consulter les notifications** → Aller dans l'app Flutter, page Notifications
4. **Marquer comme lu** → Cliquer sur une notification
5. **Badge de compteur** → Vérifier le nombre affiché

---

## 🐛 Dépannage

### Problème : Les notifications ne s'affichent pas

**Solutions :**
1. Vérifier que la table `notifications` existe dans PostgreSQL
2. Vérifier que le serveur Node.js est démarré
3. Vérifier les logs serveur : `console.log` dans `notificationHelper.js`
4. Tester l'endpoint : `GET /api/notifications` avec Postman
5. Vérifier le token JWT dans les headers

### Problème : Erreur lors de la création de notification

**Solutions :**
1. La notification ne doit **jamais bloquer** l'opération principale
2. Toujours wrapper dans un try-catch
3. Logger l'erreur mais continuer l'exécution

```javascript
try {
  await notifySubscriptionCreated(...);
} catch (error) {
  console.error('❌ Erreur notification:', error);
  // Ne pas throw, ne pas bloquer
}
```

---

## 📞 Support

Pour toute question sur le système de notifications :
- Consulter ce document
- Vérifier les logs serveur
- Tester avec Postman les endpoints `/api/notifications`

---

**Date de création** : 22 janvier 2026  
**Dernière mise à jour** : 22 janvier 2026  
**Version** : 1.0
