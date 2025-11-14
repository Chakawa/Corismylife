import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

class DescriptionEtudePage extends StatelessWidget {
  const DescriptionEtudePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS ÉTUDE** 🎓

**L'avenir de vos enfants commence aujourd'hui.**

Le contrat **CORIS ÉTUDE** est conçu pour vous aider à garantir un avenir scolaire et professionnel serein à vos enfants. Il s'agit d'un plan d'épargne qui vous permet de constituer, à votre rythme, un capital pour couvrir leurs frais de scolarité (école primaire, secondaire, université) ou les aider à démarrer leur vie d'adulte.

---

#### **Présentation du produit**

**CORIS ÉTUDE** est une solution d'épargne dédiée à l'éducation de vos enfants. Ce contrat d'assurance-vie vous permet de préparer sereinement l'avenir scolaire et professionnel de vos enfants en constituant un capital garanti qui sera disponible au moment opportun.

#### **Caractéristiques principales**

**🎓 Flexibilité maximale**
- Choix libre de la durée de l'épargne
- Montant des cotisations adapté à votre budget
- Possibilité de versements exceptionnels
- Suspension temporaire possible

**🔒 Sécurité garantie**
- Capital garanti, même en cas de décès de l'assuré
- Protection totale de vos versements
- Couverture assurée par des organismes de renom

**📈 Rendement attractif**
- Taux d'intérêt compétitif
- Valorisation annuelle de votre épargne
- Participation aux bénéfices

#### **Avantages exclusifs**

**💰 Avantages financiers**
* **Épargne progressive** : Constituer un capital à votre rythme
* **Capitalisation** : Les intérêts générés sont automatiquement réinvestis
* **Transparence totale** : Suivi en temps réel de l'évolution de votre épargne

**🎯 Avantages pratiques**
* **Utilisation flexible** : Utilisez le capital pour les frais de scolarité, les études supérieures, ou le lancement dans la vie active
* **Transmission facilitée** : Conditions avantageuses pour la transmission du capital à vos enfants
* **Accompagnement personnalisé** : Conseils de nos experts pour optimiser votre épargne

**🛡️ Sécurité et garanties**
* **Capital protégé** : Aucun risque de perte sur le montant de vos cotisations
* **Garantie décès** : Protection de vos proches en cas de décès
* **Stabilité** : Produit adossé à des actifs sécurisés

#### **Public cible**

**CORIS ÉTUDE** s'adresse particulièrement à :

**👥 Profils de parents**
- Parents souhaitant préparer l'avenir scolaire de leurs enfants
- Familles avec plusieurs enfants à scolariser
- Parents soucieux de garantir l'éducation de leurs enfants

**🎯 Objectifs éducatifs**
- Financement des études primaires, secondaires ou supérieures
- Constitution d'un capital pour le lancement dans la vie active
- Création d'une réserve financière pour l'éducation

#### **Modalités pratiques**

**💳 Versements**
- **Montant minimum** : Accessible dès 25 000 FCFA par mois
- **Versements libres** : Adaptés à votre budget
- **Périodicité flexible** : Mensuel, trimestriel, semestriel ou annuel
- **Versements exceptionnels** : Possibilité d'effectuer des versements ponctuels

**📊 Gestion et suivi**
- Interface en ligne dédiée pour le suivi de votre contrat
- Relevés périodiques détaillés
- Conseils personnalisés de nos experts
- Service client dédié et réactif

**🏆 Pourquoi choisir CORIS ÉTUDE ?**

Dans un monde où l'éducation est un investissement essentiel, CORIS ÉTUDE représente la solution idéale pour tous les parents qui souhaitent garantir l'avenir scolaire et professionnel de leurs enfants. Ce produit d'épargne dédié vous offre la possibilité de préparer sereinement l'éducation de vos enfants, avec la garantie d'un accompagnement professionnel de qualité.

*Investir dans CORIS ÉTUDE, c'est investir dans l'avenir de vos enfants.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'CORIS ÉTUDE',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF002B6B), Color(0xFF1e3c72)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF002B6B), Color(0xFF1e3c72)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 48.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE30613),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: const Text(
                        'ÉDUCATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Icon(
                      Icons.school_outlined,
                      size: 48.0,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'L\'avenir de vos enfants commence aujourd\'hui',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: MarkdownBody(
                  data: markdownContent,
                  styleSheet: MarkdownStyleSheet(
                    h3: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B6B),
                      height: 1.3,
                    ),
                    h4: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                      height: 1.4,
                    ),
                    p: const TextStyle(
                      fontSize: 16.0,
                      height: 1.6,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w400,
                    ),
                    strong: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                    ),
                    listBullet: const TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFFE30613),
                      fontWeight: FontWeight.bold,
                    ),
                    horizontalRuleDecoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 2.0,
                        ),
                      ),
                    ),
                    code: const TextStyle(
                      backgroundColor: Colors.transparent,
                      color: Color(0xFFE30613),
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),

            // Call to Action Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Prêt à investir dans l\'éducation de vos enfants ?',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final userRole = await AuthService.getUserRole();
                        if (userRole == 'commercial') {
                          Navigator.pushNamed(
                            context,
                            '/commercial/select_client',
                            arguments: {
                              'productType': 'etude',
                              'simulationData': null,
                            },
                          );
                        } else {
                          Navigator.pushNamed(context, '/souscription_etude');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE30613),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 3.0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'SOUSCRIRE MAINTENANT',
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
