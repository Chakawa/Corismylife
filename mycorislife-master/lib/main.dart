import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mycorislife/config/routes.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/services/connectivity_service.dart';
import 'package:mycorislife/services/payment_resume_coordinator.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Au cold start iOS, [PlatformDispatcher.views] peut être vide un instant ;
/// [views.first] provoque une exception → crash avant [runApp] (écran noir).
Future<void> syncPreferredOrientationsToDisplay() async {
  try {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
      return;
    }
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final isTablet = logicalSize.shortestSide >= 600;
    await SystemChrome.setPreferredOrientations(
      isTablet
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
            ],
    );
  } catch (e, st) {
    debugPrint(
        'syncPreferredOrientationsToDisplay: portrait par défaut — $e\n$st');
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser le service de connectivité (tolérant aux erreurs)
  try {
    ConnectivityService().initialize();
  } catch (e, st) {
    debugPrint('⚠️ Impossible d\'initialiser la connectivité: $e\n$st');
  }
  // Initialiser les notifications de téléchargement (ne doit pas bloquer le démarrage)
  // ❌ TEMPORAIREMENT DÉSACTIVÉ POUR TEST iOS (écran blanc possible)
// À réactiver après correction du plugin notifications
  // try {
  //   await DownloadNotificationService.initialize();
  // } catch (e, st) {
  //   debugPrint('⚠️ Impossible d\'initialiser les notifications: $e\n$st');
  // }
  await syncPreferredOrientationsToDisplay();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // Setup global error handlers to capture startup errors (useful for release/TestFlight)
  FlutterError.onError = (FlutterErrorDetails details) {
    // Forward to zone to ensure it's captured by runZonedGuarded
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.empty);
  };

  runZonedGuarded(() {
    // Fallback UI for uncaught framework errors (shows a simple message instead of white screen)
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Une erreur est survenue au démarrage. Vérifiez les logs via Xcode/TestFlight.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red[700]),
            ),
          ),
        ),
      );
    };
    runApp(const MyCorisLifeApp());
  }, (error, stack) {
    // Log to console - visible in device logs / Xcode Organizer
    debugPrint('🔥 Erreur non gérée capturée: $error');
    debugPrint('🔥 Stack: $stack');
  });
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
  Timer? _inactivityTimer;
  Timer? _sessionCheckTimer;
  bool _isForcingReconnection = false;
  static const Duration _sessionTimeout =
      Duration(minutes: 5); // 5 minutes d'inactivité
  static const Duration _sessionCheckInterval =
      Duration(seconds: 10); // vérification active côté serveur
  // Channel natif pour détecter le verrouillage d'écran
  static const MethodChannel _screenLockChannel =
      MethodChannel('com.coris.mycorislife/screen_lock');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScreenLockListener();
    _resetInactivityTimer();
    _startSessionStatusMonitoring();
    // Après le 1er frame, [views] est en général disponible (iPhone/iPad).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncPreferredOrientationsToDisplay();
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _sessionCheckTimer?.cancel();
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

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_sessionTimeout, () async {
      final token = await AuthService.getToken();
      if (token == null) return;
      _forceReconnection(
        'Session expirée après 5 minutes d\'inactivité',
        logoutReason: 'system_timeout',
      );
    });
  }

  void _startSessionStatusMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(_sessionCheckInterval, (_) async {
      if (_isForcingReconnection) return;
      final token = await AuthService.getToken();
      if (token == null) return;
      final sessionState = await AuthService.checkSessionStatus();
      if (sessionState['authenticated'] == false) {
        final isSuspended = sessionState['suspended'] == true;
        await _forceReconnection(
          isSuspended
              ? 'Votre compte a été suspendu par un administrateur'
              : 'Votre session a été fermée par le système',
          logoutReason:
              isSuspended ? 'account_suspended' : 'system_forced_logout',
        );
      }
    });
  }

  Future<void> _forceReconnection(String reason,
      {String logoutReason = 'system_timeout'}) async {
    if (_isForcingReconnection) return;
    _isForcingReconnection = true;
    debugPrint('🔒 $reason - reconnexion requise');
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        await AuthService.logout(reason: logoutReason);
      }
    } catch (e) {
      debugPrint('⚠️ Impossible d\'enregistrer la déconnexion automatique: $e');
    }

    if (!mounted) {
      _isForcingReconnection = false;
      return;
    }

    // Forcer la reconnexion
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
    // Afficher un message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _navigatorKey.currentContext == null) {
        _isForcingReconnection = false;
        return;
      }

      final messenger =
          ScaffoldMessenger.maybeOf(_navigatorKey.currentContext!);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(reason.toLowerCase().contains('suspend')
              ? 'Votre compte a été suspendu. Reconnexion impossible tant qu’il n’est pas réactivé.'
              : reason.contains('écran') || reason.contains('verrouillé')
                  ? 'Veuillez vous reconnecter pour des raisons de sécurité.'
                  : 'Votre session a expiré. Veuillez vous reconnecter.'),
          backgroundColor: const Color(0xFF002B6B),
          duration: const Duration(seconds: 3),
        ),
      );
      _isForcingReconnection = false;
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
      _inactivityTimer?.cancel();
      debugPrint('⏸️ App mise en arrière-plan à $_pausedTime');
    } else if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan
      debugPrint('🔄 App resumed');
      unawaited(PaymentResumeCoordinator.instance.checkOnAppResume());
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
            'Session expirée (${timeInBackground.inMinutes} minutes)',
            logoutReason: 'system_timeout',
          );
        } else {
          debugPrint(
              '✅ Session toujours valide (${timeInBackground.inMinutes}min ${timeInBackground.inSeconds % 60}s) - pas de reconnexion nécessaire');
          _resetInactivityTimer();
        }

        _pausedTime = null;
      } else {
        _resetInactivityTimer();
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
      // Limiter la mise à l'échelle du texte système entre 0.85× et 1.1×
      // et appliquer une adaptation globale de largeur pour tous les écrans.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clampedScale = mq.textScaler.scale(1.0).clamp(0.85, 1.10);
        final shellChild = child ?? const SizedBox.shrink();
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(clampedScale),
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: mq.viewInsets,
            systemGestureInsets: EdgeInsets.zero,
          ),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _resetInactivityTimer(),
            onPointerMove: (_) => _resetInactivityTimer(),
            child: _AppResponsiveShell(child: shellChild),
          ),
        );
      },
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

class _AppResponsiveShell extends StatelessWidget {
  const _AppResponsiveShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    // Sur tablette et grands écrans, utiliser l'espace disponible sans marges
    if (width >= 600) {
      return SafeArea(
        child: child,
      );
    }

    // Sur petits téléphones, laisser l'application utiliser toute la largeur.
    return child;
  }
}
