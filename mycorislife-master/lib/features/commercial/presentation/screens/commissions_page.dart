/// ================================================
/// PAGE - COMMISSIONS DU COMMERCIAL
/// ================================================
/// 
/// Page permettant au commercial de visualiser toutes ses commissions.
/// Les commissions sont simples: id, code_apporteur, montant_commission, date_calcul

import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mycorislife/config/app_config.dart';

class CommissionsPage extends StatefulWidget {
  final String? codeApporteur;

  const CommissionsPage({
    super.key,
    this.codeApporteur,
  });

  @override
  State<CommissionsPage> createState() => _CommissionsPageState();
}

class _CommissionsPageState extends State<CommissionsPage>
    with TickerProviderStateMixin {
  // Constantes de couleurs CORIS
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color orangeCoris = Color(0xFFFF9500);
  static const Color rougeErreur = Color(0xFFEF4444);
  static const Color blanc = Colors.white;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final storage = const FlutterSecureStorage();

  String? _codeApporteur;
  String? _token;
  bool _isLoading = true;
  String? _errorMessage;

  // DonnÃ©es simples
  List<Map<String, dynamic>> _commissions = [];
  double _totalCommission = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // RÃ©cupÃ©rer le token
      _token = await storage.read(key: 'token');
      if (_token == null) {
        throw Exception('Token non trouvÃ©');
      }

      // RÃ©cupÃ©rer le code apporteur
      _codeApporteur = widget.codeApporteur ??
          await storage.read(key: 'code_apporteur');
      if (_codeApporteur == null) {
        throw Exception('Code apporteur non trouvÃ©');
      }

      // Charger les commissions
      await _loadCommissions();

      _animationController.forward();
    } catch (e) {
      print('âŒ Erreur initialisation: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCommissions() async {
    try {
      if (_codeApporteur == null || _token == null) return;

      print('ðŸ”„ Chargement commissions pour: $_codeApporteur');

      final url =
          '${AppConfig.baseUrl}/commissions/commercial/$_codeApporteur';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            _commissions = List<Map<String, dynamic>>.from(data['commissions'] ?? []);
            _totalCommission = (data['resume']?['total_commission'] as num?)?.toDouble() ?? 0.0;
            _isLoading = false;
            _errorMessage = null;
          });
        }

        print('âœ… ${_commissions.length} commission(s) chargÃ©e(s)');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('âŒ Erreur chargement: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: bleuCoris,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Mes Commissions en Instance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: context.sp(18),
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: bleuCoris,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: bleuCoris,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Mes Commissions en Instance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: context.sp(18),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: rougeErreur),
              SizedBox(height: context.r(16)),
              Text(
                'Erreur: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(color: rougeErreur),
              ),
              SizedBox(height: context.r(16)),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initializeData();
                },
                child: const Text('RÃ©essayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bleuCoris,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/commercial_home',
              (route) => false,
            );
          },
        ),
        title: Text(
          'Mes Commissions en Instance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: context.sp(18),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadCommissions();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
            child: _buildResumCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildResumCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bleuCoris, bleuCoris.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: blanc.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: blanc,
                  size: 32,
                ),
              ),
              SizedBox(width: context.r(16)),
              Text(
                'Total des Commissions',
                style: TextStyle(
                  color: blanc,
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: context.r(16)),
          Text(
            _formatCurrency(_totalCommission),
            style: TextStyle(
              color: blanc,
              fontSize: context.sp(36),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: context.r(8)),
          Text(
            '${_commissions.length} commission${_commissions.length > 1 ? 's' : ''}',
            style: TextStyle(
              color: blanc.withValues(alpha: 0.9),
              fontSize: context.sp(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCommissionCard(Map<String, dynamic> commission) {
    final id = commission['id'];
    final montant = (commission['montant_commission'] as num?)?.toDouble() ?? 0.0;
    final dateCalcul = commission['date_calcul'] != null 
        ? DateTime.parse(commission['date_calcul'].toString())
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tÃªte avec ID et montant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commission #$id',
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: context.r(4)),
                    Text(
                      _formatCurrency(montant),
                      style: TextStyle(
                        fontSize: context.sp(24),
                        fontWeight: FontWeight.bold,
                        color: bleuCoris,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: vertSucces.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: vertSucces,
                    size: 28,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.r(16)),
            // SÃ©parateur
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            SizedBox(height: context.r(16)),
            // Date de calcul
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: orangeCoris),
                SizedBox(width: context.r(8)),
                Text(
                  _formatDate(dateCalcul),
                  style: TextStyle(
                    fontSize: context.sp(14),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

