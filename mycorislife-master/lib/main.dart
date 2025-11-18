import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mycorislife/config/routes.dart';
import 'package:mycorislife/config/theme.dart';

void main() {
  runApp(const MyCorisLifeApp());
}

class MyCorisLifeApp extends StatelessWidget {
  const MyCorisLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCorisLife',
      theme: appTheme,
      initialRoute: '/login',
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