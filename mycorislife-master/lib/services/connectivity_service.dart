import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service de gestion de la connectivité
/// Détecte et notifie les changements de connexion internet
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialise l'écoute des changements de connexion
  void initialize() {
    _checkConnection();

    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
  }

  /// Vérifie la connexion internet
  Future<void> _checkConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('❌ Erreur vérification connexion: $e');
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  /// Met à jour le statut de connexion
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    if (wasConnected != _isConnected) {
      debugPrint(
          '📡 Connexion internet: ${_isConnected ? "✅ Connecté" : "❌ Déconnecté"}');
      connectionStatusController.add(_isConnected);
    }
  }

  /// Vérifie manuellement la connexion
  Future<bool> checkConnection() async {
    await _checkConnection();
    return _isConnected;
  }

  /// Dispose le service
  void dispose() {
    connectionStatusController.close();
  }
}

/// Widget pour afficher l'état de connexion
class ConnectivityBanner extends StatelessWidget {
  final bool isConnected;

  const ConnectivityBanner({
    Key? key,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange[700],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Mode hors ligne - Données locales utilisées',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Builder avec gestion de connectivité
class ConnectivityBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isConnected) builder;

  const ConnectivityBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<ConnectivityBuilder> createState() => _ConnectivityBuilderState();
}

class _ConnectivityBuilderState extends State<ConnectivityBuilder> {
  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<bool> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;
    _subscription = _connectivityService.connectionStatusController.stream
        .listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isConnected);
  }
}
