import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

class DescriptionEtudePage extends StatelessWidget {
  const DescriptionEtudePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS ÉTUDE** 🎓

**Garantissez l'avenir éducatif de vos enfants avec une solution complète et sécurisée.**

---

#### **CORIS ÉTUDE, pourquoi souscrire ?**

• Grande importance de l'éducation dans la réussite sociale de nos enfants

• Cherté future du coût de l'éducation, combinée à une inflation galopante

• Disparition de la solidarité africaine

• Coûts annexes liés au financement des études par des opérations de crédit si rien n'est planifié

#### **CORIS ÉTUDE, de quoi s'agit-il ?**

Le contrat CORIS ÉTUDE permet aux parents ou tuteurs d'enfants de garantir des rentes certaines, pendant une durée de dix ans ou d'un capital, pour l'éducation des enfants, en cas de vie, mais aussi en cas de décès ou de Perte Totale et Irréversible d'Autonomie pendant la période de cotisation.

#### **CORIS ÉTUDE, comment ça fonctionne ?**

• Les cotisations nettes de frais capitalisées au taux d'intérêt annuel de **3,5%** majorées de la participation aux bénéfices avec une périodicité de paiement des primes : mensuelle, trimestrielle, semestrielle, annuelle, unique

• La durée et le montant de la cotisation sont déterminés par le souscripteur en fonction de l'âge de l'enfant bénéficiaire et de son projet avec une prime minimale de 10 000 F CFA. Les frais de dossier sont de 5 000 F CFA payable une seule fois

• Les garanties du contrat sont :
  ◦ en cas de vie de l'assuré au terme de la période de cotisation, CORIS VIE CI verse une rente certaine annuelle de 10 ans échu, dont le montant est défini dans le contrat pendant une durée de 5 ans
  ◦ en cas de décès ou de Perte Totale et Irréversible d'Autonomie de l'assuré pendant la durée de cotisation :

**En paiement de sinistre CORIS VIE CI verse un capital dont le montant est égal à 50 % de la rente annuelle prévue dans le contrat**

-à partir de la première date d'anniversaire du contrat suivant le sinistre et ce, jusqu'au terme de la période de cotisation, CORIS VIE CI **verse une rente annuelle équivalente à 50 % de la rente annuelle définie à la souscription**

-au terme de la période contractuelle de cotisation et ce, jusqu'au terme du contrat, CORIS VIE CI verse **la rente annuelle payable à terme échu dont le montant a été défini à la souscription**

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

#### **CORIS ÉTUDE, quels sont les avantages ?**

• Un concours financier sûr pour vos enfants pendant leurs études, ou pour leur permettre de s'établir dans la vie professionnelle

• Des garanties complètes pour assurer un avenir radieux à vos enfants quoiqu'il arrive

• Une offre flexible et accessible à tous

#### **CORIS ÉTUDE, qui peut souscrire ?**

Toute personne physique âgée de 18 ans minimum et au plus 65 ans à la date de souscription.

#### **CORIS ÉTUDE, comment souscrire ?**

Pour souscrire, choisissez le montant de la cotisation ou la rente annuelle et renseignez votre proposition d'assurance de même que le questionnaire médical.
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
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    );
  }
}
