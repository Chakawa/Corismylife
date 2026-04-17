import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mycorislife/config/routes.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/services/connectivity_service.dart';
import 'package:mycorislife/services/download_notification_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de connectivité
  ConnectivityService().initialize();

  // Initialiser les notifications de téléchargement
  await DownloadNotificationService.initialize();

  final view = WidgetsBinding.instance.platformDispatcher.views.first;
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
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(clampedScale)),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _resetInactivityTimer(),
            onPointerMove: (_) => _resetInactivityTimer(),
            child: _AppResponsiveShell(child: child!),
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

    // Sur tablette et grands écrans, on utilise bien toute la largeur
    // disponible pour éviter l'effet "colonne étroite".
    if (width >= 600) {
      final horizontalPadding = width >= 1024 ? 24.0 : 16.0;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: child,
        ),
      );
    }

    // Sur petits téléphones, on applique une légère réduction globale.
    final scale = (width / 390).clamp(0.90, 1.0);
    if (scale == 1.0) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Transform.scale(
        alignment: Alignment.topCenter,
        scale: scale,
        child: SizedBox(
          width: width / scale,
          child: child,
        ),
      ),
    );
  }
}
