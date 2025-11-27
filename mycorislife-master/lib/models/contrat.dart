class Contrat {
  final int id;
  final String codeprod;
  final String? codeinte;
  final String? codeappo;
  final String? numepoli;
  final int? duree;
  final DateTime? dateeffet;
  final DateTime? dateeche;
  final String? periodicite;
  final String? domiciliation;
  final double? capital;
  final double? rente;
  final double? prime;
  final double? montantEncaisse;
  final double? impaye;
  final String? etat;
  final String? telephone1;
  final String? telephone2;
  final String? nomPrenom;
  final DateTime? datenaissance;
  final String? prenom;
  final String? nom;
  final String? nomProduit;

  Contrat({
    required this.id,
    required this.codeprod,
    this.codeinte,
    this.codeappo,
    this.numepoli,
    this.duree,
    this.dateeffet,
    this.dateeche,
    this.periodicite,
    this.domiciliation,
    this.capital,
    this.rente,
    this.prime,
    this.montantEncaisse,
    this.impaye,
    this.etat,
    this.telephone1,
    this.telephone2,
    this.nomPrenom,
    this.datenaissance,
    this.prenom,
    this.nom,
    this.nomProduit,
  });

  factory Contrat.fromJson(Map<String, dynamic> json) {
    try {
      return Contrat(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        codeprod: json['codeprod']?.toString() ?? '',
        codeinte: json['codeinte']?.toString(),
        codeappo: json['codeappo']?.toString(),
        numepoli: json['numepoli']?.toString(),
        duree: json['duree'] is int ? json['duree'] : (json['duree'] != null ? int.tryParse(json['duree'].toString()) : null),
        dateeffet: _parseDate(json['dateeffet']),
        dateeche: _parseDate(json['dateeche']),
        periodicite: json['periodicite']?.toString(),
        domiciliation: json['domiciliation']?.toString(),
        capital: _parseDouble(json['capital']),
        rente: _parseDouble(json['rente']),
        prime: _parseDouble(json['prime']),
        montantEncaisse: _parseDouble(json['montant_encaisse']),
        impaye: _parseDouble(json['impaye']),
        etat: json['etat']?.toString(),
        telephone1: json['telephone1']?.toString(),
        telephone2: json['telephone2']?.toString(),
        nomPrenom: json['nom_prenom']?.toString(),
        datenaissance: _parseDate(json['datenaissance']),
        prenom: json['prenom']?.toString(),
        nom: json['nom']?.toString(),
        nomProduit: json['nom_produit']?.toString(),
      );
    } catch (e) {
      print('❌ Erreur parsing Contrat: $e');
      print('📦 JSON reçu: $json');
      rethrow;
    }
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      if (date is DateTime) return date;
      return DateTime.parse(date.toString());
    } catch (e) {
      print('⚠️ Erreur parsing date: $date');
      return null;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.parse(value.toString());
    } catch (e) {
      print('⚠️ Erreur parsing double: $value');
      return null;
    }
  }

  String get productName {
    return nomProduit ?? _getProductNameFromCode(codeprod);
  }

  String _getProductNameFromCode(String code) {
    switch (code) {
      case '225':
        return 'CORIS SOLIDARITÉ';
      case '205':
        return 'FLEX EMPRUNTEUR';
      case '242':
        return 'ÉPARGNE BONUS';
      case '240':
        return 'CORIS RETRAITE';
      case '202':
        return 'CORIS SÉRÉNITÉ';
      case '246':
        return 'CORIS ÉTUDE';
      case '200':
        return 'CORIS FAMILIS';
      default:
        return 'PRODUIT CORIS';
    }
  }

  String get clientName {
    if (prenom != null && nom != null && prenom!.isNotEmpty && nom!.isNotEmpty) {
      return '$prenom $nom';
    }
    return nomPrenom ?? 'Client';
  }

  /// Convertit le contrat en Map pour la navigation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeprod': codeprod,
      'codeinte': codeinte,
      'codeappo': codeappo,
      'numepoli': numepoli,
      'duree': duree,
      'dateeffet': dateeffet?.toIso8601String(),
      'dateeche': dateeche?.toIso8601String(),
      'periodicite': periodicite,
      'domiciliation': domiciliation,
      'capital': capital,
      'rente': rente,
      'prime': prime,
      'montant_encaisse': montantEncaisse,
      'impaye': impaye,
      'etat': etat,
      'telephone1': telephone1,
      'telephone2': telephone2,
      'nom_prenom': nomPrenom,
      'datenaissance': datenaissance?.toIso8601String(),
      'prenom': prenom,
      'nom': nom,
      'nom_produit': nomProduit,
    };
  }
}
