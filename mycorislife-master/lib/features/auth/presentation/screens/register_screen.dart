import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:mycorislife/services/auth_service.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  final PageController _controller = PageController();
  int _currentPage = 0;
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(4, (_) => GlobalKey<FormState>()); // Changé de 3 à 4
  final storage = const FlutterSecureStorage();

  // Contrôleur pour l'OTP
  final otpController = TextEditingController();

  // Timer pour l'OTP
  Timer? _otpTimer;
  int _otpTimeRemaining = 300; // 5 minutes en secondes
  bool _isOtpExpired = false;

  // Contrôleurs pour stocker les données
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  DateTime? dateNaissance;
  final lieuNaissanceController = TextEditingController();

  final emailController = TextEditingController();
  final telephoneController = TextEditingController();
  final adresseController = TextEditingController();
  String? selectedPays = 'Côte d’Ivoire';
  String selectedIndicatif = '+225';
  // États pour les validations en temps réel
  String? phoneErrorMessage;
  String? emailErrorMessage;
  bool isCheckingPhone = false;
  bool isCheckingEmail = false;
  final numeroPieceController = TextEditingController();
  final villeDelivranceController = TextEditingController();
  DateTime? dateDelivrance;
  DateTime? dateExpiration;
  final autoriteDelivranceController = TextEditingController();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedCivilite = 'Monsieur';
  String? selectedDocumentType = 'CNI';

  final List<Map<String, String>> indicatifs = [
    {'pays': 'Côte d’Ivoire', 'indicatif': '+225', 'flag': '🇨🇮'},
    {'pays': 'Burkina Faso', 'indicatif': '+226', 'flag': '🇧🇫'},
  ];

  void nextPage() {
    if (_currentPage < _formKeys.length &&
        _formKeys[_currentPage].currentState != null &&
        _formKeys[_currentPage].currentState!.validate() &&
        _currentPage < 3) {
      // Changé de 2 à 3
      setState(() => _currentPage++);
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool get hasUppercase => passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => passwordController.text.contains(RegExp(r'[a-z]'));
  bool get hasDigit => passwordController.text.contains(RegExp(r'[0-9]'));
  bool get hasSpecial =>
      passwordController.text.contains(RegExp(r'[!@#\$&*~_.,;:^%()-]'));
  bool get hasMinLength => passwordController.text.length >= 8;

  bool get isPasswordValid =>
      hasUppercase && hasLowercase && hasDigit && hasSpecial && hasMinLength;

  /// Vérifie si un numéro de téléphone existe déjà
  Future<void> _checkPhoneAvailability() async {
    final phoneNumber =
        "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}";

    if (telephoneController.text.isEmpty ||
        !RegExp(r'^\d{10}$').hasMatch(telephoneController.text)) {
      return; // Ne pas vérifier si le numéro n'est pas valide
    }

    setState(() {
      isCheckingPhone = true;
      phoneErrorMessage = null;
    });

    try {
      final exists = await AuthService.checkPhoneExists(phoneNumber);
      if (mounted) {
        setState(() {
          phoneErrorMessage = exists
              ? 'Ce numéro est déjà utilisé pour un compte existant'
              : null;
        });
      }
    } catch (e) {
      // En cas d'erreur, on ne bloque pas
    } finally {
      if (mounted) {
        setState(() => isCheckingPhone = false);
      }
    }
  }

  /// Vérifie si un email existe déjà
  Future<void> _checkEmailAvailability() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => emailErrorMessage = null);
      return; // L'email est optionnel
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return; // Ne pas vérifier si l'email n'est pas valide
    }

    setState(() {
      isCheckingEmail = true;
      emailErrorMessage = null;
    });

    try {
      final exists = await AuthService.checkEmailExists(email);
      if (mounted) {
        setState(() {
          emailErrorMessage =
              exists ? 'Cet email est déjà attribué à un autre compte' : null;
        });
      }
    } catch (e) {
      // En cas d'erreur, on ne bloque pas
    } finally {
      if (mounted) {
        setState(() => isCheckingEmail = false);
      }
    }
  }

  /// Envoyer le code OTP (appelé depuis l'étape 3 - mot de passe)
  Future<void> _sendOtp() async {
    if (_currentPage >= _formKeys.length) return;

    final form = _formKeys[_currentPage].currentState;
    if (form == null || !form.validate()) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final payload = {
        "password": passwordController.text,
        "nom": nomController.text.trim(),
        "prenom": prenomController.text.trim(),
        "civilite": selectedCivilite ?? "Monsieur",
        "date_naissance": dateNaissance?.toIso8601String().split('T').first,
        "lieu_naissance": lieuNaissanceController.text.trim(),
        "telephone":
            "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}",
        "adresse": adresseController.text.trim(),
        "pays": selectedPays ?? "Côte d'Ivoire",
      };

      // Ajouter l'email seulement s'il est fourni
      if (emailController.text.trim().isNotEmpty) {
        payload["email"] = emailController.text.trim();
      }

      // Envoyer l'OTP
      final otpCode = await AuthService.sendOtp(
        "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}",
        payload,
      );

      // Ne plus stocker le code OTP (pas de mode développement sur cette page)
      // Le code sera uniquement reçu par SMS

      if (!mounted) return;

      // Démarrer le timer de 5 minutes
      _startOtpTimer();

      // Passer à l'étape 4 (vérification OTP)
      setState(() => _currentPage++);
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("Code OTP envoyé au ${telephoneController.text}"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text("Erreur: ${e.toString().replaceFirst('Exception: ', '')}"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Vérifier l'OTP et créer le compte (étape 4)
  Future<void> _verifyOtpAndRegister() async {
    if (_currentPage >= _formKeys.length) return;

    final form = _formKeys[_currentPage].currentState;
    if (form == null || !form.validate()) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await AuthService.verifyOtpAndRegister(
        "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}",
        otpController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Inscription réussie !"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text("Erreur: ${e.toString().replaceFirst('Exception: ', '')}"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _register() async {
    if (_currentPage >= _formKeys.length) return;

    final form = _formKeys[_currentPage].currentState;
    if (form == null || !form.validate()) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final payload = {
        "password": passwordController.text,
        "nom": nomController.text.trim(),
        "prenom": prenomController.text.trim(),
        "civilite": selectedCivilite ?? "Monsieur",
        "date_naissance": dateNaissance?.toIso8601String().split('T').first,
        "lieu_naissance": lieuNaissanceController.text.trim(),
        "telephone":
            "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}",
        "adresse": adresseController.text.trim(),
        "pays": selectedPays ?? "Côte d'Ivoire",
      };

      // Ajouter l'email seulement s'il est fourni
      if (emailController.text.trim().isNotEmpty) {
        payload["email"] = emailController.text.trim();
      }

      await AuthService.registerClient(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Inscription réussie !"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text("Erreur: ${e.toString().replaceFirst('Exception: ', '')}"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildCondition(bool condition, String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            condition ? Icons.check_circle : Icons.radio_button_unchecked,
            color: condition ? Colors.green : Colors.grey,
            size: fontSize * 0.9,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: condition ? Colors.black : Colors.grey[600],
              fontSize: fontSize * 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType? inputType,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: fontSize * 0.8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: fontSize * 0.9)),
        SizedBox(height: fontSize * 0.3),
        TextFormField(
          controller: controller,
          keyboardType: inputType ?? TextInputType.text,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: fontSize * 0.8),
            prefixIcon: icon != null
                ? Icon(icon, color: bleuCoris, size: fontSize * 1.2)
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
                horizontal: fontSize * 0.8, vertical: fontSize * 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: const BorderSide(color: rougeCoris, width: 2),
            ),
          ),
          style: TextStyle(fontSize: fontSize * 0.8),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label, {
    IconData? icon,
    required Function(DateTime?) onDateSelected,
    String? hintText,
    required DateTime? date,
    required double fontSize,
  }) {
    String? value = date != null
        ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: fontSize * 0.8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: fontSize * 0.9)),
        SizedBox(height: fontSize * 0.3),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: bleuCoris,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: bleuCoris),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => onDateSelected(picked));
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(
                  text: value ?? ''), // Contrôleur avec valeur
              decoration: InputDecoration(
                hintText: value == null
                    ? (hintText ?? label)
                    : null, // Pas de hint si date sélectionnée
                hintStyle: TextStyle(
                    color: Colors.grey[400], fontSize: fontSize * 0.8),
                prefixIcon: icon != null
                    ? Icon(icon, color: bleuCoris, size: fontSize * 1.2)
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                    horizontal: fontSize * 0.8, vertical: fontSize * 0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fontSize * 0.4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fontSize * 0.4),
                  borderSide: const BorderSide(color: bleuCoris, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fontSize * 0.4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fontSize * 0.4),
                  borderSide: const BorderSide(color: rougeCoris, width: 2),
                ),
              ),
              validator: (_) =>
                  date == null ? "Veuillez sélectionner une date." : null,
              style: TextStyle(fontSize: fontSize * 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items, {
    IconData? icon,
    required Function(String?) onChanged,
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: fontSize * 0.8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: fontSize * 0.9)),
        SizedBox(height: fontSize * 0.3),
        DropdownButtonFormField<String>(
          value: value,
          icon: Icon(Icons.arrow_drop_down,
              color: bleuCoris, size: fontSize * 1.2),
          decoration: InputDecoration(
            hintText: label,
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: fontSize * 0.8),
            prefixIcon: icon != null
                ? Icon(icon, color: bleuCoris, size: fontSize * 1.2)
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
                horizontal: fontSize * 0.8, vertical: fontSize * 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fontSize * 0.4),
              borderSide: const BorderSide(color: rougeCoris, width: 2),
            ),
          ),
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(fontSize: fontSize * 0.8)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) =>
              value == null ? "Veuillez sélectionner une option." : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width * 0.045;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bleuCoris,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: previousPage,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: const Text(
          "Inscription",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black45,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F4F8), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(padding),
                padding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding * 0.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [rougeCoris, Color(0xFFE60000)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(padding * 0.6),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Étape ${_currentPage + 1} sur 4',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Étape 1 : Informations personnelles
                    Form(
                      key: _formKeys[0],
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            Text(
                              "Informations personnelles",
                              style: TextStyle(
                                fontSize: fontSize * 1.2,
                                fontWeight: FontWeight.bold,
                                color: bleuCoris,
                              ),
                            ),
                            _buildDropdown(
                              'Civilité',
                              selectedCivilite,
                              ['Monsieur', 'Madame', 'Mademoiselle'],
                              icon: Icons.person,
                              onChanged: (val) =>
                                  setState(() => selectedCivilite = val),
                              fontSize: fontSize,
                            ),
                            _buildTextField(
                              'Nom',
                              nomController,
                              icon: Icons.person,
                              hintText: 'OUATTARA',
                              validator: (value) => value!.isEmpty
                                  ? "Veuillez entrer votre nom."
                                  : null,
                              fontSize: fontSize,
                            ),
                            _buildTextField(
                              'Prénom',
                              prenomController,
                              icon: Icons.person_outline,
                              hintText: 'Drissa',
                              validator: (value) => value!.isEmpty
                                  ? "Veuillez entrer votre prénom."
                                  : null,
                              fontSize: fontSize,
                            ),
                            _buildDateField(
                              'Date de naissance',
                              icon: Icons.calendar_today,
                              date: dateNaissance,
                              onDateSelected: (date) =>
                                  setState(() => dateNaissance = date),
                              hintText: '01/01/1986',
                              fontSize: fontSize,
                            ),
                            _buildTextField(
                              'Lieu de naissance',
                              lieuNaissanceController,
                              icon: Icons.location_on,
                              validator: (value) => value!.isEmpty
                                  ? "Veuillez entrer votre lieu de naissance."
                                  : null,
                              fontSize: fontSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Étape 2 : Contact
                    Form(
                      key: _formKeys[1],
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            Text(
                              "Contact",
                              style: TextStyle(
                                fontSize: fontSize * 1.2,
                                fontWeight: FontWeight.bold,
                                color: bleuCoris,
                              ),
                            ),
                            _buildTextField(
                              'Adresse e-mail (optionnel)',
                              emailController,
                              icon: Icons.email,
                              inputType: TextInputType.emailAddress,
                              hintText: 'idrissmikle@gmail.com',
                              onChanged: (value) {
                                // Vérifier l'email après 1 seconde d'inactivité
                                Future.delayed(const Duration(seconds: 1), () {
                                  if (emailController.text == value) {
                                    _checkEmailAvailability();
                                  }
                                });
                              },
                              validator: (value) {
                                // L'email est optionnel
                                if (value == null || value.isEmpty) {
                                  return null; // Pas d'erreur si vide
                                }
                                // Si fourni, vérifier le format
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return "Veuillez entrer un email valide.";
                                }
                                // Vérifier si l'email est déjà utilisé
                                if (emailErrorMessage != null) {
                                  return emailErrorMessage;
                                }
                                return null;
                              },
                              fontSize: fontSize,
                            ),
                            if (emailController.text.isNotEmpty) ...[
                              SizedBox(height: fontSize * 0.3),
                              Row(
                                children: [
                                  if (isCheckingEmail)
                                    SizedBox(
                                      width: fontSize * 0.8,
                                      height: fontSize * 0.8,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  if (!isCheckingEmail &&
                                      emailErrorMessage == null &&
                                      emailController.text.isNotEmpty)
                                    Icon(Icons.check_circle,
                                        color: Colors.green,
                                        size: fontSize * 0.8),
                                  if (emailErrorMessage != null)
                                    Icon(Icons.error,
                                        color: rougeCoris,
                                        size: fontSize * 0.8),
                                  SizedBox(width: fontSize * 0.3),
                                  Expanded(
                                    child: Text(
                                      emailErrorMessage ?? 'Email valide',
                                      style: TextStyle(
                                        color: emailErrorMessage != null
                                            ? rougeCoris
                                            : Colors.green,
                                        fontSize: fontSize * 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: fontSize * 0.8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Téléphone',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontSize * 0.9),
                              ),
                            ),
                            SizedBox(height: fontSize * 0.3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: size.width * 0.22,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius:
                                        BorderRadius.circular(fontSize * 0.4),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: fontSize * 0.2),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedIndicatif,
                                      isExpanded: true,
                                      items: indicatifs.map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item['indicatif'],
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(item['flag']!,
                                                  style: TextStyle(
                                                      fontSize:
                                                          fontSize * 0.8)),
                                              SizedBox(width: fontSize * 0.1),
                                              Flexible(
                                                child: Text(
                                                  item['indicatif']!,
                                                  style: TextStyle(
                                                      fontSize: fontSize * 0.7),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(
                                            () => selectedIndicatif = val!);
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: fontSize * 0.3),
                                Expanded(
                                  child: TextFormField(
                                    controller: telephoneController,
                                    keyboardType: TextInputType.phone,
                                    onChanged: (value) {
                                      // Vérifier le téléphone après 1 seconde d'inactivité
                                      Future.delayed(const Duration(seconds: 1),
                                          () {
                                        if (telephoneController.text == value) {
                                          _checkPhoneAvailability();
                                        }
                                      });
                                    },
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "Veuillez entrer votre numéro de téléphone.";
                                      }
                                      if (!RegExp(r'^\d{10}$')
                                          .hasMatch(value)) {
                                        return "Veuillez entrer un numéro valide (10 chiffres).";
                                      }
                                      // Vérifier si le téléphone est déjà utilisé
                                      if (phoneErrorMessage != null) {
                                        return phoneErrorMessage;
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: '0798167534',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: fontSize * 0.8),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: fontSize * 0.8,
                                          vertical: fontSize * 0.7),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            fontSize * 0.4),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            fontSize * 0.4),
                                        borderSide: const BorderSide(
                                            color: bleuCoris, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            fontSize * 0.4),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            fontSize * 0.4),
                                        borderSide: const BorderSide(
                                            color: rougeCoris, width: 2),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: fontSize * 0.8),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: fontSize * 0.3),
                            Row(
                              children: [
                                if (isCheckingPhone)
                                  SizedBox(
                                    width: fontSize * 0.8,
                                    height: fontSize * 0.8,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                if (!isCheckingPhone &&
                                    phoneErrorMessage == null &&
                                    telephoneController.text.isNotEmpty &&
                                    RegExp(r'^\d{10}$')
                                        .hasMatch(telephoneController.text))
                                  Icon(Icons.check_circle,
                                      color: Colors.green,
                                      size: fontSize * 0.8),
                                if (phoneErrorMessage != null)
                                  Icon(Icons.error,
                                      color: rougeCoris, size: fontSize * 0.8),
                                SizedBox(width: fontSize * 0.3),
                                Expanded(
                                  child: Text(
                                    phoneErrorMessage ??
                                        (telephoneController.text.isNotEmpty &&
                                                RegExp(r'^\d{10}$').hasMatch(
                                                    telephoneController.text)
                                            ? 'Numéro valide'
                                            : ''),
                                    style: TextStyle(
                                      color: phoneErrorMessage != null
                                          ? rougeCoris
                                          : Colors.green,
                                      fontSize: fontSize * 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildTextField(
                              'Adresse',
                              adresseController,
                              icon: Icons.location_city,
                              hintText: 'Treichville, Bernabe, 512',
                              validator: (value) => value!.isEmpty
                                  ? "Veuillez entrer votre adresse."
                                  : null,
                              fontSize: fontSize,
                            ),
                            _buildDropdown(
                              'Pays de résidence',
                              selectedPays,
                              ['Côte d’Ivoire', 'Mali', 'Burkina Faso'],
                              icon: Icons.public,
                              onChanged: (val) =>
                                  setState(() => selectedPays = val),
                              fontSize: fontSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Étape 3 : Pièce d'identité

                    Form(
                      key: _formKeys[2],
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Créer un mot de passe",
                              style: TextStyle(
                                fontSize: fontSize * 1.2,
                                fontWeight: FontWeight.bold,
                                color: bleuCoris,
                              ),
                            ),
                            SizedBox(height: fontSize),
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (!isPasswordValid) {
                                  return "Le mot de passe ne respecte pas les critères.";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: '********',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: fontSize * 0.8),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide: const BorderSide(
                                      color: bleuCoris, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide: const BorderSide(
                                      color: rougeCoris, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: bleuCoris,
                                    size: fontSize * 1.2,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              style: TextStyle(fontSize: fontSize * 0.8),
                            ),
                            SizedBox(height: fontSize * 0.8),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              validator: (value) {
                                if (value != passwordController.text) {
                                  return "Les mots de passe ne correspondent pas.";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                hintText: '********',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: fontSize * 0.8),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide: const BorderSide(
                                      color: bleuCoris, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.4),
                                  borderSide: const BorderSide(
                                      color: rougeCoris, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: bleuCoris,
                                    size: fontSize * 1.2,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword),
                                ),
                              ),
                              style: TextStyle(fontSize: fontSize * 0.8),
                            ),
                            SizedBox(height: fontSize),
                            _buildCondition(hasUppercase,
                                "✓ Une lettre majuscule", fontSize),
                            _buildCondition(hasLowercase,
                                "✓ Une lettre minuscule", fontSize),
                            _buildCondition(hasDigit, "✓ Un chiffre", fontSize),
                            _buildCondition(
                                hasSpecial, "✓ Un caractère spécial", fontSize),
                            _buildCondition(hasMinLength,
                                "✓ 8 caractères minimum", fontSize),
                          ],
                        ),
                      ),
                    ),
                    // Étape 4 : Vérification OTP
                    Form(
                      key: _formKeys[3],
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sms,
                              size: fontSize * 4,
                              color: bleuCoris,
                            ),
                            SizedBox(height: fontSize),
                            Text(
                              "Vérification du numéro",
                              style: TextStyle(
                                fontSize: fontSize * 1.2,
                                fontWeight: FontWeight.bold,
                                color: bleuCoris,
                              ),
                            ),
                            SizedBox(height: fontSize * 0.5),
                            Text(
                              "Un code à 5 chiffres a été envoyé au",
                              style: TextStyle(
                                fontSize: fontSize * 0.8,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "$selectedIndicatif ${telephoneController.text}",
                              style: TextStyle(
                                fontSize: fontSize * 0.9,
                                fontWeight: FontWeight.bold,
                                color: bleuCoris,
                              ),
                            ),
                            SizedBox(height: fontSize * 1.5),
                            TextFormField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 5,
                              onChanged: (_) => setState(
                                  () {}), // Rafraîchir l'état du bouton
                              style: TextStyle(
                                fontSize: fontSize * 1.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: fontSize * 0.5,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Code OTP',
                                hintText: '00000',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: fontSize * 1.5,
                                  letterSpacing: fontSize * 0.5,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                  borderSide: const BorderSide(
                                      color: bleuCoris, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                  borderSide: const BorderSide(
                                      color: rougeCoris, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le code OTP';
                                }
                                if (value.length != 5) {
                                  return 'Le code doit contenir 5 chiffres';
                                }
                                if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                                  return 'Le code doit contenir uniquement des chiffres';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: fontSize),

                            // Timer et état de l'OTP
                            if (!_isOtpExpired)
                              Container(
                                padding: EdgeInsets.all(fontSize * 0.8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.timer,
                                        color: Colors.green.shade700,
                                        size: fontSize * 1.2),
                                    SizedBox(width: fontSize * 0.5),
                                    Text(
                                      "Temps restant : $_formattedTimeRemaining",
                                      style: TextStyle(
                                        fontSize: fontSize * 0.9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (_isOtpExpired)
                              Container(
                                padding: EdgeInsets.all(fontSize * 0.8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: rougeCoris,
                                        size: fontSize * 1.2),
                                    SizedBox(width: fontSize * 0.5),
                                    Text(
                                      "Code expiré ! Renvoyez un nouveau code",
                                      style: TextStyle(
                                        fontSize: fontSize * 0.8,
                                        fontWeight: FontWeight.bold,
                                        color: rougeCoris,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: fontSize),
                            ElevatedButton.icon(
                              onPressed: isLoading ? null : _resendOtp,
                              icon: Icon(Icons.refresh, size: fontSize),
                              label: Text(
                                "Renvoyer le code",
                                style: TextStyle(fontSize: fontSize * 0.9),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bleuCoris,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: fontSize * 1.5,
                                  vertical: fontSize * 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(fontSize * 0.6),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(fontSize * 0.6),
                          border: Border.all(
                            color: bleuCoris,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: bleuCoris.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: previousPage,
                          icon: const Icon(Icons.arrow_back, color: bleuCoris),
                          label: Text(
                            "Précédent",
                            style: TextStyle(
                              color: bleuCoris,
                              fontSize: fontSize * 0.9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            minimumSize:
                                Size(size.width * 0.35, fontSize * 2.8),
                            padding: EdgeInsets.symmetric(
                                horizontal: fontSize * 0.8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(fontSize * 0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 1),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_currentPage == 2 &&
                                      isPasswordValid &&
                                      passwordController.text ==
                                          confirmPasswordController.text) ||
                                  (_currentPage == 3 &&
                                      otpController.text.length == 5 &&
                                      !_isOtpExpired)
                              ? [rougeCoris, const Color(0xFFE60000)]
                              : _currentPage < 2
                                  ? [bleuCoris, const Color(0xFF0041A3)]
                                  : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(fontSize * 0.6),
                        boxShadow: [
                          BoxShadow(
                            color: ((_currentPage == 2 || _currentPage == 3)
                                    ? rougeCoris
                                    : bleuCoris)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : (_currentPage == 2
                                ? (passwordController.text.isNotEmpty &&
                                        confirmPasswordController
                                            .text.isNotEmpty &&
                                        passwordController.text ==
                                            confirmPasswordController.text
                                    ? _sendOtp
                                    : null)
                                : _currentPage == 3
                                    ? (otpController.text.length == 5 &&
                                            !_isOtpExpired
                                        ? _verifyOtpAndRegister
                                        : null)
                                    : nextPage),
                        icon: isLoading
                            ? SizedBox(
                                width: fontSize * 0.8,
                                height: fontSize * 0.8,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _currentPage == 3
                                    ? Icons.check_circle
                                    : (_currentPage == 2
                                        ? Icons.send
                                        : Icons.arrow_forward),
                                color: Colors.white,
                              ),
                        label: Text(
                          _currentPage == 3
                              ? "Créer mon compte"
                              : (_currentPage == 2
                                  ? "Envoyer le code"
                                  : "Continuer"),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          minimumSize: Size(size.width * 0.4, fontSize * 2.8),
                          padding:
                              EdgeInsets.symmetric(horizontal: fontSize * 0.8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(fontSize * 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Démarrer le compte à rebours de l'OTP
  void _startOtpTimer() {
    // Annuler le timer précédent s'il existe
    _otpTimer?.cancel();

    // Réinitialiser le timer
    setState(() {
      _otpTimeRemaining = 300; // 5 minutes
      _isOtpExpired = false;
    });

    // Créer un nouveau timer
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimeRemaining > 0) {
        setState(() {
          _otpTimeRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isOtpExpired = true;
        });
      }
    });
  }

  /// Renvoyer le code OTP
  Future<void> _resendOtp() async {
    // Vider le champ OTP
    otpController.clear();

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final payload = {
        "password": passwordController.text,
        "nom": nomController.text.trim(),
        "prenom": prenomController.text.trim(),
        "civilite": selectedCivilite ?? "Monsieur",
        "date_naissance": dateNaissance?.toIso8601String().split('T').first,
        "lieu_naissance": lieuNaissanceController.text.trim(),
        "telephone":
            "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}",
        "adresse": adresseController.text.trim(),
        "pays": selectedPays ?? "Côte d'Ivoire",
      };

      // Ajouter l'email seulement s'il est fourni
      if (emailController.text.trim().isNotEmpty) {
        payload["email"] = emailController.text.trim();
      }

      // Envoyer un NOUVEAU code OTP (l'ancien est remplacé côté serveur)
      final otpCode = await AuthService.sendOtp(
        "$selectedIndicatif${telephoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}",
        payload,
      );

      if (!mounted) return;

      // Redémarrer le timer à 5 minutes
      _startOtpTimer();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text("Nouveau code OTP envoyé au ${telephoneController.text}"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text("Erreur: ${e.toString().replaceFirst('Exception: ', '')}"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Formater le temps restant (mm:ss)
  String get _formattedTimeRemaining {
    final minutes = _otpTimeRemaining ~/ 60;
    final seconds = _otpTimeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    otpController.dispose();
    nomController.dispose();
    prenomController.dispose();
    lieuNaissanceController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    numeroPieceController.dispose();
    villeDelivranceController.dispose();
    autoriteDelivranceController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
