import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
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

""";

    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF002B6B),
          foregroundColor: Colors.white,
          title: Text(
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
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(color: Colors.white24, width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 14.0,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/Produits_assurances-21.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: MarkdownBody(
                      data: markdownContent,
                      styleSheet: MarkdownStyleSheet(
                        h3: TextStyle(
                          fontSize: context.sp(28.0),
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002B6B),
                          height: 1.3,
                        ),
                        h4: TextStyle(
                          fontSize: context.sp(22.0),
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002B6B),
                          height: 1.4,
                        ),
                        p: TextStyle(
                          fontSize: context.sp(16.0),
                          height: 1.6,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w400,
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002B6B),
                        ),
                        listBullet: TextStyle(
                          fontSize: context.sp(16.0),
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
                        code: TextStyle(
                          backgroundColor: Colors.transparent,
                          color: Color(0xFFE30613),
                          fontSize: context.sp(16.0),
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
                      Text(
                        'Prêt à commencer votre épargne ?',
                        style: TextStyle(
                          fontSize: context.sp(20.0),
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002B6B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.r(16.0)),
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
                              Navigator.pushNamed(
                                  context, '/souscription_epargne');
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.savings, size: 24),
                              SizedBox(width: context.r(12)),
                              Text(
                                'SOUSCRIRE MAINTENANT',
                                style: TextStyle(
                                  fontSize: context.sp(17.0),
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
        ));
  }
}
