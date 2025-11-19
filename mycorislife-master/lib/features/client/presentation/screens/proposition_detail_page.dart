import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_etude.dart';

/// ============================================
/// PAGE DE DÉTAILS D'UNE PROPOSITION
/// ============================================
/// Cette page affiche les détails complets d'une proposition d'assurance.
/// Elle permet à l'utilisateur de visualiser toutes les informations de sa
/// souscription avant de procéder au paiement.
///
/// Fonctionnalités:
/// - Affichage des informations personnelles
/// - Affichage des détails du produit (capital, prime, durée, etc.)
/// - Affichage des bénéficiaires et contacts d'urgence
/// - Affichage des documents joints
/// - Possibilité de modifier la proposition
/// - Possibilité de payer directement

// ===================================
// COULEURS PARTAGÉES
// ===================================
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color bleuSecondaire = Color(0xFF1E4A8C);
const Color blanc = Colors.white;
const Color fondCarte = Color(0xFFF8FAFC);
const Color grisTexte = Color(0xFF64748B);
const Color grisLeger = Color(0xFFF1F5F9);
const Color vertSucces = Color(0xFF10B981);
const Color orangeWarning = Color(0xFFF59E0B);

class PropositionDetailPage extends StatefulWidget {
  final int subscriptionId;
  final String propositionNumber;

  const PropositionDetailPage({
    super.key,
    required this.subscriptionId,
    required this.propositionNumber,
  });

  @override
  PropositionDetailPageState createState() => PropositionDetailPageState();
}

