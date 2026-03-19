import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/services/pdf_service.dart';
import 'package:mycorislife/services/download_notification_service.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';
import 'package:mycorislife/features/client/presentation/widgets/contract_payment_flow.dart';
import 'package:mycorislife/core/utils/amount_parser.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContratDetailPage extends StatefulWidget {
  final int subscriptionId;
  final String contractNumber;

  const ContratDetailPage({
    super.key,
    required this.subscriptionId,
    required this.contractNumber,
  });

  @override
  ContratDetailPageState createState() => ContratDetailPageState();
}

class ContratDetailPageState extends State<ContratDetailPage>
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

    _loadContractData();
  }

  Future<void> _loadContractData() async {
    try {
      final data = await _service.getSubscriptionDetail(widget.subscriptionId);

      developer.log('=== TOUTES LES CLÉS DISPONIBLES CONTRAT ===');
      if (data['subscription'] != null) {
        developer.log('Clés dans subscription: ${data['subscription'].keys}');
        data['subscription'].forEach((key, value) {
          if (key != 'souscriptiondata') {
            developer.log('$key: $value (type: ${value.runtimeType})');
          }
        });

        if (data['subscription']['souscriptiondata'] != null) {
          developer.log('=== SOUSCRIPTIONDATA CONTRAT ===');
          developer.log(
              'Type: ${data['subscription']['souscriptiondata'].runtimeType}');
          if (data['subscription']['souscriptiondata'] is Map) {
            data['subscription']['souscriptiondata'].forEach((key, value) {
              developer.log('$key: $value');
            });
          } else {
            developer
                .log('Contenu: ${data['subscription']['souscriptiondata']}');
          }
        }
      }

      setState(() {
        _subscriptionData = data['subscription'];
        _userData = data['user'];
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      developer.log('Erreur chargement contrat: $e', error: e);
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

  String _formatDate(dynamic dateValue) {
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
      return "Date inconnue";
    }
  }

  String _formatDateTime(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Non definie';

      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        final raw = dateValue.trim();
        if (raw.isEmpty) return 'Non definie';

        // Supporte aussi le format fr: dd/MM/yyyy HH:mm[:ss]
        final fr = RegExp(
                r'^(\d{2})/(\d{2})/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?$')
            .firstMatch(raw);
        if (fr != null) {
          final day = int.parse(fr.group(1)!);
          final month = int.parse(fr.group(2)!);
          final year = int.parse(fr.group(3)!);
          final hour = int.tryParse(fr.group(4) ?? '0') ?? 0;
          final minute = int.tryParse(fr.group(5) ?? '0') ?? 0;
          final second = int.tryParse(fr.group(6) ?? '0') ?? 0;
          date = DateTime(year, month, day, hour, minute, second);
        } else {
          date = DateTime.parse(raw);
        }
      } else {
        return 'Date inconnue';
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year a $hour:$minute';
    } catch (_) {
      return 'Date inconnue';
    }
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return '0 FCFA';

    // Some APIs return a structured object (e.g. {"amount": 1000}).
    if (montant is Map) {
      final candidates = [
        'amount',
        'montant',
        'value',
        'total',
        'montant_paye',
        'montant_encaisse',
        'payment_amount',
        'amount_paid',
      ];
      for (final key in candidates) {
        if (montant.containsKey(key)) {
          return _formatMontant(montant[key]);
        }
      }
      if (montant.length == 1) {
        return _formatMontant(montant.values.first);
      }
    }

    if (montant is List && montant.isNotEmpty) {
      return _formatMontant(montant.first);
    }

    final numValue = AmountParser.parse(montant);
    return "${numValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }

  double _getSuggestedPaymentAmount() {
    final details = _getSubscriptionDetails();
    final montantRaw = _subscriptionData?['prime'] ??
        _subscriptionData?['montant'] ??
        _subscriptionData?['prime_totale'] ??
        details['prime'] ??
        details['montant'] ??
        details['prime_totale'];

    if (montantRaw == null) return 0;
    return AmountParser.parse(montantRaw);
  }

  String _getPaymentStatus(Map<String, dynamic>? paymentInfo) {
    final statusRaw = (paymentInfo?['provider_status'] ??
            paymentInfo?['status'] ??
            paymentInfo?['statut'] ??
            _subscriptionData?['statut'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();

    final successKeywords = {
      'success',
      'succeeded',
      'paid',
      'completed',
      'validated',
      'confirmed',
      'ok',
      'validé',
      'validée',
      'confirmé',
      'confirmée',
      'authorised',
      'authorized',
      'contrat',
      'oui'
    };

    if (statusRaw.isEmpty) {
      return 'FAILED';
    }

    return successKeywords.contains(statusRaw) ? 'SUCCESS' : 'FAILED';
  }

  Color _getBadgeColor(String produit) {
    if (produit.toLowerCase().contains('solidarite')) {
      return const Color(0xFF002B6B);
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return const Color(0xFFEF4444);
    } else if (produit.toLowerCase().contains('etude')) {
      return const Color(0xFF8B5CF6);
    } else if (produit.toLowerCase().contains('retraite')) {
      return const Color(0xFF10B981);
    } else if (produit.toLowerCase().contains('serenite')) {
      return const Color(0xFF002B6B);
    } else if (produit.toLowerCase().contains('familis')) {
      return const Color(0xFFF59E0B);
    } else if (produit.toLowerCase().contains('epargne')) {
      return const Color(0xFF8B5CF6);
    } else {
      return const Color(0xFF002B6B);
    }
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

  // MÉTHODE SUPPRIMÉE : _getProductIcon n'est pas utilisée
  // IconData _getProductIcon(String produit) {
  //   ...
  // }

  String _getProductType() {
    return _subscriptionData?['produit_nom'] ??
        _subscriptionData?['product_type'] ??
        'Produit inconnu';
  }

  Map<String, dynamic> _getSubscriptionDetails() {
    // Some backends may use different naming conventions for the "souscriptiondata" field.
    // Accept multiple variants so that production vs emulator responses both work.
    return _subscriptionData?['souscriptiondata'] ??
        _subscriptionData?['souscriptionData'] ??
        _subscriptionData?['souscription_data'] ??
        _subscriptionData?['souscription'] ??
        {};
  }

  /// Normalise une valeur document en nom de fichier serveur.
  /// Accepte: URL complète, chemin local, ou nom brut.
  String? _extractServerFileName(dynamic rawValue) {
    if (rawValue == null) return null;
    final asString = rawValue.toString().trim();
    if (asString.isEmpty || asString.toLowerCase() == 'null') return null;
    final decoded = Uri.decodeFull(asString).replaceAll('\\\\', '/');
    final fileName = decoded.split('/').last.trim();
    if (fileName.isEmpty) return null;
    return fileName;
  }

  String _getContractStatus() {
    final dateEcheance = _subscriptionData?['date_echeance'] ??
        _getSubscriptionDetails()['date_echeance'];
    if (dateEcheance != null) {
      try {
        final echeance = DateTime.parse(dateEcheance.toString());
        final now = DateTime.now();
        if (echeance.isBefore(now)) {
          return 'Échu';
        } else if (echeance.difference(now).inDays <= 30) {
          return 'Bientôt échu';
        }
      } catch (e) {
        developer.log('Erreur calcul statut: $e', error: e);
      }
    }
    return 'Actif';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Actif':
        return const Color(0xFF10B981);
      case 'Bientôt échu':
        return const Color(0xFFF59E0B);
      case 'Échu':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Map<String, dynamic> _getSolidariteData() {
    final details = _getSubscriptionDetails();

    final dateEffet = details['date_effet'] ??
        _subscriptionData?['date_effet'] ??
        _subscriptionData?['date_creation'];

    dynamic dateEcheanceCalculee;
    if (dateEffet != null) {
      try {
        DateTime dateEffetDt = _parseDate(dateEffet);
        dateEcheanceCalculee = DateTime(
          dateEffetDt.year + 1,
          dateEffetDt.month,
          dateEffetDt.day,
          dateEffetDt.hour,
          dateEffetDt.minute,
          dateEffetDt.second,
        );
      } catch (e) {
        developer.log('Erreur calcul date échéance: $e', error: e);
      }
    }

    return {
      'capital': details['capital'] ?? _subscriptionData?['capital'] ?? 0,
      'prime_totale': details['prime_totale'] ??
          _subscriptionData?['prime_totale'] ??
          _subscriptionData?['prime'] ??
          0,
      'periodicite': details['periodicite'] ??
          _subscriptionData?['periodicite'] ??
          'Mensuelle',
      'date_effet': dateEffet,
      'date_echeance': details['date_echeance'] ??
          _subscriptionData?['date_echeance'] ??
          dateEcheanceCalculee,
      'duree_contrat': '1 an',
      'conjoints': _extractMembres(details, 'conjoints'),
      'enfants': _extractMembres(details, 'enfants'),
      'ascendants': _extractMembres(details, 'ascendants'),
    };
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) return DateTime.parse(dateValue);
    return DateTime.now();
  }

  List<dynamic> _extractMembres(Map<String, dynamic> details, String type) {
    final membres = details[type];

    if (membres is List) {
      for (var i = 0; i < membres.length; i++) {
        if (membres[i] is Map && !membres[i].containsKey('lien_parente')) {
          if (type == 'conjoints') {
            membres[i]['lien_parente'] = 'Conjoint(e)';
          } else if (type == 'enfants') {
            membres[i]['lien_parente'] = 'Enfant';
          } else if (type == 'ascendants') {
            membres[i]['lien_parente'] = 'Ascendant';
          }
        }
      }
      return membres;
    }

    return [];
  }

  Widget _buildProductSection() {
    final productType = _getProductType().toLowerCase();

    if (productType.contains('solidarite')) {
      final solidariteData = _getSolidariteData();
      return _buildSolidariteSection(solidariteData);
    } else if (productType.contains('epargne')) {
      return _buildEpargneSection(_getSubscriptionDetails());
    } else if (productType.contains('etude')) {
      return _buildEtudeSection(_getSubscriptionDetails());
    } else if (productType.contains('familis')) {
      return _buildFamilisSection(_getSubscriptionDetails());
    } else if (productType.contains('emprunteur')) {
      return _buildFlexEmprunteurSection(_getSubscriptionDetails());
    } else if (productType.contains('retraite')) {
      return _buildRetraiteSection(_getSubscriptionDetails());
    } else if (productType.contains('serenite')) {
      return _buildSereniteSection(_getSubscriptionDetails());
    } else {
      return _buildDefaultProductSection(_getSubscriptionDetails());
    }
  }

  Map<String, dynamic>? _getPaymentInfo() {
    final details = _getSubscriptionDetails();

    // Support multiple locations for payment info
    // (some environments store it inside `souscriptiondata`, others at root)
    final rawPaymentInfo = _subscriptionData?['payment_info'] ??
        details['payment_info'] ??
        _subscriptionData?['paiement'] ??
        details['paiement'] ??
        _subscriptionData?['payment'] ??
        details['payment'];

    String? pickText(List<dynamic> values) {
      for (final value in values) {
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
      }
      return null;
    }

    dynamic pickValue(List<dynamic> values) {
      for (final value in values) {
        if (value == null) continue;
        final text = value.toString().trim().toLowerCase();
        if (text.isNotEmpty && text != 'null') return value;
      }
      return null;
    }

    Map<String, dynamic> toMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) return <String, dynamic>{};
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
          if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
            return Map<String, dynamic>.from(decoded.first);
          }
        } catch (_) {
          // Some backends may store JSON-like strings with single quotes.
          // Try a relaxed parse by converting single quotes to double quotes.
          try {
            final normalized = trimmed.replaceAll("'", '"');
            final decoded = jsonDecode(normalized);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
            if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
              return Map<String, dynamic>.from(decoded.first);
            }
          } catch (_) {
            // ignore
          }
        }
        return <String, dynamic>{};
      }
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        return Map<String, dynamic>.from(raw.first);
      }
      return <String, dynamic>{};
    }

    final paymentInfo = toMap(rawPaymentInfo);
    final paymentMeta = toMap(_subscriptionData?['paiement'] ??
        details['paiement'] ??
        details['payment']);

    final paymentMethod = pickText([
      paymentInfo['payment_method'],
      paymentInfo['method'],
      paymentMeta['mode_paiement'],
      paymentMeta['payment_method'],
      details['mode_paiement'],
      details['payment_method'],
      _subscriptionData?['payment_method'],
    ]);

    final paymentDate = pickText([
      paymentInfo['payment_date'],
      paymentInfo['date_paiement'],
      paymentMeta['payment_date'],
      paymentMeta['date_paiement'],
      details['payment_date'],
      details['date_paiement'],
      _subscriptionData?['payment_date'],
      _subscriptionData?['date_validation'],
      _subscriptionData?['updated_at'],
      _subscriptionData?['created_at'],
    ]);

    final amount = pickValue([
      paymentInfo['amount'],
      paymentInfo['montant'],
      paymentInfo['payment_amount'],
      paymentInfo['amount_paid'],
      paymentInfo['montant_paye'],
      paymentInfo['montant_paye'],
      paymentMeta['amount'],
      paymentMeta['montant'],
      paymentMeta['payment_amount'],
      paymentMeta['amount_paid'],
      paymentMeta['montant_paye'],
      details['payment_amount'],
      details['amount_paid'],
      details['montant_paye'],
      details['dernier_montant_paye'],
      details['montant'],
      details['montant_encaisse'],
      details['total_paid'],
      _subscriptionData?['dernier_montant_paye'],
      _subscriptionData?['montant_paye'],
      _subscriptionData?['amount_paid'],
      _subscriptionData?['montant_encaisse'],
      _subscriptionData?['total_paid'],
    ]);

    final paymentId = pickText([
      paymentInfo['payment_id'],
      paymentInfo['provider_payment_id'],
      paymentInfo['paymentId'],
      paymentInfo['id'],
      paymentMeta['payment_id'],
      paymentMeta['provider_payment_id'],
      paymentMeta['paymentId'],
      paymentMeta['id'],
      details['payment_id'],
      details['provider_payment_id'],
      details['paymentId'],
      details['id_paiement'],
      details['payment_transaction_id'],
      _subscriptionData?['payment_id'],
      _subscriptionData?['provider_payment_id'],
      _subscriptionData?['paymentId'],
      _subscriptionData?['id_paiement'],
      _subscriptionData?['payment_transaction_id'],
      paymentInfo['transaction_id'],
      paymentInfo['transactionId'],
      paymentInfo['reference'],
      paymentInfo['session_id'],
      paymentMeta['transaction_id'],
      paymentMeta['transactionId'],
      paymentMeta['reference'],
      details['transaction_id'],
      details['transactionId'],
    ]);

    final providerStatus = pickText([
      paymentInfo['provider_status'],
      paymentInfo['status'],
      paymentMeta['provider_status'],
      paymentMeta['status'],
      details['provider_status'],
      details['status'],
    ]);

    if (paymentMethod == null &&
        paymentDate == null &&
        amount == null &&
        paymentId == null) {
      return null;
    }

    return {
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'amount': amount,
      'payment_id': paymentId,
      'provider_status': providerStatus,
    };
  }

  Widget _buildPaymentInfoCard() {
    final paymentInfo = _getPaymentInfo();
    if (paymentInfo == null) {
      return const SizedBox.shrink();
    }

    final paymentMethodRaw = (paymentInfo['payment_method'] ?? '').toString();
    final paymentMethod =
        paymentMethodRaw.trim().isEmpty ? 'Non defini' : paymentMethodRaw;

    final amount = paymentInfo['amount'] ??
        paymentInfo['montant'] ??
        paymentInfo['amount_paid'] ??
        paymentInfo['montant_paye'] ??
        paymentInfo['montant_encaisse'] ??
        _subscriptionData?['montant'] ??
        _subscriptionData?['montant_encaisse'] ??
        _subscriptionData?['total_paid'] ??
        _subscriptionData?['prime'];

    final paymentDate = paymentInfo['payment_date'] ??
        paymentInfo['date_paiement'] ??
        _subscriptionData?['date_validation'];

    final paymentId = paymentInfo['payment_id'] ??
        paymentInfo['transactionId'] ??
        paymentInfo['transaction_id'] ??
        _subscriptionData?['payment_transaction_id'];

    final providerStatusRaw = (paymentInfo['provider_status'] ??
            paymentInfo['status'] ??
            paymentInfo['statut'] ??
            '')
        .toString();
    final providerStatus = providerStatusRaw.trim().isEmpty
        ? 'INCONNU'
        : providerStatusRaw.toUpperCase();

    final validationStatus = _getPaymentStatus(paymentInfo);

    return _buildRecapSection(
      'Section paiement',
      Icons.account_balance_wallet_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Mode de paiement', paymentMethod, '', ''),
        _buildCombinedRecapRow('Montant paye', _formatMontant(amount),
            'Date de paiement', _formatDateTime(paymentDate)),
        _buildCombinedRecapRow(
            'ID paiement', (paymentId ?? 'Non definie').toString(), '', ''),
        _buildCombinedRecapRow('Validation', validationStatus, '', ''),
      ],
    );
  }

  Widget _buildSolidariteSection(Map<String, dynamic> data) {
    final capital = data['capital'] ?? 0;
    final primeTotale = data['prime_totale'] ?? 0;
    final periodicite = data['periodicite'] ?? 'Non définie';
    final conjoints = data['conjoints'] ?? [];
    final enfants = data['enfants'] ?? [];
    final ascendants = data['ascendants'] ?? [];

    return _buildRecapSection(
      'Détails du Contrat',
      Icons.people_outline,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow(
            'Produit', 'CORIS SOLIDARITÉ', 'Périodicité', periodicite),
        _buildCombinedRecapRow('Capital garanti', _formatMontant(capital),
            'Prime totale', _formatMontant(primeTotale)),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        if (conjoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMembresSection('Conjoint(s)', Icons.people_outline, conjoints),
        ],
        if (enfants.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMembresSection('Enfant(s)', Icons.child_care_outlined, enfants),
        ],
        if (ascendants.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMembresSection(
              'Ascendant(s)', Icons.elderly_outlined, ascendants),
        ],
        if (conjoints.isEmpty && enfants.isEmpty && ascendants.isEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: const Text(
              'Aucun membre assuré',
              style: TextStyle(
                color: Color(0xFFD92D20),
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildCombinedRecapRow(
          'Date d\'effet',
          _formatDate(data['date_effet']),
          'Date d\'échéance',
          _formatDate(data[
              'date_echeance']), // CORRECTION : suppression interpolation inutile
        ),
      ],
    );
  }

  Widget _buildMembresSection(
      String titre, IconData icone, List<dynamic> membres) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: const Color(0xFF002B6B)),
            const SizedBox(width: 8),
            Text(
              titre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF002B6B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...membres.map((membre) => _buildMembreRecap(
            membre)), // CORRECTION : suppression .toList() inutile
      ],
    );
  }

  Widget _buildMembreRecap(dynamic membre) {
    final nomPrenom = membre['nom_prenom'] ??
        'Non renseigné'; // CORRECTION : suppression duplication
    final dateNaissance = membre['date_naissance'] ??
        membre['birthDate'] ??
        membre['dateNaissance'];

    String lienParente = '';
    if (membre.containsKey('lien_parente')) {
      lienParente = membre['lien_parente'] ?? '';
    } else {
      lienParente = 'Membre assuré';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nomPrenom,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          if (lienParente.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Relation: $lienParente',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          if (dateNaissance != null) ...[
            const SizedBox(height: 4),
            Text(
              'Né(e) le: ${_formatDate(dateNaissance)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpargneSection(Map<String, dynamic> data) {
    return _buildRecapSection(
      'Détails du Contrat',
      Icons.savings_outlined,
      const Color(0xFF10B981),
      [
        _buildRecapRow('Produit', 'CORIS ÉPARGNE BONUS'),
        _buildRecapRow('Statut', _getContractStatus()),
        _buildRecapRow('Capital au terme', _formatMontant(data['capital'])),
        _buildRecapRow(
            'Prime mensuelle', _formatMontant(data['prime_mensuelle'])),
        _buildRecapRow('Durée', '15 ans (180 mois)'),
        _buildRecapRow('Date d\'effet', _formatDate(data['date_effet'])),
        _buildRecapRow('Date de fin', _formatDate(data['date_fin'])),
        _buildRecapRow('Bonus', _getBonusText(data)),
      ],
    );
  }

  String _getBonusText(Map<String, dynamic> data) {
    final capital = data['capital'] ?? 0;
    if (capital >= 6000000) return '+ 15% de bonus au terme';
    if (capital >= 4000000) return '+ 10% de bonus au terme';
    if (capital >= 2000000) return '+ 7% de bonus au terme';
    return '+ 5% de bonus au terme';
  }

  Widget _buildEtudeSection(Map<String, dynamic> data) {
    final mode = data['mode_souscription'] ?? 'Mode Prime';
    final prime = data['prime_calculee'] ?? data['prime'];
    final rente = data['rente_calculee'] ?? data['rente'];
    final ageParent = data['age_parent'] ?? 'Non renseigné';
    final dateNaissanceParent = data['date_naissance_parent'];

    return _buildRecapSection(
      'Détails du Contrat',
      Icons.school_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'CORIS ÉTUDE', 'Mode', mode),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
          'Âge du parent',
          '$ageParent ans',
          'Date de naissance',
          dateNaissanceParent != null
              ? _formatDate(dateNaissanceParent)
              : 'Non renseignée',
        ),
        _buildCombinedRecapRow(
          'Prime ${data['periodicite']}',
          _formatMontant(prime),
          'Rente au terme',
          _formatMontant(rente),
        ),
        _buildCombinedRecapRow(
            'Durée du contrat',
            '${data['duree_mois'] != null ? (data['duree_mois'] ~/ 12) : (17 - (data['age_enfant'] ?? 0))} ans (jusqu\'à 17 ans)',
            'Périodicité',
            data['periodicite'] ?? 'Non définie'),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'échéance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildFamilisSection(Map<String, dynamic> data) {
    final duree = data['duree'] ?? 'Non définie';
    final capital = data['capital'] ?? 0;
    final prime = data['prime'] ?? data['prime_calculee'] ?? 0;

    return _buildRecapSection(
      'Détails du Contrat',
      Icons.family_restroom_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow(
            'Produit', 'CORIS FAMILIS', 'Durée', '$duree années'),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Prime ${data['periodicite'] == 'unique' ? 'unique' : 'annuelle'}',
            _formatMontant(prime),
            'Capital à garantir',
            _formatMontant(capital)),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'échéance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildFlexEmprunteurSection(Map<String, dynamic> data) {
    return _buildRecapSection(
      'Détails du Contrat',
      Icons.home_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'FLEX EMPRUNTEUR', 'Type de prêt',
            data['type_pret'] ?? 'Non défini'),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Capital à garantir',
            _formatMontant(data['capital']),
            'Durée',
            '${data['duree']} ${data['duree_type']}'),
        if (data['date_effet'] != null && data['date_echeance'] != null)
          _buildCombinedRecapRow(
              'Date d\'effet',
              _formatDate(data['date_effet']),
              'Date d\'échéance',
              _formatDate(data['date_echeance'])),
        if (data['date_effet'] != null && data['date_echeance'] == null)
          _buildCombinedRecapRow(
              'Date d\'effet', _formatDate(data['date_effet']), '', ''),
        if (data['date_effet'] == null && data['date_echeance'] != null)
          _buildCombinedRecapRow(
              'Date d\'échéance', _formatDate(data['date_echeance']), '', ''),
        _buildCombinedRecapRow('Prime annuelle estimée',
            _formatMontant(data['prime_annuelle']), '', ''),
        if (data['garantie_prevoyance'] == true &&
            data['garantie_perte_emploi'] == true)
          _buildCombinedRecapRow(
              'Garantie Prévoyance',
              _formatMontant(data['capital_prevoyance']),
              'Garantie Perte d\'emploi',
              _formatMontant(data['capital_perte_emploi'])),
        if (data['garantie_prevoyance'] == true &&
            data['garantie_perte_emploi'] != true)
          _buildCombinedRecapRow('Garantie Prévoyance',
              _formatMontant(data['capital_prevoyance']), '', ''),
        if (data['garantie_prevoyance'] != true &&
            data['garantie_perte_emploi'] == true)
          _buildCombinedRecapRow('Garantie Perte d\'emploi',
              _formatMontant(data['capital_perte_emploi']), '', ''),
      ],
    );
  }

  Widget _buildRetraiteSection(Map<String, dynamic> data) {
    final duree = data['duree'] ?? 'Non définie';

    return _buildRecapSection(
      'Détails du Contrat',
      Icons.savings_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'CORIS RETRAITE',
            'Prime ${data['periodicite']}', _formatMontant(data['prime'])),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Capital au terme',
            _formatMontant(data['capital']),
            'Durée du contrat',
            '$duree ${data['duree_type'] == 'années' ? 'ans' : 'mois'}'),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'échéance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildSereniteSection(Map<String, dynamic> data) {
    final duree = data['duree'] ?? 'Non définie';

    return _buildRecapSection(
      'Détails du Contrat',
      Icons.health_and_safety_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'CORIS SÉRÉNITÉ',
            'Prime ${data['periodicite']}', _formatMontant(data['prime'])),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Capital au terme',
            _formatMontant(data['capital']),
            'Durée du contrat',
            '$duree ${data['duree_type'] == 'années' ? 'ans' : 'mois'}'),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'échéance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildDefaultProductSection(Map<String, dynamic> data) {
    return _buildRecapSection(
      'Détails du Contrat',
      Icons.security_outlined,
      const Color(0xFF10B981),
      [
        _buildRecapRow('Produit', _getBadgeText(_getProductType())),
        _buildRecapRow('Statut', _getContractStatus()),
        _buildRecapRow(
            'Date de création',
            _formatDate(_subscriptionData?['date_creation'] ??
                _subscriptionData?['created_at'])),

        if (data['capital'] != null)
          _buildRecapRow('Capital', _formatMontant(data['capital'])),

        if (data['prime'] != null)
          _buildRecapRow('Prime', _formatMontant(data['prime'])),

        if (data['duree'] != null)
          _buildRecapRow(
              'Durée',
              data['duree']
                  .toString()), // CORRECTION : suppression interpolation inutile
      ],
    );
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
            ),
            const SizedBox(height: 16),
            const Text(
              "Chargement du contrat...",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: const Color(0xFF002B6B),
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
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadContractData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B6B),
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
    final status = _getContractStatus();
    final statusColor = _getStatusColor(status);
    final badgeColor = _getBadgeColor(_getProductType());

    // CORRECTION : remplacement de withOpacity
    final badgeColorWithAlpha = Color.alphaBlend(
      badgeColor.withAlpha((255 * 0.8).round()),
      Colors.transparent,
    );

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: badgeColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                badgeColor,
                badgeColorWithAlpha,
              ],
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contractNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              _getBadgeText(_getProductType()),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(
                    230), // CORRECTION : withAlpha au lieu de withOpacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(
              255, 255, 255, 0.15), // CORRECTION : Color.fromRGBO
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color.fromRGBO(
                255, 255, 255, 0.2), // CORRECTION : Color.fromRGBO
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/client_home');
            }
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(
                255, 255, 255, 0.15), // CORRECTION : Color.fromRGBO
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color.fromRGBO(
                  255, 255, 255, 0.2), // CORRECTION : Color.fromRGBO
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: _shareContract,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildUserInfoCard(),
          const SizedBox(height: 16),
          _buildProductSection(),
          const SizedBox(height: 16),
          _buildPaymentInfoCard(),
          const SizedBox(height: 16),
          _buildBeneficiariesCard(),
          const SizedBox(height: 16),
          _buildDocumentsCard(),
          const SizedBox(height: 16),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0F172A).withAlpha(10), // CORRECTION : withAlpha
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informations Personnelles",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildCombinedRecapRow(
                'Civilité',
                _userData?['civilite'] ?? 'Non renseigné',
                'Nom',
                _userData?['nom'] ?? 'Non renseigné'),
            _buildCombinedRecapRow(
                'Prénom',
                _userData?['prenom'] ?? 'Non renseigné',
                'Email',
                _userData?['email'] ?? 'Non renseigné'),
            _buildCombinedRecapRow(
                'Téléphone',
                _userData?['telephone'] ?? 'Non renseigné',
                'Date de naissance',
                _formatDate(_userData?['date_naissance'])),
            _buildCombinedRecapRow(
                'Lieu de naissance',
                _userData?['lieu_naissance'] ?? 'Non renseigné',
                'Adresse',
                _userData?['adresse'] ?? 'Non renseigné'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0F172A).withAlpha(10), // CORRECTION : withAlpha
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25), // CORRECTION : withAlpha
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
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

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedRecapRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label1 :',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                Text(
                  value1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label2 :',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                Text(
                  value2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesCard() {
    final subscriptionData = _getSubscriptionDetails();
    final beneficiaire = subscriptionData['beneficiaire'];
    final contactUrgence = subscriptionData['contact_urgence'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0F172A).withAlpha(10), // CORRECTION : withAlpha
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bénéficiaires et Contacts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            if (beneficiaire != null) ...[
              _buildContactItem(
                "Bénéficiaire",
                beneficiaire['nom'] ?? 'Non spécifié',
                beneficiaire['lien_parente'] ?? 'Bénéficiaire',
                beneficiaire['contact'],
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
            ],
            if (contactUrgence != null) ...[
              _buildContactItem(
                "Contact d'urgence",
                contactUrgence['nom'] ?? 'Non spécifié',
                contactUrgence['lien_parente'] ?? 'Contact',
                contactUrgence['contact'],
                Icons.contact_phone_outlined,
              ),
            ],
            if (beneficiaire == null && contactUrgence == null) ...[
              const Text(
                "Aucun bénéficiaire ou contact spécifié",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(String type, String nom, String relation,
      String? contact, IconData icon) {
    final badgeColor = _getBadgeColor(_getProductType());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(25), // CORRECTION : withAlpha
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: badgeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (relation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    relation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                if (contact != null && contact.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    contact,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractDocumentsList(dynamic raw) {
    final docs = <Map<String, dynamic>>[];

    void addDoc(dynamic path, {dynamic label}) {
      if (path == null) return;
      final normalizedPath = _extractServerFileName(path);
      if (normalizedPath == null) return;
      final normalizedLabel = label?.toString().trim();
      docs.add({
        'path': normalizedPath,
        if (normalizedLabel != null && normalizedLabel.isNotEmpty)
          'label': normalizedLabel,
      });
    }

    void parse(dynamic value) {
      if (value == null) return;

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return;
        if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
            (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
          try {
            parse(jsonDecode(trimmed));
            return;
          } catch (_) {
            addDoc(trimmed);
            return;
          }
        }
        addDoc(trimmed);
        return;
      }

      if (value is List) {
        for (final item in value) {
          parse(item);
        }
        return;
      }

      if (value is Map) {
        if (value['path'] != null ||
            value['url'] != null ||
            value['filename'] != null) {
          addDoc(
            value['path'] ?? value['url'] ?? value['filename'] ?? value['name'],
            label: value['label'] ?? value['title'] ?? value['name'],
          );
          return;
        }

        for (final entry in value.entries) {
          final key = entry.key.toString();
          final entryValue = entry.value;
          if (entryValue is String) {
            addDoc(entryValue, label: key);
          } else {
            parse(entryValue);
          }
        }
      }
    }

    parse(raw);

    final seen = <String>{};
    return docs.where((doc) {
      final path = doc['path']?.toString() ?? '';
      if (path.isEmpty || seen.contains(path)) return false;
      seen.add(path);
      return true;
    }).toList();
  }

  Widget _buildDocumentsCard() {
    final subscriptionData = _getSubscriptionDetails();
    // Recherche robuste de la pièce d'identité depuis tous les emplacements possibles.
    final pieceIdentite = _extractServerFileName(
      subscriptionData['piece_identite'] ??
          subscriptionData['pieceIdentite'] ??
          subscriptionData['piece_identite_url'] ??
          _subscriptionData?['piece_identite'] ??
          _subscriptionData?['piece_identite_url'],
    );

    final pieceIdentiteLabel = (subscriptionData['piece_identite_label'] ??
            _subscriptionData?['piece_identite_label'] ??
            pieceIdentite)
        ?.toString();

    final docsList = <Map<String, dynamic>>[
      ..._extractDocumentsList(subscriptionData['documents']),
      ..._extractDocumentsList(_subscriptionData?['documents']),
      ..._extractDocumentsList(subscriptionData['souscription_documents']),
      ..._extractDocumentsList(_subscriptionData?['souscription_documents']),
    ];

    // Inclure aussi pieceIdentite s'il existe (pour afficher toutes les pièces d'identité)
    if (pieceIdentite != null && pieceIdentite.toString().trim().isNotEmpty) {
      final identityPath = pieceIdentite.toString().trim();
      final alreadyExists = docsList.any((doc) {
        final docPath = doc['path']?.toString().trim();
        return docPath != null && docPath == identityPath;
      });
      if (!alreadyExists) {
        docsList.insert(0, {
          'path': identityPath,
          'label': pieceIdentiteLabel ?? 'Pièce d\'identité',
        });
      }
    }

    final normalizedDocsList = docsList.isEmpty ? null : docsList;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Documents",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            SubscriptionRecapWidgets.buildDocumentsSection(
              pieceIdentite: pieceIdentiteLabel,
              documents: normalizedDocsList,
              onDocumentTap: pieceIdentite != null
                  ? () => _viewDocument(pieceIdentite, pieceIdentiteLabel)
                  : null,
              onDocumentTapWithInfo: (path, label) =>
                  _viewDocument(path, label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(
      String label, String? documentName, String? displayLabel) {
    final hasDocument = documentName != null &&
        documentName.isNotEmpty &&
        documentName != 'Non téléchargée';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF002B6B).withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.credit_card,
              color: const Color(0xFF002B6B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayLabel ?? 'Non téléchargée',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (hasDocument) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _viewDocument(documentName, displayLabel),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF002B6B).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Color(0xFF002B6B),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewDocument(String? documentName, String? displayLabel) {
    if (documentName == null ||
        documentName.isEmpty ||
        documentName == 'Non téléchargée') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Aucun document disponible'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final normalizedDocumentName = Uri.decodeFull(documentName)
        .replaceAll('\\\\', '/')
        .split('/')
        .last
        .trim();

    if (normalizedDocumentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom du document invalide'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    // Ouvrir le viewer de documents
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          documentName: normalizedDocumentName,
          displayLabel: displayLabel,
          subscriptionId: widget.subscriptionId,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final status = _getContractStatus();
    final suggestedAmount = _getSuggestedPaymentAmount();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ContractPaymentFlow.showSearchAndAmountDialog(
                      context,
                      initialPolicyNumber: widget.contractNumber,
                      knownSubscriptionId: widget.subscriptionId,
                      initialAmount:
                          suggestedAmount > 0 ? suggestedAmount : null,
                      onPaymentSuccess: _loadContractData,
                    );
                  },
                  icon: const Icon(Icons.payment_outlined),
                  label: const Text(
                    'Payer mes cotisations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002B6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viewContractPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF002B6B)),
                    foregroundColor: const Color(0xFF002B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'Voir le PDF du contrat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _downloadContract,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF002B6B)),
                        foregroundColor: const Color(0xFF002B6B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Télécharger',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: status == 'Échu' || status == 'Bientôt échu'
                          ? _renewContract
                          : _contactSupport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getBadgeColor(_getProductType()),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        status == 'Échu' || status == 'Bientôt échu'
                            ? 'Renouveler'
                            : 'Contacter le support',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewContractPdf() {
    HapticFeedback.lightImpact();

    final productType = _getProductType().toLowerCase();
    final excludeQuestionnaire = productType.contains('etude') ||
        productType.contains('familis') ||
        productType.contains('serenite') ||
        productType.contains('sérénité');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          subscriptionId: widget.subscriptionId,
          excludeQuestionnaire: excludeQuestionnaire,
        ),
      ),
    );
  }

  Future<void> _shareContract() async {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Préparation du PDF à partager...'),
        backgroundColor: _getBadgeColor(_getProductType()),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // Réutilise le même endpoint PDF que le bouton Télécharger pour garantir la cohérence.
      final productType = _getProductType().toLowerCase();
      final excludeQuestionnaire = productType.contains('etude') ||
          productType.contains('familis') ||
          productType.contains('serenite') ||
          productType.contains('sérénité');

      final tempFile = await PdfService.fetchToTemp(
        widget.subscriptionId,
        excludeQuestionnaire: excludeQuestionnaire,
      );

      final policy = widget.contractNumber.isNotEmpty
          ? widget.contractNumber
          : '#${widget.subscriptionId}';

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Contrat CORIS $policy',
        text: 'Veuillez trouver ci-joint mon contrat CORIS $policy.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de partage du contrat: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadContract() async {
    HapticFeedback.lightImpact();

    final notificationId = 10000 + widget.subscriptionId;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Téléchargement du contrat en cours...'),
        backgroundColor: _getBadgeColor(_getProductType()),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await DownloadNotificationService.showProgress(
        notificationId,
        title: 'Telechargement du contrat CORIS',
        progress: 0,
      );

      final productType = _getProductType().toLowerCase();
      final excludeQuestionnaire = productType.contains('etude') ||
          productType.contains('familis') ||
          productType.contains('serenite') ||
          productType.contains('sérénité');

      final downloadedFile = await PdfService.downloadToDownloadsWithProgress(
        widget.subscriptionId,
        excludeQuestionnaire: excludeQuestionnaire,
        onProgress: (progress) {
          DownloadNotificationService.showProgress(
            notificationId,
            title: 'Telechargement du contrat CORIS',
            progress: progress,
          );
        },
      );

      await DownloadNotificationService.showCompleted(
        notificationId,
        title: 'Telechargement termine',
        filePath: downloadedFile.path,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                    'Contrat telecharge. Ouvrez la notification pour afficher le fichier.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      await DownloadNotificationService.showFailed(
        notificationId,
        title: 'Echec du telechargement',
        message: 'Impossible de telecharger le contrat',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Erreur téléchargement contrat: $e'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _renewContract() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Redirection vers le renouvellement...'),
        backgroundColor: _getBadgeColor(_getProductType()),
      ),
    );
  }

  Future<void> _contactSupport() async {
    HapticFeedback.lightImpact();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Text(
                  'Contacter le support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.email_outlined,
                      color: Color(0xFF002B6B)),
                  title: const Text('Par e-mail'),
                  subtitle: Text(AppConfig.supportEmail),
                  onTap: () async {
                    final emailUri =
                        Uri.parse('mailto:${AppConfig.supportEmail}');
                    Navigator.pop(context);
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined,
                      color: Color(0xFF002B6B)),
                  title: const Text('Par appel'),
                  subtitle: Text(AppConfig.supportPhone),
                  onTap: () async {
                    final phoneUri = Uri.parse('tel:${AppConfig.supportPhone}');
                    Navigator.pop(context);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
