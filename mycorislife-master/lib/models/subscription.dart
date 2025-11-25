class Subscription {
  final int id;
  final int userId;
  final String numeroPolice;
  final String produitNom;
  final String statut;
  final DateTime dateCreation;
  final DateTime? dateValidation;
  final Map<String, dynamic> souscriptionData;

  Subscription({
    required this.id,
    required this.userId,
    required this.numeroPolice,
    required this.produitNom,
    required this.statut,
    required this.dateCreation,
    this.dateValidation,
    required this.souscriptionData,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Détecter si c'est un contrat de la table "contrats" ou une souscription
    final bool isContrat = json.containsKey('numepoli') && json.containsKey('codeprod');
    
    if (isContrat) {
      // Format de la table "contrats"
      // Fonction helper pour parser les nombres qui peuvent être string ou null
      num? parseNumeric(dynamic value) {
        if (value == null) return null;
        if (value is num) return value;
        if (value is String) {
          try {
            return num.parse(value);
          } catch (e) {
            return null;
          }
        }
        return null;
      }
      
      // Fonction helper pour parser les dates de manière sécurisée
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        try {
          if (value is DateTime) return value;
          if (value is String) return DateTime.parse(value);
        } catch (e) {
          return null;
        }
        return null;
      }
      
      return Subscription(
        id: json['id'] ?? 0,
        userId: 0, // Les contrats n'ont pas de user_id
        numeroPolice: json['numepoli']?.toString() ?? 'N/A',
        produitNom: _getProductName(json['codeprod']?.toString()),
        statut: json['etat']?.toString() ?? 'ACTIF',
        dateCreation: parseDate(json['dateeffet']) ?? DateTime.now(),
        dateValidation: parseDate(json['dateeche']),
        souscriptionData: {
          'capital': parseNumeric(json['capital']) ?? 0,
          'prime': parseNumeric(json['prime']) ?? 0,
          'rente': parseNumeric(json['rente']) ?? 0,
          'duree': json['duree'] ?? 0,
          'periodicite': json['periodicite']?.toString() ?? '',
          'dateEffet': json['dateeffet']?.toString(),
          'dateEcheance': json['dateeche']?.toString(),
          'montantEncaisse': parseNumeric(json['montant_encaisse']) ?? 0,
          'impaye': parseNumeric(json['impaye']) ?? 0,
          'nom_prenom': json['nom_prenom']?.toString() ?? '',
          'telephone1': json['telephone1']?.toString() ?? '',
          'telephone2': json['telephone2']?.toString() ?? '',
          'datenaissance': json['datenaissance']?.toString(),
          'domiciliation': json['domiciliation']?.toString() ?? '',
          'codeinte': json['codeinte']?.toString() ?? '',
          'codeappo': json['codeappo']?.toString() ?? '',
        },
      );
    } else {
      // Format de la table "subscriptions"
      return Subscription(
        id: json['id'],
        userId: json['user_id'],
        numeroPolice: json['numero_police'],
        produitNom: json['produit_nom'],
        statut: json['statut'],
        dateCreation: DateTime.parse(json['date_creation']),
        dateValidation: json['date_validation'] != null ? DateTime.parse(json['date_validation']) : null,
        souscriptionData: json['souscriptiondata'],
      );
    }
  }
  
  // Convertir le code produit en nom lisible
  static String _getProductName(String? codeProd) {
    if (codeProd == null) return 'Produit inconnu';
    
    switch (codeProd) {
      case '240':
        return 'CORIS SOLIDARITÉ';
      case '241':
        return 'FLEX EMPRUNTEUR';
      case '242':
        return 'CORIS ÉTUDE';
      case '243':
        return 'CORIS RETRAITE';
      case '244':
        return 'CORIS SÉRÉNITÉ';
      case '245':
        return 'ÉPARGNE BONUS';
      case '246':
        return 'CORIS FAMILIS';
      default:
        return 'Produit $codeProd';
    }
  }

  String get formattedDateCreation {
    return '${dateCreation.day.toString().padLeft(2, '0')}/${dateCreation.month.toString().padLeft(2, '0')}/${dateCreation.year}';
  }

  String get formattedDateValidation {
    if (dateValidation == null) return '-';
    return '${dateValidation!.day.toString().padLeft(2, '0')}/${dateValidation!.month.toString().padLeft(2, '0')}/${dateValidation!.year}';
  }

  String get capitalFormatted {
    final capital = souscriptionData['capital'] ?? souscriptionData['montant'] ?? 0;
    return '${capital.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }

  String get primeFormatted {
    final prime = souscriptionData['prime'] ?? souscriptionData['prime_calculee'] ?? souscriptionData['prime_mensuelle'] ?? 0;
    return '${prime.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }
}