class PropositionDetailPageState extends State<PropositionDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final SubscriptionService _service = SubscriptionService();
  Map<String, dynamic>? _subscriptionData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final data = await _service.getSubscriptionDetail(widget.subscriptionId);

      developer.log('=== DONNÉES REÇUES ===');
      developer.log('Subscription: ${data['subscription']}');
      developer.log('Subscription type: ${data['subscription'].runtimeType}');
      developer.log('souscriptiondata: ${data['subscription']?['souscriptiondata']}');
      developer.log('souscriptiondata type: ${data['subscription']?['souscriptiondata'].runtimeType}');
      developer.log('piece_identite direct: ${data['subscription']?['souscriptiondata']?['piece_identite']}');
      developer.log('User: ${data['user']}');

      setState(() {
        _subscriptionData = data['subscription'];
        _userData = data['user'];
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      developer.log('Erreur: $e', error: e);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(String produit) {
    // Toujours retourner le bleu Coris pour uniformiser
    return const Color(0xFF002B6B);
  }

  String _getBadgeText(String produit) {
    if (produit.toLowerCase().contains('solidarite')) {
      return 'CORIS SOLIDARITÉ';
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return 'FLEX EMPRUNTEUR';
    } else if (produit.toLowerCase().contains('etude')) {
      return 'CORIS ÉTUDE';
    } else if (produit.toLowerCase().contains('retraite')) {
      return 'CORIS RETRAITE';
    } else if (produit.toLowerCase().contains('serenite')) {
      return 'CORIS SÉRÉNITÉ';
    } else if (produit.toLowerCase().contains('familis')) {
      return 'CORIS FAMILIS';
    } else if (produit.toLowerCase().contains('epargne')) {
      return 'CORIS ÉPARGNE BONUS';
    } else {
      return 'ASSURANCE VIE';
    }
  }

  String _getProductType() {
    return _subscriptionData?['produit_nom'] ??
        _subscriptionData?['product_type'] ??
        'Produit inconnu';
  }

  Map<String, dynamic> _getSubscriptionDetails() {
    final details = _subscriptionData?['souscriptiondata'] ?? {};
    // Debug: Afficher les données pour vérifier prime_calculee
    developer.log('=== DÉTAILS SOUSCRIPTION ===');
    developer.log('prime_calculee: ${details['prime_calculee']}');
    developer.log('prime: ${details['prime']}');
    developer.log('montant: ${details['montant']}');
    developer.log('periodicite: ${details['periodicite']}');
    return details;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: grisLeger,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            _buildSliverAppBar(),
          ];
        },
        body: Column(
          children: [
            Expanded(child: _buildRecapContent()),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: grisLeger,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(bleuCoris),
            ),
            const SizedBox(height: 16),
            const Text(
              "Chargement des détails...",
              style: TextStyle(
                fontSize: 16,
                color: grisTexte,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: grisLeger,
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: bleuCoris,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Erreur de chargement",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: grisTexte,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSubscriptionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: bleuCoris,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final badgeColor = _getBadgeColor(_getProductType());

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: badgeColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [badgeColor, bleuSecondaire],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: blanc, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        widget.propositionNumber,
                        style: const TextStyle(
                          color: blanc,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getBadgeText(_getProductType()),
                    style: TextStyle(
                      color: blanc.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: blanc),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildRecapContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value.dy * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  const SizedBox(height: 20),

                  // Informations Personnelles
                  SubscriptionRecapWidgets.buildPersonalInfoSection(
                      _userData ?? {}),

                  const SizedBox(height: 20),

                  // Produit Souscrit (selon le type)
                  _buildProductSection(),

                  const SizedBox(height: 20),

                  // Sections spécifiques pour CORIS SOLIDARITÉ
                  ..._buildSolidariteMembersSection(),

                  // Bénéficiaires et Contact d'urgence
                  _buildBeneficiariesSection(),

                  const SizedBox(height: 20),

                  // Documents
                  _buildDocumentsSection(),

                  const SizedBox(height: 20),

                  // Avertissement
                  SubscriptionRecapWidgets.buildVerificationWarning(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductSection() {
    final details = _getSubscriptionDetails();
    final productType = _getProductType().toLowerCase();

    // Pour CORIS SÉRÉNITÉ
    if (productType.contains('serenite')) {
      final duree = details['duree'] ?? 'Non définie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime'] ?? 0;
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildSereniteProductSection(
        productName: 'CORIS SÉRÉNITÉ',
        prime: prime,
        periodicite: periodicite,
        capital: capital,
        duree: duree,
        dureeType: dureeType,
        dateEffet: dateEffet,
        dateEcheance: dateEcheance,
      );
    }

    // Pour CORIS RETRAITE
    if (productType.contains('retraite')) {
      final duree = details['duree'] ?? 'Non définie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime'] ?? 0;
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildRetraiteProductSection(
        productName: 'CORIS RETRAITE',
        prime: prime,
        periodicite: periodicite,
        capital: capital,
        duree: duree,
        dureeType: dureeType,
        dateEffet: dateEffet,
        dateEcheance: dateEcheance,
      );
    }

    // Pour CORIS ÉTUDE
    if (productType.contains('etude')) {
      final prime = details['prime_calculee'] ?? details['prime'] ?? details['montant'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final rente = details['rente_calculee'] ?? details['rente'] ?? 0;
      final duree = details['duree'] ?? details['duree_mois'] != null ? '${(details['duree_mois'] as int) ~/ 12}' : 'Non définie';
      final mode = details['mode_souscription'] ?? 'Mode Capital';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];
      final ageParent = details['age_parent'] ?? 'Non renseigné';
      final dateNaissanceParent = details['date_naissance_parent'];

      // Formater la périodicité avec majuscule
      String periodiciteFormatee = periodicite;
      if (periodicite != null && periodicite.isNotEmpty) {
        periodiciteFormatee = periodicite[0].toUpperCase() + periodicite.substring(1).toLowerCase();
      }

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.school,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow('Produit', 'CORIS ÉTUDE', 'Mode', mode),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Âge du parent',
            ageParent.toString() + ' ans',
            'Date de naissance',
            dateNaissanceParent != null ? SubscriptionRecapWidgets.formatDate(dateNaissanceParent) : 'Non renseignée',
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Cotisation $periodiciteFormatee',
            SubscriptionRecapWidgets.formatMontant(prime),
            'Rente au terme',
            SubscriptionRecapWidgets.formatMontant(rente),
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Durée du contrat',
            duree != 'Non définie' ? '$duree ans (jusqu\'à 18 ans)' : 'Non définie',
            'Périodicité',
            periodiciteFormatee
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null ? SubscriptionRecapWidgets.formatDate(dateEffet) : 'Non définie',
            'Date d\'échéance',
            dateEcheance != null ? SubscriptionRecapWidgets.formatDate(dateEcheance) : 'Non définie',
          ),
        ],
      );
    }

    // Pour CORIS FAMILIS
    if (productType.contains('familis')) {
      final capital = details['capital'] ?? 0;
      final prime = details['prime'] ?? details['prime_mensuelle'] ?? 0;
      final duree = details['duree'] ?? details['duree_mois'] ?? 'Non définie';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.family_restroom,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow('Produit', 'CORIS FAMILIS', 'Capital', SubscriptionRecapWidgets.formatMontant(capital)),
          SubscriptionRecapWidgets.buildCombinedRecapRow('Prime mensuelle', SubscriptionRecapWidgets.formatMontant(prime), 'Durée', '$duree mois'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null ? SubscriptionRecapWidgets.formatDate(dateEffet) : 'Non définie',
            'Date d\'échéance',
            dateEcheance != null ? SubscriptionRecapWidgets.formatDate(dateEcheance) : 'Non définie',
          ),
        ],
      );
    }

    // Pour CORIS SOLIDARITÉ
    if (productType.contains('solidarite')) {
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final primeTotale = details['prime_totale'] ?? 0;

      // Afficher SEULEMENT le produit (sans les membres)
      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.emoji_people_outlined,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow('Produit',
              'CORIS SOLIDARITÉ', 'Périodicité', periodicite.toUpperCase()),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Capital assuré',
              SubscriptionRecapWidgets.formatMontant(capital),
              'Prime $periodicite',
              SubscriptionRecapWidgets.formatMontant(primeTotale)),
        ],
      );
    }

    // Pour CORIS ÉPARGNE BONUS
    if (productType.contains('epargne') || productType.contains('bonus')) {
      final capital = details['capital_au_terme'] ?? details['capital'] ?? 0;
      final prime = details['prime_mensuelle'] ?? details['prime'] ?? 0;
      final dateEffet = details['date_effet'];
      final dateFin = details['date_fin'] ?? details['date_echeance'];
      final bonus = details['bonus'] ?? 'Non défini';

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.savings,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow('Produit', 'CORIS ÉPARGNE BONUS'),
          SubscriptionRecapWidgets.buildRecapRow('Capital au terme', SubscriptionRecapWidgets.formatMontant(capital)),
          SubscriptionRecapWidgets.buildRecapRow('Prime mensuelle', SubscriptionRecapWidgets.formatMontant(prime)),
          SubscriptionRecapWidgets.buildRecapRow('Durée', '15 ans (180 mois)'),
          if (dateEffet != null)
            SubscriptionRecapWidgets.buildRecapRow('Date d\'effet', SubscriptionRecapWidgets.formatDate(dateEffet)),
          if (dateFin != null)
            SubscriptionRecapWidgets.buildRecapRow('Date de fin', SubscriptionRecapWidgets.formatDate(dateFin)),
          SubscriptionRecapWidgets.buildRecapRow('Bonus', bonus.toString()),
        ],
      );
    }

    // Pour FLEX EMPRUNTEUR
    if (productType.contains('flex') || productType.contains('emprunteur')) {
      final typePret = details['type_pret'] ?? 'Non défini';
      final capital = details['capital_garanti'] ?? details['capital'] ?? 0;
      final duree = details['duree'] ?? 'Non définie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime_annuelle'] ?? details['prime'] ?? 0;
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];
      final garantiePrevoyance = details['garantie_prevoyance'] ?? false;
      final garantiePerteEmploi = details['garantie_perte_emploi'] ?? false;
      final capitalPrevoyance = details['capital_prevoyance'] ?? 0;
      final capitalPerteEmploi = details['capital_perte_emploi'] ?? 0;

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.account_balance,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow('Produit', 'FLEX EMPRUNTEUR', 'Type de prêt', typePret),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Capital à garantir',
            SubscriptionRecapWidgets.formatMontant(capital),
            'Durée',
            '$duree $dureeType',
          ),
          if (dateEffet != null && dateEcheance != null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              SubscriptionRecapWidgets.formatDate(dateEffet),
              'Date d\'échéance',
              SubscriptionRecapWidgets.formatDate(dateEcheance),
            ),
          if (dateEffet != null && dateEcheance == null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              SubscriptionRecapWidgets.formatDate(dateEffet),
              '',
              '',
            ),
          if (dateEffet == null && dateEcheance != null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'échéance',
              SubscriptionRecapWidgets.formatDate(dateEcheance),
              '',
              '',
            ),
          SubscriptionRecapWidgets.buildCombinedRecapRow('Prime annuelle estimée', SubscriptionRecapWidgets.formatMontant(prime), '', ''),
          if (garantiePrevoyance && garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie Prévoyance',
              SubscriptionRecapWidgets.formatMontant(capitalPrevoyance),
              'Garantie Perte d\'emploi',
              SubscriptionRecapWidgets.formatMontant(capitalPerteEmploi),
            ),
          if (garantiePrevoyance && !garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie Prévoyance',
              SubscriptionRecapWidgets.formatMontant(capitalPrevoyance),
              '',
              '',
            ),
          if (!garantiePrevoyance && garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie Perte d\'emploi',
              SubscriptionRecapWidgets.formatMontant(capitalPerteEmploi),
              '',
              '',
            ),
        ],
      );
    }

    // Section par défaut pour les autres produits
    return SubscriptionRecapWidgets.buildRecapSection(
      'Produit Souscrit',
      Icons.security,
      vertSucces,
      [
        SubscriptionRecapWidgets.buildRecapRow(
            'Produit', _getBadgeText(_getProductType())),
        if (details['capital'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Capital',
              SubscriptionRecapWidgets.formatMontant(details['capital'])),
        if (details['prime'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Prime',
              SubscriptionRecapWidgets.formatMontant(details['prime'])),
        if (details['duree'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Durée',
              '${details['duree']} ${details['duree_type'] ?? 'mois'}'),
        if (details['date_effet'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Date d\'effet',
              SubscriptionRecapWidgets.formatDate(details['date_effet'])),
      ],
    );
  }

  /// Construit les sections des membres pour CORIS SOLIDARITÉ
  /// Retourne une liste de widgets pour Conjoints, Enfants, Ascendants
  List<Widget> _buildSolidariteMembersSection() {
    final details = _getSubscriptionDetails();
    final productType = _getProductType().toLowerCase();

    // Ne rien afficher si ce n'est pas CORIS SOLIDARITÉ
    if (!productType.contains('solidarite')) {
      return [];
    }

    final List<Widget> sections = [];
    final conjoints = details['conjoints'] as List<dynamic>?;
    final enfants = details['enfants'] as List<dynamic>?;
    final ascendants = details['ascendants'] as List<dynamic>?;

    // Section Conjoints
    if (conjoints != null && conjoints.isNotEmpty) {
      sections.add(
        SubscriptionRecapWidgets.buildRecapSection(
          'Conjoint(s)',
          Icons.people,
          bleuCoris,
          conjoints.map((conjoint) => _buildMembreRecap(conjoint)).toList(),
        ),
      );
      sections.add(const SizedBox(height: 20));
    }

    // Section Enfants
    if (enfants != null && enfants.isNotEmpty) {
      sections.add(
        SubscriptionRecapWidgets.buildRecapSection(
          'Enfant(s)',
          Icons.child_care,
          bleuCoris,
          enfants.map((enfant) => _buildMembreRecap(enfant)).toList(),
        ),
      );
      sections.add(const SizedBox(height: 20));
    }

    // Section Ascendants
    if (ascendants != null && ascendants.isNotEmpty) {
      sections.add(
        SubscriptionRecapWidgets.buildRecapSection(
          'Ascendant(s)',
          Icons.elderly,
          bleuCoris,
          ascendants.map((ascendant) => _buildMembreRecap(ascendant)).toList(),
        ),
      );
      sections.add(const SizedBox(height: 20));
    }

    return sections;
  }

  /// Construit l'affichage d'un membre (conjoint, enfant, ascendant)
  /// Format : Nom en gras + Date de naissance et Lieu de naissance en dessous
  Widget _buildMembreRecap(Map<String, dynamic> membre) {
    final nom = membre['nom'] ??
        membre['nomPrenom'] ??
        membre['nom_prenom'] ??
        membre['prenom'] ??
        'Non renseigné';
    final dateNaissance = membre['date_naissance'] ?? membre['dateNaissance'] ?? membre['date_de_naissance'];
    final lieuNaissance = membre['lieu_naissance'] ?? membre['lieuNaissance'] ?? membre['lieu_de_naissance'];

    return Padding(
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
            dateNaissance != null
                ? 'Date de naissance: ${SubscriptionRecapWidgets.formatDate(dateNaissance)}'
                : 'Date de naissance: Non renseignée',
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
    );
  }

  Widget _buildBeneficiariesSection() {
    final details = _getSubscriptionDetails();
    final beneficiaire = details['beneficiaire'];
    final contactUrgence = details['contact_urgence'];

    return SubscriptionRecapWidgets.buildBeneficiariesSection(
      beneficiaireNom: beneficiaire?['nom'],
      beneficiaireContact: beneficiaire?['contact'],
      beneficiaireLienParente: beneficiaire?['lien_parente'],
      contactUrgenceNom: contactUrgence?['nom'],
      contactUrgenceContact: contactUrgence?['contact'],
      contactUrgenceLienParente: contactUrgence?['lien_parente'],
    );
  }

  Widget _buildDocumentsSection() {
    // Chercher piece_identite dans tous les endroits possibles
    String? pieceIdentite;
    
    // 1. Dans souscriptiondata directement (le plus commun)
    final souscriptiondata = _subscriptionData?['souscriptiondata'];
    if (souscriptiondata != null) {
      // Essayer différentes clés possibles
      pieceIdentite = souscriptiondata['piece_identite'] ?? 
                      souscriptiondata['pieceIdentite'] ??
                      souscriptiondata['document'];
      
      // Si c'est un Map avec des sous-clés
      if (pieceIdentite == null && souscriptiondata['documents'] != null) {
        final docs = souscriptiondata['documents'];
        if (docs is Map) {
          pieceIdentite = docs['piece_identite'] ?? docs['pieceIdentite'];
        }
      }
    }
    
    // 2. Au niveau racine de _subscriptionData
    pieceIdentite ??= _subscriptionData?['piece_identite'];
    pieceIdentite ??= _subscriptionData?['document'];
    
    // 3. Dans les détails (via getSubscriptionDetails)
    if (pieceIdentite == null) {
      final details = _getSubscriptionDetails();
      pieceIdentite = details['piece_identite'] ?? 
                      details['pieceIdentite'] ??
                      details['document'];
      
      // Si c'est dans un sous-objet documents
      if (pieceIdentite == null && details['documents'] != null) {
        final docs = details['documents'];
        if (docs is Map) {
          pieceIdentite = docs['piece_identite'] ?? docs['pieceIdentite'];
        }
      }
    }

    developer.log('=== DOCUMENT DEBUG COMPLET ===');
    developer.log('_subscriptionData: ${_subscriptionData}');
    developer.log('_subscriptionData keys: ${_subscriptionData?.keys.toList()}');
    developer.log('souscriptiondata: $souscriptiondata');
    developer.log('souscriptiondata type: ${souscriptiondata?.runtimeType}');
    if (souscriptiondata is Map) {
      developer.log('souscriptiondata keys: ${souscriptiondata.keys.toList()}');
    }
    developer.log('Final pieceIdentite trouvé: $pieceIdentite');

    // Vérifier si le document existe et n'est pas vide
    final hasDocument = pieceIdentite != null && 
                       pieceIdentite.toString().isNotEmpty && 
                       pieceIdentite != 'Non téléchargée' &&
                       pieceIdentite != 'null' &&
                       pieceIdentite.toString().toLowerCase() != 'null';

    developer.log('hasDocument: $hasDocument');

    return SubscriptionRecapWidgets.buildDocumentsSection(
      pieceIdentite: hasDocument ? pieceIdentite : null,
      onDocumentTap: hasDocument ? () => _viewDocument(pieceIdentite) : null,
    );
  }

  void _viewDocument(String? documentName) {
    developer.log('_viewDocument called with: $documentName');
    
    if (documentName == null || documentName.isEmpty || documentName == 'Non téléchargée') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: blanc, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Aucun document disponible'),
              ),
            ],
          ),
          backgroundColor: orangeWarning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Ouvrir le viewer de documents
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          documentName: documentName,
          subscriptionId: widget.subscriptionId,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Bouton Imprimer
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: bleuCoris.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerPage(subscriptionId: widget.subscriptionId),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_outlined, color: bleuCoris, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Imprimer',
                              style: TextStyle(
                                color: bleuCoris,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton Modifier
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: orangeWarning.withValues(alpha: 0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: orangeWarning.withValues(alpha: 0.05),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _modifyProposition,
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, color: orangeWarning, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Modifier',
                              style: TextStyle(
                                color: orangeWarning,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bouton Accepter et Payer (pleine largeur)
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _acceptAndPay,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: blanc, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Accepter et Payer',
                        style: TextStyle(
                          color: blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: blanc, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _modifyProposition() {
    HapticFeedback.lightImpact();

    if (_subscriptionData == null) return;

    final productType = _getProductType().toLowerCase();
    final details = _getSubscriptionDetails();

    // Rediriger vers la page de souscription appropriée avec les données
    if (productType.contains('etude')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionEtudePage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
          ),
        ),
      ).then((_) {
        _loadSubscriptionData();
      });
    } else if (productType.contains('serenite') || productType.contains('sérénité')) {
      Navigator.pushNamed(
        context,
        '/serenite',
        arguments: {
          'subscriptionId': widget.subscriptionId,
          'existingData': details,
        },
      ).then((_) {
        _loadSubscriptionData();
      });
    } else if (productType.contains('retraite')) {
      Navigator.pushNamed(
        context,
        '/retraite',
        arguments: {
          'subscriptionId': widget.subscriptionId,
          'existingData': details,
        },
      ).then((_) {
        _loadSubscriptionData();
      });
    } else if (productType.contains('solidarite') || productType.contains('solidarité')) {
      Navigator.pushNamed(
        context,
        '/souscription_solidarite',
        arguments: {
          'subscriptionId': widget.subscriptionId,
          'existingData': details,
        },
      ).then((_) {
        _loadSubscriptionData();
      });
    } else if (productType.contains('familis')) {
      Navigator.pushNamed(
        context,
        '/familis',
        arguments: {
          'subscriptionId': widget.subscriptionId,
          'existingData': details,
        },
      ).then((_) {
        _loadSubscriptionData();
      });
    } else if (productType.contains('flex') || productType.contains('emprunteur')) {
      Navigator.pushNamed(
        context,
        '/flex',
        arguments: {
          'subscriptionId': widget.subscriptionId,
          'existingData': details,
        },
      ).then((_) {
        _loadSubscriptionData();
      });
    } else if (productType.contains('epargne') || productType.contains('épargne')) {
      Navigator.pushNamed(
        context,
        '/epargne',
        arguments: {
          'subscriptionId': widget.subscriptionId,
          'existingData': details,
        },
      ).then((_) {
        _loadSubscriptionData();
      });
    } else {
      // Produit non reconnu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La modification de ce type de produit n\'est pas encore disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _acceptAndPay() {
    HapticFeedback.lightImpact();

    // Afficher les options de paiement (comme dans la souscription)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentBottomSheet(),
    );
  }

  Widget _buildPaymentBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.payment, color: bleuCoris, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Options de Paiement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: bleuCoris,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPaymentOption(
                'Wave',
                Icons.waves,
                Colors.blue,
                'Paiement mobile sécurisé',
                () => _processPayment('Wave'),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'Orange Money',
                Icons.phone_android,
                Colors.orange,
                'Paiement mobile Orange',
                () => _processPayment('Orange Money'),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: fondCarte,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: bleuCoris,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: grisTexte,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: grisTexte, size: 16),
          ],
        ),
      ),
    );
  }

  void _processPayment(String paymentMethod) {
    Navigator.pop(context); // Fermer le bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.payment, color: blanc, size: 20),
            const SizedBox(width: 12),
            Text('Paiement via $paymentMethod en cours...'),
          ],
        ),
        backgroundColor: vertSucces,
      ),
    );

    // TODO: Implémenter la logique de paiement réelle
  }
}
