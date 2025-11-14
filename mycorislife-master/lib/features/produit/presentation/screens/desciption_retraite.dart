import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

class DescriptionRetraitePage extends StatelessWidget {
  const DescriptionRetraitePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS RETRAITE** 

**Préparez votre retraite et profitez pleinement de votre vie.**

Le contrat **CORIS RETRAITE** est un plan d'épargne retraite qui vous permet de vous constituer un capital solide pour votre avenir. Que vous soyez salarié, travailleur indépendant ou entrepreneur, ce produit vous offre la liberté financière de vivre la retraite que vous avez toujours souhaitée.

---

#### **Présentation du produit**

**CORIS RETRAITE** est une solution d'épargne dédiée à la préparation de votre retraite. Ce contrat d'assurance-vie vous permet de constituer progressivement un capital garanti qui sera disponible au moment de votre départ en retraite, vous offrant ainsi la tranquillité d'esprit et la liberté financière nécessaires pour profiter pleinement de cette nouvelle étape de votre vie.

#### **Caractéristiques principales**

**🔒 Sécurité absolue**
- Capital 100% garanti
- Protection totale de vos versements
- Couverture assurée par des organismes de renom
- Aucun risque de perte sur vos cotisations

**📈 Rendement optimisé**
- Taux d'intérêt compétitif et attractif
- Participation aux bénéfices de la compagnie d'assurance
- Revalorisation annuelle de votre capital
- Capitalisation des intérêts

**⚡ Flexibilité maximale**
- Versements libres selon vos possibilités
- Possibilité d'effectuer des versements exceptionnels
- Adaptation aux variations de vos revenus
- Suspension temporaire possible sans pénalités

#### **Avantages exclusifs**

**💰 Avantages financiers**
* **Rendement supérieur** : Votre épargne bénéfie d'un taux d'intérêt particulièrement avantageux
* **Capitalisation** : Les intérêts générés sont automatiquement réinvestis pour maximiser votre capital
* **Transparence totale** : Suivi en temps réel de l'évolution de votre épargne

**🎯 Avantages fiscaux**
* **Optimisation fiscale** : Bénéficiez d'avantages fiscaux selon la législation en vigueur
* **Défiscalisation** : Possibilité de déduction des versements dans certaines conditions
* **Transmission facilitée** : Conditions avantageuses pour la transmission de votre patrimoine

**🛡️ Sécurité et garanties**
* **Capital protégé** : Aucun risque de perte sur le montant de vos cotisations
* **Garantie décès** : Protection de vos proches en cas de décès
* **Stabilité** : Produit adossé à des actifs sécurisés et diversifiés

#### **Public cible**

**CORIS RETRAITE** s'adresse particulièrement à :

**👥 Profils d'épargnants**
- Actifs souhaitant préparer leur retraite de manière progressive
- Travailleurs indépendants et entrepreneurs
- Personnes avec des revenus variables recherchant la flexibilité
- Épargnants prudents privilégiant la sécurité du capital

**🎯 Objectifs patrimoniaux**
- Constitution d'un complément de retraite substantiel
- Maintien du niveau de vie après la cessation d'activité
- Réalisation de projets personnels à la retraite
- Optimisation de la transmission patrimoniale

#### **Modalités pratiques**

**💳 Versements**
- **Montant minimum** : Accessible dès 25 000 FCFA par mois
- **Versements libres** : Adaptés à votre budget et à vos capacités
- **Périodicité flexible** : Mensuel, trimestriel, semestriel ou annuel
- **Versements exceptionnels** : Possibilité d'effectuer des versements ponctuels importants

**📊 Gestion et suivi**
- Interface en ligne dédiée pour le suivi de votre contrat
- Relevés périodiques détaillés
- Conseils personnalisés de nos experts
- Service client dédié et réactif

**🏆 Pourquoi choisir CORIS RETRAITE ?**

Dans un contexte où la préparation de la retraite est essentielle, CORIS RETRAITE représente la solution idéale pour tous ceux qui souhaitent garantir leur avenir financier. Ce produit d'épargne dédié vous offre la possibilité de préparer sereinement votre retraite, avec la garantie d'un accompagnement professionnel de qualité.

*Investir dans CORIS RETRAITE, c'est investir dans votre avenir et votre tranquillité d'esprit.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'CORIS RETRAITE',
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
                        'RETRAITE',
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
                      Icons.work_outline,
                      size: 48.0,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Préparez votre retraite en toute sérénité',
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
                    'Prêt à préparer votre retraite ?',
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
                              'productType': 'retraite',
                              'simulationData': null,
                            },
                          );
                        } else {
                          Navigator.pushNamed(context, '/souscription_retraite');
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
                          Icon(Icons.work, size: 24),
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
