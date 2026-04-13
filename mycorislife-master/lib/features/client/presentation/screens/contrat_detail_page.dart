import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
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

      developer.log('=== TOUTES LES CLÃ‰S DISPONIBLES CONTRAT ===');
      if (data['subscription'] != null) {
        developer.log('ClÃ©s dans subscription: ${data['subscription'].keys}');
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
      if (dateValue == null) return 'Non dÃ©finie';

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
      'validÃ©',
      'validÃ©e',
      'confirmÃ©',
      'confirmÃ©e',
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
      return 'CORIS SOLIDARITÃ‰';
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return 'FLEX EMPRUNTEUR';
    } else if (produit.toLowerCase().contains('etude')) {
      return 'CORIS Ã‰TUDE';
    } else if (produit.toLowerCase().contains('retraite')) {
      return 'CORIS RETRAITE';
    } else if (produit.toLowerCase().contains('serenite')) {
      return 'CORIS SÃ‰RÃ‰NITÃ‰';
    } else if (produit.toLowerCase().contains('familis')) {
      return 'CORIS FAMILIS';
    } else if (produit.toLowerCase().contains('epargne')) {
      return 'CORIS Ã‰PARGNE BONUS';
    } else {
      return 'ASSURANCE VIE';
    }
  }

  // MÃ‰THODE SUPPRIMÃ‰E : _getProductIcon n'est pas utilisÃ©e
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
  /// Accepte: URL complÃ¨te, chemin local, ou nom brut.
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
          return 'Ã‰chu';
        } else if (echeance.difference(now).inDays <= 30) {
          return 'BientÃ´t Ã©chu';
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
      case 'BientÃ´t Ã©chu':
        return const Color(0xFFF59E0B);
      case 'Ã‰chu':
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
        developer.log('Erreur calcul date Ã©chÃ©ance: $e', error: e);
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
        _buildCombinedRecapRow('Statut provider', providerStatus, '', ''),
        _buildCombinedRecapRow('Validation', validationStatus, '', ''),
      ],
    );
  }

  Widget _buildSolidariteSection(Map<String, dynamic> data) {
    final capital = data['capital'] ?? 0;
    final primeTotale = data['prime_totale'] ?? 0;
    final periodicite = data['periodicite'] ?? 'Non dÃ©finie';
    final conjoints = data['conjoints'] ?? [];
    final enfants = data['enfants'] ?? [];
    final ascendants = data['ascendants'] ?? [];

    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.people_outline,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow(
            'Produit', 'CORIS SOLIDARITÃ‰', 'PÃ©riodicitÃ©', periodicite),
        _buildCombinedRecapRow('Capital garanti', _formatMontant(capital),
            'Prime totale', _formatMontant(primeTotale)),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        if (conjoints.isNotEmpty) ...[
          SizedBox(height: context.r(12)),
          _buildMembresSection('Conjoint(s)', Icons.people_outline, conjoints),
        ],
        if (enfants.isNotEmpty) ...[
          SizedBox(height: context.r(12)),
          _buildMembresSection('Enfant(s)', Icons.child_care_outlined, enfants),
        ],
        if (ascendants.isNotEmpty) ...[
          SizedBox(height: context.r(12)),
          _buildMembresSection(
              'Ascendant(s)', Icons.elderly_outlined, ascendants),
        ],
        if (conjoints.isEmpty && enfants.isEmpty && ascendants.isEmpty) ...[
          SizedBox(height: context.r(8)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: Text(
              'Aucun membre assurÃ©',
              style: TextStyle(
                color: Color(0xFFD92D20),
                fontSize: context.sp(12),
              ),
            ),
          ),
        ],
        SizedBox(height: context.r(12)),
        _buildCombinedRecapRow(
          'Date d\'effet',
          _formatDate(data['date_effet']),
          'Date d\'Ã©chÃ©ance',
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
            SizedBox(width: context.r(8)),
            Text(
              titre,
              style: TextStyle(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w600,
                color: Color(0xFF002B6B),
              ),
            ),
          ],
        ),
        SizedBox(height: context.r(8)),
        ...membres.map((membre) => _buildMembreRecap(
            membre)), // CORRECTION : suppression .toList() inutile
      ],
    );
  }

  Widget _buildMembreRecap(dynamic membre) {
    final nomPrenom = membre['nom_prenom'] ??
        'Non renseignÃ©'; // CORRECTION : suppression duplication
    final dateNaissance = membre['date_naissance'] ??
        membre['birthDate'] ??
        membre['dateNaissance'];

    String lienParente = '';
    if (membre.containsKey('lien_parente')) {
      lienParente = membre['lien_parente'] ?? '';
    } else {
      lienParente = 'Membre assurÃ©';
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          if (lienParente.isNotEmpty) ...[
            SizedBox(height: context.r(4)),
            Text(
              'Relation: $lienParente',
              style: TextStyle(
                fontSize: context.sp(12),
                color: Color(0xFF64748B),
              ),
            ),
          ],
          if (dateNaissance != null) ...[
            SizedBox(height: context.r(4)),
            Text(
              'NÃ©(e) le: ${_formatDate(dateNaissance)}',
              style: TextStyle(
                fontSize: context.sp(12),
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
      'DÃ©tails du Contrat',
      Icons.savings_outlined,
      const Color(0xFF10B981),
      [
        _buildRecapRow('Produit', 'CORIS Ã‰PARGNE BONUS'),
        _buildRecapRow('Statut', _getContractStatus()),
        _buildRecapRow('Capital au terme', _formatMontant(data['capital'])),
        _buildRecapRow(
            'Prime mensuelle', _formatMontant(data['prime_mensuelle'])),
        _buildRecapRow('DurÃ©e', '15 ans (180 mois)'),
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
    final ageParent = data['age_parent'] ?? 'Non renseignÃ©';
    final dateNaissanceParent = data['date_naissance_parent'];

    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.school_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'CORIS Ã‰TUDE', 'Mode', mode),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
          'Ã‚ge du parent',
          '$ageParent ans',
          'Date de naissance',
          dateNaissanceParent != null
              ? _formatDate(dateNaissanceParent)
              : 'Non renseignÃ©e',
        ),
        _buildCombinedRecapRow(
          'Prime ${data['periodicite']}',
          _formatMontant(prime),
          'Rente au terme',
          _formatMontant(rente),
        ),
        _buildCombinedRecapRow(
            'DurÃ©e du contrat',
            '${data['duree_mois'] != null ? (data['duree_mois'] ~/ 12) : (17 - (data['age_enfant'] ?? 0))} ans (jusqu\'Ã  17 ans)',
            'PÃ©riodicitÃ©',
            data['periodicite'] ?? 'Non dÃ©finie'),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'Ã©chÃ©ance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildFamilisSection(Map<String, dynamic> data) {
    final duree = data['duree'] ?? 'Non dÃ©finie';
    final capital = data['capital'] ?? 0;
    final prime = data['prime'] ?? data['prime_calculee'] ?? 0;

    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.family_restroom_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow(
            'Produit', 'CORIS FAMILIS', 'DurÃ©e', '$duree annÃ©es'),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Prime ${data['periodicite'] == 'unique' ? 'unique' : 'annuelle'}',
            _formatMontant(prime),
            'Capital Ã  garantir',
            _formatMontant(capital)),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'Ã©chÃ©ance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildFlexEmprunteurSection(Map<String, dynamic> data) {
    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.home_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'FLEX EMPRUNTEUR', 'Type de prÃªt',
            data['type_pret'] ?? 'Non dÃ©fini'),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Capital Ã  garantir',
            _formatMontant(data['capital']),
            'DurÃ©e',
            '${data['duree']} ${data['duree_type']}'),
        if (data['date_effet'] != null && data['date_echeance'] != null)
          _buildCombinedRecapRow(
              'Date d\'effet',
              _formatDate(data['date_effet']),
              'Date d\'Ã©chÃ©ance',
              _formatDate(data['date_echeance'])),
        if (data['date_effet'] != null && data['date_echeance'] == null)
          _buildCombinedRecapRow(
              'Date d\'effet', _formatDate(data['date_effet']), '', ''),
        if (data['date_effet'] == null && data['date_echeance'] != null)
          _buildCombinedRecapRow(
              'Date d\'Ã©chÃ©ance', _formatDate(data['date_echeance']), '', ''),
        _buildCombinedRecapRow('Prime annuelle estimÃ©e',
            _formatMontant(data['prime_annuelle']), '', ''),
        if (data['garantie_prevoyance'] == true &&
            data['garantie_perte_emploi'] == true)
          _buildCombinedRecapRow(
              'Garantie PrÃ©voyance',
              _formatMontant(data['capital_prevoyance']),
              'Garantie Perte d\'emploi',
              _formatMontant(data['capital_perte_emploi'])),
        if (data['garantie_prevoyance'] == true &&
            data['garantie_perte_emploi'] != true)
          _buildCombinedRecapRow('Garantie PrÃ©voyance',
              _formatMontant(data['capital_prevoyance']), '', ''),
        if (data['garantie_prevoyance'] != true &&
            data['garantie_perte_emploi'] == true)
          _buildCombinedRecapRow('Garantie Perte d\'emploi',
              _formatMontant(data['capital_perte_emploi']), '', ''),
      ],
    );
  }

  Widget _buildRetraiteSection(Map<String, dynamic> data) {
    final duree = data['duree'] ?? 'Non dÃ©finie';

    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.savings_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'CORIS RETRAITE',
            'Prime ${data['periodicite']}', _formatMontant(data['prime'])),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Capital au terme',
            _formatMontant(data['capital']),
            'DurÃ©e du contrat',
            '$duree ${data['duree_type'] == 'annÃ©es' ? 'ans' : 'mois'}'),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'Ã©chÃ©ance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildSereniteSection(Map<String, dynamic> data) {
    final duree = data['duree'] ?? 'Non dÃ©finie';

    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.health_and_safety_outlined,
      const Color(0xFF10B981),
      [
        _buildCombinedRecapRow('Produit', 'CORIS SÃ‰RÃ‰NITÃ‰',
            'Prime ${data['periodicite']}', _formatMontant(data['prime'])),
        _buildCombinedRecapRow('Statut', _getContractStatus(), '', ''),
        _buildCombinedRecapRow(
            'Capital au terme',
            _formatMontant(data['capital']),
            'DurÃ©e du contrat',
            '$duree ${data['duree_type'] == 'annÃ©es' ? 'ans' : 'mois'}'),
        _buildCombinedRecapRow('Date d\'effet', _formatDate(data['date_effet']),
            'Date d\'Ã©chÃ©ance', _formatDate(data['date_echeance'])),
      ],
    );
  }

  Widget _buildDefaultProductSection(Map<String, dynamic> data) {
    return _buildRecapSection(
      'DÃ©tails du Contrat',
      Icons.security_outlined,
      const Color(0xFF10B981),
      [
        _buildRecapRow('Produit', _getBadgeText(_getProductType())),
        _buildRecapRow('Statut', _getContractStatus()),
        _buildRecapRow(
            'Date de crÃ©ation',
            _formatDate(_subscriptionData?['date_creation'] ??
                _subscriptionData?['created_at'])),

        if (data['capital'] != null)
          _buildRecapRow('Capital', _formatMontant(data['capital'])),

        if (data['prime'] != null)
          _buildRecapRow('Prime', _formatMontant(data['prime'])),

        if (data['duree'] != null)
          _buildRecapRow(
              'DurÃ©e',
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
            SizedBox(height: context.r(16)),
            Text(
              "Chargement du contrat...",
              style: TextStyle(
                fontSize: context.sp(16),
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
        title: Text('Erreur'),
        backgroundColor: const Color(0xFF002B6B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: context.r(16)),
            Text(
              "Erreur de chargement",
              style: TextStyle(
                fontSize: context.sp(20),
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: context.r(8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(16),
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            SizedBox(height: context.r(24)),
            ElevatedButton(
              onPressed: _loadContractData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B6B),
                foregroundColor: Colors.white,
              ),
              child: Text('RÃ©essayer'),
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
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              _getBadgeText(_getProductType()),
              style: TextStyle(
                fontSize: context.sp(12),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: context.r(4)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(
                    230), // CORRECTION : withAlpha au lieu de withOpacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: context.sp(11),
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
          icon: Icon(Icons.arrow_back_ios_new,
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
            icon: Icon(Icons.share, color: Colors.white, size: 20),
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
          SizedBox(height: context.r(16)),
          _buildUserInfoCard(),
          SizedBox(height: context.r(16)),
          _buildProductSection(),
          SizedBox(height: context.r(16)),
          _buildPaymentInfoCard(),
          SizedBox(height: context.r(16)),
          _buildBeneficiariesCard(),
          SizedBox(height: context.r(16)),
          _buildCommercialAssistanceCard(),
          SizedBox(height: context.r(16)),
          _buildDocumentsCard(),
          SizedBox(height: context.r(16)),
          SizedBox(height: context.r(100)),
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
            Text(
              "Informations Personnelles",
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: context.r(16)),
            _buildCombinedRecapRow(
                'CivilitÃ©',
                _userData?['civilite'] ?? 'Non renseignÃ©',
                'Nom',
                _userData?['nom'] ?? 'Non renseignÃ©'),
            _buildCombinedRecapRow(
                'PrÃ©nom',
                _userData?['prenom'] ?? 'Non renseignÃ©',
                'Email',
                _userData?['email'] ?? 'Non renseignÃ©'),
            _buildCombinedRecapRow(
                'TÃ©lÃ©phone',
                _userData?['telephone'] ?? 'Non renseignÃ©',
                'Date de naissance',
                _formatDate(_userData?['date_naissance'])),
            _buildCombinedRecapRow(
                'Lieu de naissance',
                _userData?['lieu_naissance'] ?? 'Non renseignÃ©',
                'Adresse',
                _userData?['adresse'] ?? 'Non renseignÃ©'),
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
              SizedBox(width: context.r(10)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: context.r(12)),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                fontSize: context.sp(14),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                fontSize: context.sp(14),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontSize: context.sp(14),
                  ),
                ),
                Text(
                  value1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontSize: context.sp(14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label2 :',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontSize: context.sp(14),
                  ),
                ),
                Text(
                  value2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontSize: context.sp(14),
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
            Text(
              "BÃ©nÃ©ficiaires et Contacts",
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: context.r(16)),
            if (beneficiaire != null) ...[
              _buildContactItem(
                "BÃ©nÃ©ficiaire",
                beneficiaire['nom'] ?? 'Non spÃ©cifiÃ©',
                beneficiaire['lien_parente'] ?? 'BÃ©nÃ©ficiaire',
                beneficiaire['contact'],
                beneficiaire['date_naissance'] ??
                    beneficiaire['dateNaissance'] ??
                    beneficiaire['date_de_naissance'],
                Icons.person_outline,
              ),
              SizedBox(height: context.r(12)),
            ],
            if (contactUrgence != null) ...[
              _buildContactItem(
                "Contact d'urgence",
                contactUrgence['nom'] ?? 'Non spÃ©cifiÃ©',
                contactUrgence['lien_parente'] ?? 'Contact',
                contactUrgence['contact'],
                contactUrgence['date_naissance'] ??
                    contactUrgence['dateNaissance'] ??
                    contactUrgence['date_de_naissance'],
                Icons.contact_phone_outlined,
              ),
            ],
            if (beneficiaire == null && contactUrgence == null) ...[
              Text(
                "Aucun bÃ©nÃ©ficiaire ou contact spÃ©cifiÃ©",
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialAssistanceCard() {
    final subscriptionData = _getSubscriptionDetails();
    final assistanceCommerciale = subscriptionData['assistance_commerciale'];

    if (assistanceCommerciale is! Map) {
      return const SizedBox.shrink();
    }

    final isAideParCommercial =
        assistanceCommerciale['is_aide_par_commercial'] == true;
    final nomPrenom = assistanceCommerciale['commercial_nom_prenom']?.toString();
    final codeApporteur =
        assistanceCommerciale['commercial_code_apporteur']?.toString();

    if (!isAideParCommercial &&
        (nomPrenom == null || nomPrenom.trim().isEmpty) &&
        (codeApporteur == null || codeApporteur.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return SubscriptionRecapWidgets.buildAssistanceCommercialeSection(
      nomPrenom: nomPrenom,
      codeApporteur: codeApporteur,
    );
  }

  Widget _buildContactItem(String type, String nom, String relation,
      String? contact, String? dateNaissance, IconData icon) {
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
          SizedBox(width: context.r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontSize: context.sp(12),
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.r(4)),
                Text(
                  nom,
                  style: TextStyle(
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (relation.isNotEmpty) ...[
                  SizedBox(height: context.r(2)),
                  Text(
                    relation,
                    style: TextStyle(
                      fontSize: context.sp(12),
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                if (dateNaissance != null && dateNaissance.isNotEmpty) ...[
                  SizedBox(height: context.r(2)),
                  Text(
                    'Date de naissance: ${SubscriptionRecapWidgets.formatDate(dateNaissance)}',
                    style: TextStyle(
                      fontSize: context.sp(12),
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                if (contact != null && contact.isNotEmpty) ...[
                  SizedBox(height: context.r(2)),
                  Text(
                    contact,
                    style: TextStyle(
                      fontSize: context.sp(12),
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

    // RÃ©cupÃ©ration robuste des documents d'identitÃ© multiples
    final identityDocs = <Map<String, dynamic>>[];
    final rawIdentityDocs = [
      subscriptionData['piece_identite_documents'],
      _subscriptionData?['piece_identite_documents'],
    ];

    for (var docList in rawIdentityDocs) {
      if (docList != null) {
        final extracted = _extractDocumentsList(docList);
        if (extracted.isNotEmpty) identityDocs.addAll(extracted);
      }
    }

    // Ajouter piÃ¨ce d'identitÃ© unique si elle existe
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
      ...identityDocs, // documents multiples
    ];

    if (pieceIdentite != null && pieceIdentite.trim().isNotEmpty) {
      final identityPath = pieceIdentite.trim();
      final alreadyExists = docsList.any((doc) {
        final docPath = doc['path']?.toString().trim();
        return docPath != null && docPath == identityPath;
      });
      if (!alreadyExists) {
        docsList.insert(0, {
          'path': identityPath,
          'label': pieceIdentiteLabel ?? 'PiÃ¨ce d\'identitÃ©',
        });
      }
    }

    // DÃ©duplication globale
    final seenPaths = <String>{};
    final deduplicatedDocsList = docsList.where((doc) {
      final path = doc['path']?.toString().trim() ?? '';
      if (path.isEmpty || seenPaths.contains(path)) return false;
      seenPaths.add(path);
      return true;
    }).toList();

    final normalizedDocsList =
        deduplicatedDocsList.isEmpty ? null : deduplicatedDocsList;

    final totalDocuments = normalizedDocsList?.length ?? 0;

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
            Text(
              totalDocuments > 0 ? "Documents ($totalDocuments)" : "Documents",
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: context.r(16)),
            SubscriptionRecapWidgets.buildDocumentsSection(
              pieceIdentite: pieceIdentiteLabel,
              documents: normalizedDocsList,
              onDocumentTap: pieceIdentite != null
                  ? () => _viewDocument(pieceIdentite, pieceIdentiteLabel)
                  : null,
              onDocumentTapWithInfo: (path, label) =>
                  _viewDocument(path, label),
              documentCount: totalDocuments,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDocumentRow(
      String label, String? documentName, String? displayLabel) {
    final hasDocument = documentName != null &&
        documentName.isNotEmpty &&
        documentName != 'Non tÃ©lÃ©chargÃ©e';

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
          SizedBox(width: context.r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.sp(12),
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.r(4)),
                Text(
                  displayLabel ?? 'Non tÃ©lÃ©chargÃ©e',
                  style: TextStyle(
                    fontSize: context.sp(14),
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (hasDocument) ...[
            SizedBox(width: context.r(12)),
            InkWell(
              onTap: () => _viewDocument(documentName, displayLabel),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF002B6B).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
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
        documentName == 'Non tÃ©lÃ©chargÃ©e') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: context.r(12)),
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
                  icon: Icon(Icons.payment_outlined),
                  label: Text(
                    'Payer mes cotisations',
                    style: TextStyle(
                      fontSize: context.sp(16),
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
              SizedBox(height: context.r(12)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viewContractPdf,
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF002B6B)),
                    foregroundColor: const Color(0xFF002B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    'Voir le PDF du contrat',
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.r(12)),
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
                      child: Text(
                        'TÃ©lÃ©charger',
                        style: TextStyle(
                          fontSize: context.sp(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.r(12)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: status == 'Ã‰chu' || status == 'BientÃ´t Ã©chu'
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
                        status == 'Ã‰chu' || status == 'BientÃ´t Ã©chu'
                            ? 'Renouveler'
                            : 'Contacter le support',
                        style: TextStyle(
                          fontSize: context.sp(16),
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
        productType.contains('sÃ©rÃ©nitÃ©');

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
        content: Text('PrÃ©paration du PDF Ã  partager...'),
        backgroundColor: _getBadgeColor(_getProductType()),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // RÃ©utilise le mÃªme endpoint PDF que le bouton TÃ©lÃ©charger pour garantir la cohÃ©rence.
      final productType = _getProductType().toLowerCase();
      final excludeQuestionnaire = productType.contains('etude') ||
          productType.contains('familis') ||
          productType.contains('serenite') ||
          productType.contains('sÃ©rÃ©nitÃ©');

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
        content: Text('TÃ©lÃ©chargement du contrat en cours...'),
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
          productType.contains('sÃ©rÃ©nitÃ©');

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
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: context.r(12)),
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
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: context.r(12)),
              Expanded(
                child: Text('Erreur tÃ©lÃ©chargement contrat: $e'),
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
        content: Text('Redirection vers le renouvellement...'),
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
                Text(
                  'Contacter le support',
                  style: TextStyle(fontSize: context.sp(18), fontWeight: FontWeight.w700),
                ),
                SizedBox(height: context.r(14)),
                ListTile(
                  leading: Icon(Icons.email_outlined,
                      color: Color(0xFF002B6B)),
                  title: Text('Par e-mail'),
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
                  leading: Icon(Icons.phone_outlined,
                      color: Color(0xFF002B6B)),
                  title: Text('Par appel'),
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

