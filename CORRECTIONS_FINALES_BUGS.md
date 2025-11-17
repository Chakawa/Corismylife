# 🐛 CORRECTIONS FINALES - LISTE DES BUGS

## ✅ CORRECTIONS EFFECTUÉES (2/9)

### 1. ✅ Noms CORIS SOLIDARITÉ non affichés
**Problème** : Les noms des conjoints/enfants/ascendants ne s'affichaient pas  
**Solution** : Ajout de debug + essai de plusieurs variantes de noms  
**Fichier** : `proposition_detail_page.dart`  
**Statut** : ✅ CORRIGÉ

### 2. ✅ Déconnexion dans profil ne fonctionnait pas
**Problème** : Cliquer sur "Se déconnecter" dans le profil ne déconnectait pas vraiment  
**Solution** : Ajout de `storage.deleteAll()` et redirection vers `/login`  
**Fichiers** : `profil_screen.dart`  
**Statut** : ✅ CORRIGÉ

---

## ⏳ CORRECTIONS À FAIRE (7/9)

### 3. ⏳ Chargement profil automatique
**Problème** : Les infos du profil ne s'affichent pas automatiquement  
**Solution à implémenter** :
- Vérifier que `_loadUserProfile()` est appelé dans `initState`
- Vérifier l'API `/api/users/profile`
- Afficher un loader pendant le chargement
- Gérer les erreurs proprement

**Fichiers à modifier** :
- `profil_screen.dart`
- `user_service.dart`

---

### 4. ⏳ Photo dans modification profil
**Problème** : Pas d'option pour ajouter une photo dans la page de modification  
**Solution à implémenter** :
- Ajouter un widget pour sélectionner une photo (image_picker)
- Ajouter un bouton "Changer la photo"
- Upload avec l'API `/api/users/upload-photo`
- Afficher un aperçu de la photo

**Fichiers à modifier** :
- `edit_profile_screen.dart`

**Code à ajouter** :
```dart
import 'package:image_picker/image_picker.dart';

// Ajouter dans la classe
File? _imageFile;
final ImagePicker _picker = ImagePicker();

// Fonction pour sélectionner une photo
Future<void> _pickImage() async {
  final pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
  );
  
  if (pickedFile != null) {
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }
}

// Widget pour afficher la photo
Widget _buildPhotoSection() {
  return Stack(
    children: [
      CircleAvatar(
        radius: 60,
        backgroundImage: _imageFile != null
            ? FileImage(_imageFile!)
            : NetworkImage(photoUrl) as ImageProvider,
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: IconButton(
          icon: Icon(Icons.camera_alt),
          onPressed: _pickImage,
        ),
      ),
    ],
  );
}
```

---

### 5. ⏳ Optimiser notifications (trop lent)
**Problème** : Les notifications mettent trop de temps à charger  
**Solutions à implémenter** :
- Ajouter un cache local (SharedPreferences)
- Afficher les données en cache pendant le chargement
- Pagination des notifications (charger 20 à la fois)
- Optimiser la requête SQL côté backend

**Fichiers à modifier** :
- `notifications_screen.dart`
- `notification_service.dart`
- `notificationController.js` (backend)

**Optimisations backend** :
```sql
-- Ajouter un index
CREATE INDEX idx_notifications_created_at_desc 
ON notifications(user_id, created_at DESC);

-- Limiter les résultats
SELECT * FROM notifications 
WHERE user_id = $1 
ORDER BY created_at DESC 
LIMIT 20;
```

---

### 6. ⏳ Changement mot de passe ne fonctionne pas
**Problème** : L'utilisateur ne peut pas changer son mot de passe  
**Solution à implémenter** :
- Créer une page `change_password_screen.dart`
- Utiliser l'API `/api/users/change-password`
- Valider le mot de passe actuel
- Vérifier que le nouveau mot de passe est fort

**Fichiers à créer** :
- `change_password_screen.dart`

