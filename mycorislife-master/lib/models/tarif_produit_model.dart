class TarifProduit {
  final int? id;
  final int produitId;
  final int? dureeContrat; // Durée en mois ou années selon le produit
  final String periodicite; // 'mensuel', 'trimestriel', 'semestriel', 'annuel', 'unique'
  final double? prime;
  final double? capital;
  final int? age; // Nullable car RETRAITE et SOLIDARITÉ n'utilisent pas l'âge
  final String? categorie; // Optionnel, pour catégoriser les tarifs
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TarifProduit({
    this.id,
    required this.produitId,
    this.dureeContrat,
    required this.periodicite,
    this.prime,
    this.capital,
    this.age,
    this.categorie,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit_id': produitId,
      'duree_contrat': dureeContrat,
      'periodicite': periodicite,
      'prime': prime,
      'capital': capital,
      'age': age,
      'categorie': categorie,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TarifProduit.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to int
    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      return null;
    }

    // Helper function to safely convert to double
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return null;
    }

    return TarifProduit(
      id: _toInt(map['id']),
      produitId: _toInt(map['produit_id']) ?? 0,
      dureeContrat: _toInt(map['duree_contrat']),
      periodicite: map['periodicite']?.toString() ?? '',
      prime: _toDouble(map['prime']),
      capital: _toDouble(map['capital']),
      age: _toInt(map['age']),
      categorie: map['categorie']?.toString(),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString()) 
          : null,
    );
  }

  @override
  String toString() => 
      'TarifProduit(id: $id, produitId: $produitId, duree: $dureeContrat, periodicite: $periodicite, prime: $prime, capital: $capital, age: $age, categorie: $categorie)';
}




