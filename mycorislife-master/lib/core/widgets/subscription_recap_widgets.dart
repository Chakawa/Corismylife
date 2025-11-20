import 'package:flutter/material.dart';

// Couleurs partagées
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color bleuSecondaire = Color(0xFF1E4A8C);
const Color blanc = Colors.white;
const Color fondCarte = Color(0xFFF8FAFC);
const Color grisTexte = Color(0xFF64748B);
const Color grisLeger = Color(0xFFF1F5F9);
const Color vertSucces = Color(0xFF10B981);
const Color orangeWarning = Color(0xFFF59E0B);

/// Widget de récapitulatif réutilisable pour les souscriptions et propositions
class SubscriptionRecapWidgets {
  /// Formate un montant en FCFA
  static String formatMontant(dynamic montant) {
    if (montant == null) return '0 FCFA';

    final numValue = montant is String
        ? double.tryParse(montant) ?? 0
        : (montant as num).toDouble();

    return "${numValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }

  /// Formate un nombre sans FCFA
  /// Accepte int, double ou String et retourne une chaîne formatée avec espaces
  static String formatNumber(dynamic number) {
    // Convertir en double si c'est un int ou une String
    final numValue = number is String
        ? double.tryParse(number) ?? 0
        : (number as num).toDouble();

    return numValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  /// Formate une date
  static String formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Non définie';

      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Date inconnue';
      }

      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateValue.toString();
    }
  }

  /// Construit une section de récapitulatif
  static Widget buildRecapSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Construit une ligne de récapitulatif simple
  static Widget buildRecapRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: grisTexte,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isHighlighted ? vertSucces : bleuCoris,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de récapitulatif avec deux colonnes
  static Widget buildCombinedRecapRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un sous-titre de section
  static Widget buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: bleuCoris,
          fontSize: 14,
        ),
      ),
    );
  }

  static Widget buildPersonalInfoSection(Map<String, dynamic> userData) {
    // Gérer les différentes variantes de clés pour date_naissance et lieu_naissance
    final dateNaissance = userData['date_naissance'] ??
        userData['dateNaissance'] ??
        userData['date_de_naissance'];
    final lieuNaissance = userData['lieu_naissance'] ??
        userData['lieuNaissance'] ??
        userData['lieu_de_naissance'];

    return buildRecapSection(
      'Informations Personnelles',
      Icons.person,
      bleuCoris,
      [
        buildCombinedRecapRow(
            'Civilité',
            userData['civilite'] ?? 'Non renseigné',
            'Nom',
            userData['nom'] ?? 'Non renseigné'),
        buildCombinedRecapRow('Prénom', userData['prenom'] ?? 'Non renseigné',
            'Email', userData['email'] ?? 'Non renseigné'),
        buildCombinedRecapRow(
            'Téléphone',
            userData['telephone'] ?? 'Non renseigné',
            'Date de naissance',
            dateNaissance != null
                ? formatDate(dateNaissance)
                : 'Non renseigné'),
        buildCombinedRecapRow(
            'Lieu de naissance',
            lieuNaissance ?? 'Non renseigné',
            'Adresse',
            userData['adresse'] ?? 'Non renseigné'),
      ],
    );
  }

  /// Construit le récapitulatif du produit CORIS SÉRÉNITÉ
  static Widget buildSereniteProductSection({
    required String productName,
    required dynamic prime,
    required String periodicite,
    required dynamic capital,
    required dynamic duree,
    required String dureeType,
    required dynamic dateEffet,
    required dynamic dateEcheance,
  }) {
    return buildRecapSection(
      'Produit Souscrit',
      Icons.security,
      vertSucces,
      [
        buildCombinedRecapRow(
            'Produit', productName, 'Prime $periodicite', formatMontant(prime)),
        buildCombinedRecapRow(
            'Capital au terme',
            formatMontant(capital),
            'Durée du contrat',
            '$duree ${dureeType == 'années' ? 'ans' : 'mois'}'),
        buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null ? formatDate(dateEffet) : 'Non définie',
            'Date d\'échéance',
            dateEcheance != null ? formatDate(dateEcheance) : 'Non définie'),
      ],
    );
  }

  /// Construit le récapitulatif du produit CORIS RETRAITE
  static Widget buildRetraiteProductSection({
    required String productName,
    required dynamic prime,
    required String periodicite,
    required dynamic capital,
    required dynamic duree,
    required String dureeType,
    required dynamic dateEffet,
    required dynamic dateEcheance,
  }) {
    return buildRecapSection(
      'Produit Souscrit',
      Icons.savings,
      vertSucces,
      [
        buildCombinedRecapRow(
            'Produit', productName, 'Prime $periodicite', formatMontant(prime)),
        buildCombinedRecapRow(
            'Capital au terme',
            formatMontant(capital),
            'Durée du contrat',
            '$duree ${dureeType == 'années' ? 'ans' : 'mois'}'),
        buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null ? formatDate(dateEffet) : 'Non définie',
            'Date d\'échéance',
            dateEcheance != null ? formatDate(dateEcheance) : 'Non définie'),
      ],
    );
  }

  /// Construit le récapitulatif du produit CORIS SOLIDARITÉ
  static Widget buildSolidariteProductSection({
    required String productName,
    required dynamic capital,
    required String periodicite,
    required dynamic primeTotale,
    int? nombreConjoints,
    int? nombreEnfants,
    int? nombreAscendants,
    List<dynamic>? conjoints,
    List<dynamic>? enfants,
    List<dynamic>? ascendants,
  }) {
    final widgets = <Widget>[
      buildCombinedRecapRow(
          'Produit', productName, 'Capital assuré', formatMontant(capital)),
      buildCombinedRecapRow('Prime $periodicite', formatMontant(primeTotale),
          'Périodicité', periodicite.toUpperCase()),
    ];

    // Afficher le résumé des membres couverts
    final List<String> membersSummary = [];
    if (nombreConjoints != null && nombreConjoints > 0) {
      membersSummary
          .add('$nombreConjoints conjoint${nombreConjoints > 1 ? 's' : ''}');
    }
    if (nombreEnfants != null && nombreEnfants > 0) {
      membersSummary
          .add('$nombreEnfants enfant${nombreEnfants > 1 ? 's' : ''}');
    }
    if (nombreAscendants != null && nombreAscendants > 0) {
      membersSummary
          .add('$nombreAscendants ascendant${nombreAscendants > 1 ? 's' : ''}');
    }

    if (membersSummary.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(buildSubsectionTitle('Personnes couvertes'));
      widgets.add(buildRecapRow('Membres', membersSummary.join(', ')));
    }

    // Afficher les détails des conjoints
    if (conjoints != null && conjoints.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(buildSubsectionTitle('Conjoint(s)'));
      for (int i = 0; i < conjoints.length; i++) {
        final conjoint = conjoints[i];
        final nom = conjoint['nom'] ?? 'Conjoint ${i + 1}';
        final dateNaissance = conjoint['date_naissance'] ??
            conjoint['dateNaissance'] ??
            conjoint['date_de_naissance'];
        final lieuNaissance = conjoint['lieu_naissance'] ??
            conjoint['lieuNaissance'] ??
            conjoint['lieu_de_naissance'];

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: bleuCoris,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Date de naissance: ${formatDate(dateNaissance)}',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: grisTexte,
                  fontSize: 12,
                ),
              ),
              if (lieuNaissance != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Lieu de naissance: $lieuNaissance',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ));
      }
    }

    // Afficher les détails des enfants
    if (enfants != null && enfants.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(buildSubsectionTitle('Enfant(s)'));
      for (int i = 0; i < enfants.length; i++) {
        final enfant = enfants[i];
        final nom = enfant['nom'] ?? 'Enfant ${i + 1}';
        final dateNaissance = enfant['date_naissance'] ??
            enfant['dateNaissance'] ??
            enfant['date_de_naissance'];
        final lieuNaissance = enfant['lieu_naissance'] ??
            enfant['lieuNaissance'] ??
            enfant['lieu_de_naissance'];

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: bleuCoris,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Date de naissance: ${formatDate(dateNaissance)}',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: grisTexte,
                  fontSize: 12,
                ),
              ),
              if (lieuNaissance != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Lieu de naissance: $lieuNaissance',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ));
      }
    }

    // Afficher les détails des ascendants
    if (ascendants != null && ascendants.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(buildSubsectionTitle('Ascendant(s)'));
      for (int i = 0; i < ascendants.length; i++) {
        final ascendant = ascendants[i];
        final nom = ascendant['nom'] ?? 'Ascendant ${i + 1}';
        final dateNaissance = ascendant['date_naissance'] ??
            ascendant['dateNaissance'] ??
            ascendant['date_de_naissance'];
        final lieuNaissance = ascendant['lieu_naissance'] ??
            ascendant['lieuNaissance'] ??
            ascendant['lieu_de_naissance'];

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: bleuCoris,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Date de naissance: ${formatDate(dateNaissance)}',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: grisTexte,
                  fontSize: 12,
                ),
              ),
              if (lieuNaissance != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Lieu de naissance: $lieuNaissance',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ));
      }
    }

    return buildRecapSection(
      'Produit Souscrit',
      Icons.family_restroom,
      vertSucces,
      widgets,
    );
  }

  /// Construit le récapitulatif des bénéficiaires et contacts d'urgence
  static Widget buildBeneficiariesSection({
    String? beneficiaireNom,
    String? beneficiaireContact,
    String? beneficiaireLienParente,
    String? contactUrgenceNom,
    String? contactUrgenceContact,
    String? contactUrgenceLienParente,
  }) {
    return buildRecapSection(
      'Bénéficiaire et Contact d\'urgence',
      Icons.contacts,
      Colors.amber,
      [
        buildSubsectionTitle('Bénéficiaire en cas de décès'),
        buildCombinedRecapRow(
            'Nom complet',
            beneficiaireNom?.isEmpty ?? true
                ? 'Non renseigné'
                : beneficiaireNom!,
            'Lien de parenté',
            beneficiaireLienParente ?? 'Non renseigné'),
        buildRecapRow(
            'Téléphone',
            beneficiaireContact?.isEmpty ?? true
                ? 'Non renseigné'
                : beneficiaireContact!),
        const SizedBox(height: 12),
        buildSubsectionTitle('Contact d\'urgence'),
        buildCombinedRecapRow(
            'Nom complet',
            contactUrgenceNom?.isEmpty ?? true
                ? 'Non renseigné'
                : contactUrgenceNom!,
            'Lien de parenté',
            contactUrgenceLienParente ?? 'Non renseigné'),
        buildRecapRow(
            'Téléphone',
            contactUrgenceContact?.isEmpty ?? true
                ? 'Non renseigné'
                : contactUrgenceContact!),
      ],
    );
  }

  /// Construit le récapitulatif des documents
  static Widget buildDocumentsSection({
    String? pieceIdentite,
    VoidCallback? onDocumentTap,
  }) {
    return buildRecapSection(
      'Documents',
      Icons.description,
      bleuSecondaire,
      [
        GestureDetector(
          onTap: pieceIdentite != null ? onDocumentTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 20,
                      color: pieceIdentite != null ? bleuCoris : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pièce d\'identité',
                          style: TextStyle(
                            color: grisTexte,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (pieceIdentite != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            pieceIdentite,
                            style: TextStyle(
                              color: bleuCoris,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            'Non téléchargée',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (pieceIdentite != null)
                  Icon(
                    Icons.visibility,
                    size: 20,
                    color: bleuCoris,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construit l'avertissement de vérification
  static Widget buildVerificationWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: orangeWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: orangeWarning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: orangeWarning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vérification Importante',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: orangeWarning,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vérifiez attentivement toutes les informations. Une fois validée, certaines modifications ne seront plus possibles.',
                  style: TextStyle(
                    color: grisTexte,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un bouton de validation professionnel
  static Widget buildValidationButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
    Color? backgroundColor,
    IconData? icon,
  }) {
    final bgColor = backgroundColor ?? vertSucces;

    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            Color.lerp(bgColor, Colors.black, 0.15)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: bgColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(blanc),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: blanc,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: blanc,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Construit un bouton secondaire (pour annuler, retour, etc.)
  static Widget buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bleuCoris.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: bleuCoris,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
