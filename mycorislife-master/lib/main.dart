import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mycorislife/config/routes.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:mycorislife/services/connectivity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

class _MyCorisLifeAppState extends State<MyCorisLifeApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _hasCheckedAuth = false;
  
  // Variables pour gérer le timeout de reconnexion
  DateTime? _pausedTime;
  static const Duration _sessionTimeout = Duration(minutes: 5); // 5 minutes d'inactivité

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'token');
    setState(() {
      _isAuthenticated = token != null && token.isNotEmpty;
      _hasCheckedAuth = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // L'app passe en arrière-plan : enregistrer l'heure
      _pausedTime = DateTime.now();
      debugPrint('⏸️ App mise en arrière-plan à ${_pausedTime}');
    } 
    else if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan
      debugPrint('🔄 App resumed');
      
      if (_pausedTime != null) {
        final timeInBackground = DateTime.now().difference(_pausedTime!);
        debugPrint('⏱️ Temps en arrière-plan: ${timeInBackground.inMinutes} minutes');
        
        // Ne forcer la reconnexion QUE si l'app est restée en arrière-plan
        // pendant plus de 5 minutes
        if (timeInBackground > _sessionTimeout) {
          debugPrint('🔒 Session expirée - reconnexion requise');
          
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
                const SnackBar(
                  content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
                  backgroundColor: Color(0xFF002B6B),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        } else {
          debugPrint('✅ Session toujours valide - pas de reconnexion nécessaire');
        }
        
        // Réinitialiser le temps de pause
        _pausedTime = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedAuth) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'MyCorisLife',
      theme: appTheme,
      initialRoute: _isAuthenticated ? '/client/dashboard' : '/login',
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
