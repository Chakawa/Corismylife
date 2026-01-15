# Documentation API - Changement de Mot de Passe

## 📱 Pour l'Application Mobile Flutter

### Endpoint: Changement de Mot de Passe (Self-Service)

**URL**: `POST /api/auth/change-password`

**Authentification**: Requiert un token JWT valide (utilisateur connecté)

**Headers**:
```json
{
  "Authorization": "Bearer <JWT_TOKEN>",
  "Content-Type": "application/json"
}
```

**Body Request**:
```json
{
  "oldPassword": "ancien_mot_de_passe",
  "newPassword": "nouveau_mot_de_passe"
}
```

**Validations**:
- `oldPassword` et `newPassword` sont requis
- `newPassword` doit contenir au moins 6 caractères
- L'ancien mot de passe doit être correct

**Réponses**:

✅ **Succès** (200):
```json
{
  "success": true,
  "message": "Mot de passe modifié avec succès"
}
```

❌ **Erreurs**:

**400 - Champs manquants**:
```json
{
  "success": false,
  "message": "Ancien et nouveau mot de passe requis"
}
```

**400 - Mot de passe trop court**:
```json
{
  "success": false,
  "message": "Le nouveau mot de passe doit contenir au moins 6 caractères"
}
```

**401 - Ancien mot de passe incorrect**:
```json
{
  "success": false,
  "message": "Ancien mot de passe incorrect"
}
```

**404 - Utilisateur non trouvé**:
```json
{
  "success": false,
  "message": "Utilisateur non trouvé"
}
```

**500 - Erreur serveur**:
```json
{
  "success": false,
  "message": "Erreur lors de la modification du mot de passe"
}
```

---

## 🔧 Exemple d'Implémentation Flutter

### 1. Créer le Service API

Fichier: `lib/services/auth_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String baseUrl = 'http://localhost:5000/api';
  
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Récupérer le token depuis le stockage local
      final token = await _getStoredToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur inconnue',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }
  
  Future<String> _getStoredToken() async {
    // Implémentez la récupération du token depuis SharedPreferences ou SecureStorage
    // Exemple:
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('auth_token') ?? '';
    return '';
  }
}
```

### 2. Créer le Widget de Changement de Mot de Passe

Fichier: `lib/features/profile/screens/change_password_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        // Succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retour à la page précédente
      } else {
        // Échec
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le mot de passe'),
        backgroundColor: const Color(0xFF002B6B), // CORIS Blue
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Ancien mot de passe
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  labelText: 'Ancien mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureOldPassword = !_obscureOldPassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ancien mot de passe requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nouveau mot de passe
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureNewPassword = !_obscureNewPassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nouveau mot de passe requis';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmation nouveau mot de passe
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmation requise';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002B6B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Modifier le mot de passe',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3. Ajouter le bouton dans le Profil

Fichier: `lib/features/profile/screens/profile_screen.dart`

```dart
// Ajoutez ce widget dans votre écran de profil

ListTile(
  leading: const Icon(Icons.lock_outline, color: Color(0xFF002B6B)),
  title: const Text('Modifier le mot de passe'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  },
),
```

---

## ✅ Checklist d'Implémentation

- [ ] Créer `lib/services/auth_service.dart` avec la méthode `changePassword`
- [ ] Implémenter la récupération du token JWT stocké
- [ ] Créer `lib/features/profile/screens/change_password_screen.dart`
- [ ] Ajouter le bouton "Modifier le mot de passe" dans l'écran de profil
- [ ] Tester avec un utilisateur commercial
- [ ] Gérer les erreurs réseau
- [ ] Ajouter des messages de succès/échec
- [ ] Tester la validation des champs

---

## 🧪 Tests Recommandés

1. **Test avec ancien mot de passe correct** → Doit réussir
2. **Test avec ancien mot de passe incorrect** → Doit échouer avec message d'erreur
3. **Test avec nouveau mot de passe < 6 caractères** → Doit échouer
4. **Test sans connexion internet** → Doit afficher erreur réseau
5. **Test de confirmation mot de passe différent** → Doit bloquer avant l'envoi

---

## 🎯 Remarques Importantes

- ✅ L'endpoint est **sécurisé** avec vérification JWT
- ✅ L'ancien mot de passe est **vérifié** avant modification
- ✅ Le nouveau mot de passe est **hashé** avec bcrypt (10 rounds)
- ✅ Aucune donnée sensible n'est loggée côté backend
- ⚠️ Ne jamais stocker les mots de passe en clair dans l'app
- ⚠️ Utiliser `flutter_secure_storage` pour le token JWT

---

## 📞 Support Backend

**Backend**: http://localhost:5000/api/auth/change-password

Le backend est **opérationnel** et prêt à recevoir les requêtes.

Contactez l'équipe backend si vous rencontrez des problèmes.
