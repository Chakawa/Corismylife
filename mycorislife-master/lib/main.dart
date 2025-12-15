import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mycorislife/config/routes.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:mycorislife/services/connectivity_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de connectivité
  ConnectivityService().initialize();

  runApp(const MyCorisLifeApp());
}

class MyCorisLifeApp extends StatefulWidget {
  const MyCorisLifeApp({super.key});

  @override
  State<MyCorisLifeApp> createState() => _MyCorisLifeAppState();
}

class _MyCorisLifeAppState extends State<MyCorisLifeApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Variables pour gérer le timeout de reconnexion
  DateTime? _pausedTime;
  static const Duration _sessionTimeout =
      Duration(minutes: 5); // 5 minutes d'inactivité en arrière-plan

  // Channel natif pour détecter le verrouillage d'écran
  static const MethodChannel _screenLockChannel =
      MethodChannel('com.coris.mycorislife/screen_lock');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScreenLockListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialise l'écoute native du verrouillage d'écran
  void _initScreenLockListener() {
    _screenLockChannel.setMethodCallHandler((call) async {
      debugPrint('🔔 Événement natif reçu: ${call.method}');

      // DÉSACTIVÉ : Ne plus forcer la reconnexion au déverrouillage d'écran
      // Seul le timeout de 5 minutes en arrière-plan est actif
      // if (call.method == 'onScreenUnlocked') {
      //   debugPrint(
      //       '🔓 ÉCRAN DÉVERROUILLÉ (détection native) - reconnexion immédiate');
      //   _forceReconnection('Écran déverrouillé - sécurité');
      // }
    });

    debugPrint(
        '✅ Listener natif initialisé pour verrouillage d\'écran (DÉSACTIVÉ)');
  }

  void _forceReconnection(String reason) {
    debugPrint('🔒 $reason - reconnexion requise');

    // Forcer la reconnexion
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );

    // Afficher un message
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _navigatorKey.currentContext;
      if (context != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                reason.contains('écran') || reason.contains('verrouillé')
                    ? 'Veuillez vous reconnecter pour des raisons de sécurité.'
                    : 'Votre session a expiré. Veuillez vous reconnecter.'),
            backgroundColor: const Color(0xFF002B6B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('📱 AppLifecycleState changé: $state');

    // LOGIQUE DE SÉCURITÉ DOUBLE :
    // 1. Plugin natif Android détecte ACTION_USER_PRESENT → reconnexion immédiate (écran déverrouillé)
    // 2. Flutter détecte temps en arrière-plan → timeout 5 minutes (changement d'app)

    if (state == AppLifecycleState.paused) {
      // L'app passe en arrière-plan : enregistrer l'heure de début
      _pausedTime = DateTime.now();
      debugPrint('⏸️ App mise en arrière-plan à $_pausedTime');
    } else if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan
      debugPrint('🔄 App resumed');

      // Vérifier UNIQUEMENT le timeout de 5 minutes en arrière-plan
      // Le verrouillage d'écran est géré par ACTION_USER_PRESENT (plugin natif)
      if (_pausedTime != null) {
        final timeInBackground = DateTime.now().difference(_pausedTime!);
        debugPrint(
            '⏱️ Temps en arrière-plan: ${timeInBackground.inMinutes} minutes ${timeInBackground.inSeconds % 60} secondes');

        // Forcer la reconnexion si plus de 5 minutes en arrière-plan
        if (timeInBackground >= _sessionTimeout) {
          debugPrint(
              '🔒 Session expirée après ${timeInBackground.inMinutes} minutes - reconnexion requise');
          _forceReconnection(
              'Session expirée (${timeInBackground.inMinutes} minutes)');
        } else {
          debugPrint(
              '✅ Session toujours valide (${timeInBackground.inMinutes}min ${timeInBackground.inSeconds % 60}s) - pas de reconnexion nécessaire');
        }

        _pausedTime = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher de loader, toujours commencer par la page de connexion
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'MyCorisLife',
      theme: appTheme,
      initialRoute: '/login', // Toujours commencer par la page de connexion
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
      // Configuration de la localisation en français
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
