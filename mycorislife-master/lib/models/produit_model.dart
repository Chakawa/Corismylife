class Produit {
  final int? id;
  final String libelle;

  Produit({
    this.id,
    required this.libelle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
    );
  }

  @override
  String toString() => 'Produit(id: $id, libelle: $libelle)';
}