**Code à ajouter** :
```dart
class ChangePasswordScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Changer le mot de passe')),
      body: Form(
        child: Column(
          children: [
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mot de passe actuel'),
            ),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
            ),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirmer'),
            ),
            ElevatedButton(
              onPressed: () async {
                await UserService.changePassword(
                  oldPassword: oldPassword,
                  newPassword: newPassword,
                );
              },
              child: Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 7. ⏳ Authentification deux étapes
**Problème** : L'auth à deux étapes ne fonctionne pas  
**Solution à implémenter** :
- Utiliser le package `local_auth` pour biométrie
- Ajouter une option dans les paramètres
- Sauvegarder la préférence dans secure storage
- Vérifier avant chaque action sensible

**Packages à ajouter** :
```yaml
dependencies:
  local_auth: ^2.1.0
```

**Code à ajouter** :
```dart
import 'package:local_auth/local_auth.dart';

final LocalAuthentication auth = LocalAuthentication();

Future<bool> _authenticateWithBiometrics() async {
  try {
    return await auth.authenticate(
      localizedReason: 'Veuillez vous authentifier',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  } catch (e) {
    return false;
  }
}
```

---

### 8. ⏳ Centre d'aide (appel direct)
**Problème** : Le centre d'aide ne fonctionne pas, impossible d'appeler  
**Solution à implémenter** :
- Utiliser le package `url_launcher` pour appeler
- Ajouter un bouton "Appeler le support"
- Ajouter un numéro de téléphone

**Packages à ajouter** :
```yaml
dependencies:
  url_launcher: ^6.2.0
```

**Code à ajouter dans profil_screen.dart** :
```dart
import 'package:url_launcher/url_launcher.dart';

void _showHelpAndSupport(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.phone),
            title: Text('Appeler le support'),
            subtitle: Text('+225 XX XX XX XX XX'),
            onTap: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '+225XXXXXXXXX');
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Envoyer un email'),
            subtitle: Text('support@coris.ci'),
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@coris.ci',
                query: 'subject=Aide MyCorisLife',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
          ),
        ],
      ),
    ),
  );
}
```

---

### 9. ⏳ Rattacher proposition
**Problème** : Impossible de rattacher une proposition  
**Solution à implémenter** :
- Créer une page `attach_proposition_screen.dart`
- Scanner un QR code OU entrer un numéro de proposition
- Utiliser l'API pour rattacher
- Afficher la proposition dans "Mes Propositions"

**Packages à ajouter** :
```yaml
dependencies:
  qr_code_scanner: ^1.0.1
```

**Code à ajouter** :
```dart
class AttachPropositionScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rattacher une proposition')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Scanner QR code
            },
            child: Text('Scanner un QR Code'),
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Numéro de proposition',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Appeler l'API pour rattacher
              await SubscriptionService.attachProposition(numeroProposition);
            },
            child: Text('Rattacher'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 RÉSUMÉ

```
┌────────────────────────────────────────────────────────┐
│               STATUT DES CORRECTIONS                   │
├────────────────────────────────────────────────────────┤
│ ✅ Noms CORIS SOLIDARITÉ          [FAIT]              │
│ ✅ Déconnexion profil              [FAIT]              │
│ ⏳ Chargement profil auto          [À FAIRE]           │
│ ⏳ Photo modification profil       [À FAIRE]           │
│ ⏳ Optimiser notifications         [À FAIRE]           │
│ ⏳ Changement mot de passe         [À FAIRE]           │
│ ⏳ Auth deux étapes                [À FAIRE]           │
│ ⏳ Centre d'aide (appel)           [À FAIRE]           │
│ ⏳ Rattacher proposition           [À FAIRE]           │
├────────────────────────────────────────────────────────┤
│ TOTAL : 2/9 complétés (22%)                           │
└────────────────────────────────────────────────────────┘
```

---

## 🎯 PROCHAINES ÉTAPES

**Pour toi** :
1. ✅ Lance l'app et teste les 2 corrections effectuées
2. ⏳ Je continue avec les 7 autres corrections
3. ⏳ On teste chaque correction une par une

**Priorité** :
1. Chargement profil (critique)
2. Photo profil (important)
3. Centre d'aide (important pour support)
4. Changement mot de passe (sécurité)
5. Optimiser notifications (performance)
6. Auth deux étapes (sécurité)
7. Rattacher proposition (fonctionnalité)

---

**Date** : 30 Octobre 2025  
**Statut** : 2/9 corrections effectuées  
**Prochaine action** : Corriger le chargement du profil















