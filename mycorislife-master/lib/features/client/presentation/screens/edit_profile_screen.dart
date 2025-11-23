import 'package:flutter/material.dart';
import 'package:mycorislife/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:mycorislife/config/app_config.dart';
import 'photo_viewer_page.dart';

/// Page de modification du profil utilisateur
/// Permet à l'utilisateur de modifier ses informations personnelles
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ===================================
  // CONSTANTES DE COULEURS
  // ===================================
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;
  static const Color fondGris = Color(0xFFF0F4F8);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color vertSucces = Color(0xFF10B981);

  // ===================================
  // CONTRÔLEURS DE FORMULAIRE
  // ===================================
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  // ===================================
  // VARIABLES D'ÉTAT
  // ===================================
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _civilite;
  String? _photoUrl; // URL de la photo actuelle
  File? _selectedPhoto; // Photo sélectionnée mais pas encore uploadée
  final ImagePicker _picker = ImagePicker();

  // ===================================
  // INITIALISATION
  // ===================================
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Charge les données utilisateur depuis l'API
  Future<void> _loadUserData() async {
    try {
      final user = await UserService.getProfile();
      setState(() {
        _nomController.text = user['nom'] ?? '';
        _prenomController.text = user['prenom'] ?? '';
        _emailController.text = user['email'] ?? '';
        _telephoneController.text = user['telephone'] ?? '';
        _adresseController.text = user['adresse'] ?? '';
        _civilite = user['civilite'];
        _photoUrl = user['photo_url'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sauvegarde les modifications du profil
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Appeler l'API pour mettre à jour le profil
      await UserService.updateProfile(
        civilite: _civilite ?? 'M.',
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim(),
      );

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: vertSucces,
        ),
      );

      // Retourner à la page précédente
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour du profil'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Sélectionne et upload une photo de profil
  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null) return;

      // Essayer de recadrer l'image (optionnel)
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recadrer la photo',
              toolbarColor: bleuCoris,
              toolbarWidgetColor: blanc,
              backgroundColor: Colors.black,
              activeControlsWidgetColor: bleuCoris,
              lockAspectRatio: false,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Recadrer la photo',
              aspectRatioLockEnabled: false,
              resetAspectRatioEnabled: true,
            ),
          ],
        );
      } catch (cropError) {
        debugPrint('⚠️ Erreur recadrage (utilisation image originale): $cropError');
        // Si le recadrage échoue, utiliser l'image originale
        croppedFile = null;
      }

      // Utiliser l'image recadrée si disponible, sinon l'originale
      final imagePathToUpload = croppedFile?.path ?? image.path;

      setState(() {
        _selectedPhoto = File(imagePathToUpload);
        _isUploadingPhoto = true;
      });

      final photoUrl = await UserService.uploadPhoto(imagePathToUpload);
      
      setState(() {
        _photoUrl = photoUrl;
        _selectedPhoto = null;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo mise à jour avec succès'),
            backgroundColor: vertSucces,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur upload photo: $e');
      setState(() {
        _isUploadingPhoto = false;
        _selectedPhoto = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // ===================================
  // INTERFACE UTILISATEUR
  // ===================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondGris,
      appBar: AppBar(
        title: const Text(
          'Modifier mon profil',
          style: TextStyle(color: blanc, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bleuCoris,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: blanc),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo de profil avec upload
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                              onLongPress: (_photoUrl != null || _selectedPhoto != null)
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PhotoViewerPage(
                                            photoUrl: _photoUrl,
                                            localFile: _selectedPhoto,
                                            title: 'Photo de profil',
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bleuCoris, width: 3),
                                ),
                                child: ClipOval(
                                  child: _selectedPhoto != null
                                      ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                                      : _photoUrl != null
                                          ? Image.network(
                                              '${AppConfig.baseUrl}$_photoUrl',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: bleuCoris),
                                            )
                                          : Container(
                                              color: bleuCoris.withOpacity(0.1),
                                              child: const Icon(Icons.person, size: 50, color: bleuCoris),
                                            ),
                                ),
                              ),
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: blanc),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: bleuCoris,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 20, color: blanc),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Appuyez pour changer la photo',
                              style: TextStyle(fontSize: 12, color: grisTexte),
                            ),
                            if (_photoUrl != null || _selectedPhoto != null)
                              Text(
                                'Maintenez appuyé pour voir',
                                style: TextStyle(fontSize: 11, color: grisTexte.withOpacity(0.7)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Section Civilité
                      _buildSectionTitle('Civilité'),
                      _buildCiviliteSelector(),
                      const SizedBox(height: 24),

                      // Section Informations personnelles
                      _buildSectionTitle('Informations personnelles'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nomController,
                        label: 'Nom',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _prenomController,
                        label: 'Prénom',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre prénom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section Contact
                      _buildSectionTitle('Contact'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _telephoneController,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre numéro de téléphone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section Adresse
                      _buildSectionTitle('Adresse'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _adresseController,
                        label: 'Adresse complète',
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 40),

                      // Bouton de sauvegarde
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bleuCoris,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: blanc,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer les modifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: blanc,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Construit un titre de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: bleuCoris,
      ),
    );
  }

  /// Construit le sélecteur de civilité
  Widget _buildCiviliteSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCiviliteOption('Monsieur', 'M'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCiviliteOption('Madame', 'Mme'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCiviliteOption('Mademoiselle', 'Mlle'),
          ),
        ],
      ),
    );
  }

  /// Construit une option de civilité
  Widget _buildCiviliteOption(String label, String value) {
    final isSelected = _civilite == value;

    return GestureDetector(
      onTap: () => setState(() => _civilite = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? bleuCoris : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? bleuCoris : grisTexte.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? blanc : grisTexte,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Construit un champ de texte stylisé
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: grisTexte),
          prefixIcon: Icon(icon, color: bleuCoris),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: blanc,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
