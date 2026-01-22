/// Validateurs de formulaires réutilisables pour l'application CORIS
class FormValidators {
  /// Valide qu'un champ n'est pas vide
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "ce champ"}';
    }
    return null;
  }

  /// Valide la longueur minimale d'un champ
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "ce champ"}';
    }
    if (value.trim().length < min) {
      return '${fieldName ?? "Ce champ"} doit contenir au moins $min caractères';
    }
    return null;
  }

  /// Valide la longueur maximale d'un champ
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.trim().length > max) {
      return '${fieldName ?? "Ce champ"} ne peut pas dépasser $max caractères';
    }
    return null;
  }

  /// Valide un nom (au moins 3 caractères, lettres uniquement)
  static String? name(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "le nom"}';
    }
    if (value.trim().length < 3) {
      return '${fieldName ?? "Le nom"} doit contenir au moins 3 caractères';
    }
    // Accepter lettres, espaces, tirets, apostrophes
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-\']+$').hasMatch(value.trim())) {
      return '${fieldName ?? "Le nom"} ne peut contenir que des lettres';
    }
    return null;
  }

  /// Valide une adresse email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner votre adresse email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse email valide';
    }
    return null;
  }

  /// Valide un numéro de téléphone (au moins 8 chiffres)
  static String? phone(String? value, {String? fieldName, int minDigits = 8}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "le numéro de téléphone"}';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return '${fieldName ?? "Le numéro"} doit contenir uniquement des chiffres';
    }
    if (value.trim().length < minDigits) {
      return '${fieldName ?? "Le numéro"} doit contenir au moins $minDigits chiffres';
    }
    return null;
  }

  /// Valide un numéro Orange Money (doit commencer par 07)
  static String? orangeMoneyPhone(String? value) {
    final basicValidation = phone(value, fieldName: 'Le numéro Orange Money');
    if (basicValidation != null) return basicValidation;
    
    if (!value!.trim().startsWith('07')) {
      return 'Le numéro Orange Money doit commencer par 07';
    }
    return null;
  }

  /// Valide un montant numérique
  static String? amount(String? value, {String? fieldName, double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "le montant"}';
    }
    
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return '${fieldName ?? "Le montant"} doit être un nombre valide';
    }
    
    if (min != null && amount < min) {
      return '${fieldName ?? "Le montant"} doit être supérieur ou égal à $min';
    }
    
    if (max != null && amount > max) {
      return '${fieldName ?? "Le montant"} ne peut pas dépasser $max';
    }
    
    return null;
  }

  /// Valide un nombre entier
  static String? integer(String? value, {String? fieldName, int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "ce champ"}';
    }
    
    final number = int.tryParse(value.trim());
    if (number == null) {
      return '${fieldName ?? "Cette valeur"} doit être un nombre entier';
    }
    
    if (min != null && number < min) {
      return '${fieldName ?? "La valeur"} doit être supérieure ou égale à $min';
    }
    
    if (max != null && number > max) {
      return '${fieldName ?? "La valeur"} ne peut pas dépasser $max';
    }
    
    return null;
  }

  /// Valide une date de naissance (âge entre min et max)
  static String? dateOfBirth(DateTime? value, {int? minAge, int? maxAge, String? fieldName}) {
    if (value == null) {
      return 'Veuillez sélectionner ${fieldName ?? "la date de naissance"}';
    }
    
    final now = DateTime.now();
    final age = now.year - value.year - (now.month < value.month || (now.month == value.month && now.day < value.day) ? 1 : 0);
    
    if (minAge != null && age < minAge) {
      return 'L\'âge minimum requis est de $minAge ans';
    }
    
    if (maxAge != null && age > maxAge) {
      return 'L\'âge maximum autorisé est de $maxAge ans';
    }
    
    return null;
  }

  /// Valide que deux champs correspondent (ex: confirmation mot de passe)
  static String? matches(String? value, String? otherValue, {String? fieldName}) {
    if (value != otherValue) {
      return '${fieldName ?? "Les champs"} ne correspondent pas';
    }
    return null;
  }

  /// Valide un RIB ivoirien (format CI XX XXXXX XXXXXXXXXX XX)
  static String? rib(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner votre RIB';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if (cleaned.length < 23) {
      return 'Le RIB doit contenir au moins 23 caractères';
    }
    
    return null;
  }

  /// Valide un numéro de pièce d'identité
  static String? identityNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner ${fieldName ?? "le numéro de la pièce d\'identité"}';
    }
    
    if (value.trim().length < 5) {
      return '${fieldName ?? "Le numéro"} doit contenir au moins 5 caractères';
    }
    
    return null;
  }

  /// Combine plusieurs validateurs
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
