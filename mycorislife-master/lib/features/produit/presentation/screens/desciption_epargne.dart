import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

class DescriptionEpargnePage extends StatelessWidget {
  const DescriptionEpargnePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS ÉPARGNE BONUS** 

**Constituez votre capital à votre rythme et en toute simplicité.**

Le contrat **CORIS ÉPARGNE BONUS** est un contrat d'assurance-vie qui vous permet de vous constituer un capital pour vos projets futurs. Que ce soit pour un achat important, un voyage ou simplement pour créer un fonds de sécurité, ce produit d'épargne est la solution idéale pour faire fructifier votre argent sans risque.

---

#### **Présentation du produit**

**CORIS ÉPARGNE BONUS** est une solution d'épargne simple et accessible qui vous permet de constituer progressivement un capital garanti. Ce contrat d'assurance-vie vous offre la flexibilité nécessaire pour épargner selon vos moyens tout en bénéficiant d'un rendement attractif et sécurisé.

#### **Caractéristiques principales**

**🔒 Simplicité et sécurité**
- Contrat facile à comprendre et à gérer
- Taux de rendement garanti
- Capital protégé à tout moment
- Aucun risque de perte sur vos cotisations

**📈 Rendement attractif**
- Taux d'intérêt compétitif
- Participation aux bénéfices
- Revalorisation annuelle de votre capital
- Capitalisation des intérêts

**⚡ Accessibilité maximale**
- Cotisations adaptées à votre budget
- Versements libres selon vos possibilités
- Périodicité flexible
- Pas de montant minimum élevé

#### **Avantages exclusifs**

**💰 Avantages financiers**
* **Rendement garanti** : Votre épargne bénéfie d'un taux d'intérêt sécurisé
* **Capitalisation** : Les intérêts générés sont automatiquement réinvestis
* **Transparence totale** : Suivi en temps réel de l'évolution de votre épargne
* **Bonus de fidélité** : Avantages supplémentaires pour les épargnants fidèles

**🎯 Avantages pratiques**
* **Utilisation flexible** : Utilisez le capital pour vos projets personnels
* **Accessibilité** : Produit accessible à tous les budgets
* **Simplicité** : Gestion facile et intuitive de votre contrat
* **Accompagnement** : Conseils personnalisés de nos experts

**🛡️ Sécurité et garanties**
* **Capital protégé** : Aucun risque de perte sur le montant de vos cotisations
* **Garantie décès** : Protection de vos proches en cas de décès
* **Stabilité** : Produit adossé à des actifs sécurisés

#### **Public cible**

**CORIS ÉPARGNE BONUS** s'adresse particulièrement à :

**👥 Profils d'épargnants**
- Personnes souhaitant épargner régulièrement en toute sécurité
- Épargnants débutants recherchant la simplicité
- Personnes avec des budgets variés
- Tous ceux qui souhaitent constituer un capital pour leurs projets

**🎯 Objectifs d'épargne**
- Constitution d'un fonds de sécurité
- Financement de projets personnels (achat, voyage, etc.)
- Création d'une réserve financière
- Préparation d'événements importants

#### **Modalités pratiques**

**💳 Versements**
- **Montant minimum** : Accessible dès 10 000 FCFA par mois
- **Versements libres** : Adaptés à votre budget
- **Périodicité flexible** : Mensuel, trimestriel, semestriel ou annuel
- **Versements exceptionnels** : Possibilité d'effectuer des versements ponctuels

**📊 Gestion et suivi**
- Interface en ligne dédiée pour le suivi de votre contrat
- Relevés périodiques détaillés
- Conseils personnalisés de nos experts
- Service client dédié et réactif

**🏆 Pourquoi choisir CORIS ÉPARGNE BONUS ?**

Dans un monde où l'épargne est essentielle pour réaliser ses projets, CORIS ÉPARGNE BONUS représente la solution idéale pour tous ceux qui souhaitent épargner simplement et efficacement. Ce produit d'épargne accessible vous offre la possibilité de constituer un capital garanti, avec la garantie d'un accompagnement professionnel de qualité.

*Investir dans CORIS ÉPARGNE BONUS, c'est faire le choix d'une épargne simple, sécurisée et performante.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'CORIS ÉPARGNE BONUS',
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
                        'ÉPARGNE',
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
                      Icons.savings_outlined,
                      size: 48.0,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Épargnez simplement et efficacement',
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
                    'Prêt à commencer votre épargne ?',
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
                              'productType': 'epargne',
                              'simulationData': null,
                            },
                          );
                        } else {
                          Navigator.pushNamed(context, '/souscription_epargne');
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
                          Icon(Icons.savings, size: 24),
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
