import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

class DescriptionSerenitePage extends StatelessWidget {
  const DescriptionSerenitePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS SÉRÉNITÉ PLUS**

**L'épargne-retraite flexible et performante pour construire votre avenir en toute sérénité.**

---

#### **CORIS SÉRÉNITÉ PLUS, pourquoi souscrire ?**

• Vous souhaitez faire face aux aléas de la vie ?

• Comment protéger vos proches contre les conséquences d'une disparition prématurée : léguer votre patrimoine, maintenir le niveau de vie de vos protégés, subvenir aux besoins de la famille après vous, etc. ?

#### **CORIS SÉRÉNITÉ PLUS, de quoi s'agit-il ?**

Ce contrat garantit, en cas de décès ou de Perte Totale et Irréversible d'Autonomie de l'assuré (PTIA), quelle que soit la date de survenance, le versement d'un capital dont le montant est défini à la souscription aux bénéficiaire(s) désigné(s). Ainsi, il permet de garantir durablement la sécurité financière et matérielle du conjoint, des enfants ou des proches en cas d'événements malheureux tout en constituant au fur et à mesure une épargne de prévoyance qui pour vous et libre disposition en cas de nécessité.

#### **CORIS SÉRÉNITÉ PLUS, quelles sont les garanties ?**

**🛡️ À tout moment**
Après au moins deux primes annuelles ou 15% du cumul des primes prévues dans le contrat, le souscripteur peut disposer d'une partie de ses cotisations en rachetant son contrat.

**⚰️ En cas décès ou de Perte Totale et Irréversible d'Autonomie**
Pendant la période de garantie, **CORIS VIE CI** règle le capital défini à la souscription, au(x) bénéficiaire(s) désigné(s) dans le contrat.

#### **Caractéristiques principales**

**🔒 Sécurité absolue**
- Capital 100% garanti à tout moment
- Protection totale de vos versements initiaux
- Couverture assurée par des organismes de renom

**📈 Rendement optimisé**
- Taux d'intérêt compétitif et attractif sur le marché
- Participation aux bénéfices de la compagnie d'assurance
- Revalorisation annuelle de votre capital

**⚡ Flexibilité maximale**
- Versements libres selon vos possibilités
- Possibilité d'effectuer des versements exceptionnels
- Adaptation aux variations de vos revenus
- Suspension temporaire possible sans pénalités

#### **CORIS SÉRÉNITÉ PLUS, quels sont les avantages ?**

• **Une couverture complète** : le décès toutes causes et la Perte Totale et Irréversible d'Autonomie (PTIA)

• **Une tranquillité d'esprit** : sécurité financière assurée avec la garantie d'un capital de survie pour votre famille dès la signature du contrat et le versement de la première prime et les frais de dossier

• **Une formule d'assurance flexible** : libre choix des bénéficiaires, du capital garanti, de la durée et la périodicité de paiement des cotisations

• **Coût connu à l'avance** : le montant de la cotisation est fixé à l'adhésion et n'augmente pas suivant votre âge ou la dégradation de votre état de santé

• **Une fiscalité avantageuse** : en cas de sinistre, le capital réglé n'est assujetti à aucune imposition

#### **CORIS SÉRÉNITÉ PLUS, qui peut souscrire ?**

Toute personne physique âgée d'au moins 18 ans et au plus 65 ans à la souscription.

#### **CORIS SÉRÉNITÉ PLUS, combien ça coûte ?**

La prime est fonction de l'âge de l'assuré à la date de souscription, du capital garanti et de la durée de paiement des cotisations.
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'CORIS SÉRÉNITÉ PLUS',
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
                        'PRODUIT PHARE',
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
                      Icons.security_outlined,
                      size: 48.0,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Votre épargne en toute confiance',
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
                    // Titres principaux
                    h3: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B6B),
                      height: 1.3,
                    ),
                    // Sous-titres
                    h4: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                      height: 1.4,
                    ),
                    // Paragraphes
                    p: const TextStyle(
                      fontSize: 16.0,
                      height: 1.6,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w400,
                    ),
                    // Texte en gras
                    strong: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                    ),
                    // Puces de liste
                    listBullet: const TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFFE30613),
                      fontWeight: FontWeight.bold,
                    ),
                    // Éléments de liste

                    // Séparateur horizontal
                    horizontalRuleDecoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 2.0,
                        ),
                      ),
                    ),
                    // Code inline (pour les emojis)
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
                        // Vérifier le rôle de l'utilisateur pour déterminer le flux de navigation
                        // Si c'est un commercial, il doit passer par la sélection de client
                        // Si c'est un client, il peut accéder directement à la souscription
                        final userRole = await AuthService.getUserRole();
                        if (userRole == 'commercial') {
                          // Pour les commerciaux, rediriger vers la sélection de client
                          Navigator.pushNamed(
                            context,
                            '/commercial/select_client',
                            arguments: {
                              'productType': 'serenite',
                              'simulationData': null, // Pas de simulation, accès direct
                            },
                          );
                        } else {
                          // Pour les clients, navigation directe vers la page de souscription
                          Navigator.pushNamed(context, '/souscription_serenite');
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
                          Icon(Icons.security, size: 24),
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
