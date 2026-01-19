import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

class DescriptionSolidaritePage extends StatelessWidget {
  const DescriptionSolidaritePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS SOLIDARITÉ**

**L'assurance obsèques qui protège toute la famille, sans formalités médicales.**

---

#### **CORIS SOLIDARITÉ, pourquoi souscrire ?**

• Anticiper sur les événements de la vie

• Faire face aux obsèques et funérailles des membres de la famille sans s'endetter, se ruiner ou annuler des projets d'investissements

#### **CORIS SOLIDARITÉ, de quoi s'agit-il ?**

Le contrat **CORIS SOLIDARITÉ** vous permet de faire face aux événements sociaux de la vie que sont les obsèques et les funérailles en garantissant le versement d'un capital forfaitaire destiné à couvrir les frais funéraires exposés lors du décès d'un membre de la famille assurée pendant la durée du contrat.

#### **CORIS SOLIDARITÉ, comment ça fonctionne ?**

L'adhésion est réservée à toute personne physique âgée de moins soixante-quatre (64) ans et le groupe familial de base assuré est composé :

• **du souscripteur** : qui est l'assuré principal qui signe le contrat et paye les primes. Il est le propriétaire du contrat d'assurance

• **d'un (1) conjoint du souscripteur**

• **de six (06) enfants mineurs du souscripteur reconnus, âgés de 12 ans minimum et au plus 21 ans à la date de souscription**

Le souscripteur a la possibilité d'incorporer des adhérents supplémentaires contre une surprime tels que les ascendants directs (père et mère) du souscripteur et/ou du conjoint, les enfants et conjoints.

Le groupe familial assuré est composé au maximum de quatre (04) personnes âgées de plus de soixante-cinq (65) ans et de moins de soixante-dix (70) ans.

**L'adhésion est conclue pour une durée initiale d'une année et se renouvelle par tacite reconduction jusqu'au 70ème anniversaire de l'adhérent.**

Le souscripteur a le choix entre quatre (04) options de capitaux garantis par tête variant de 500 000 à 2 000 000 F CFA.

#### **Caractéristiques principales**

**🛡️ Couverture familiale étendue**
- Couverture de l'assuré principal
- Protection des conjoints
- Assurance des enfants
- Prise en charge des ascendants
- Capital versé pour chaque membre assuré

**💰 Garanties financières**
- Capital forfaitaire garanti en cas de décès
- Montant défini à la souscription
- Versement rapide aux bénéficiaires
- Pas de franchise ni de délai de carence

**🎯 Flexibilité de la couverture**
- Choix du capital assuré
- Adaptation selon la composition familiale
- Prime modulable selon vos besoins
- Périodicité de paiement flexible

#### **Avantages exclusifs**

#### **CORIS SOLIDARITÉ, quels sont les avantages ?**

• une assistance inédite : mise à la disposition, du bénéficiaire désigné, d'un ensemble de prestations par l'intermédiaire des pompes funèbres partenaires ou le paiement du capital

• une offre souple et accessible : adhérer sur une simple déclaration écrite sur l'honneur de la composition de la famille sans formalités médicales

• une cotisation à la portée de tous, à partir de 2 699 F CFA par mois

• Le souscripteur a la possibilité d'incorporer ou de retirer les membres de sa famille conformément aux conditions de souscription

#### **CORIS SOLIDARITÉ, comment souscrire ?**

Pour souscrire, choisissez votre option de capital et renseignez votre proposition d'assurance.

#### **Modalités pratiques**

**📝 Membres couverts**
- **Assuré principal** : La personne qui souscrit le contrat
- **Conjoint(s)** : Époux/épouse ou partenaire reconnu
- **Enfants** : De la naissance jusqu'à 25 ans
- **Ascendants** : Parents et beaux-parents

**💳 Primes et paiements**
- **Capital flexible** : De 500 000 FCFA à 5 000 000 FCFA par personne
- **Prime ajustable** : Selon le nombre de personnes couvertes
- **Périodicité** : Mensuelle, trimestrielle, semestrielle ou annuelle
- **Modes de paiement** : Virement, prélèvement automatique, mobile money

**📊 Garanties et indemnisation**
- Versement immédiat du capital en cas de décès
- Couverture valable 24h/24 et 7j/7
- Aucune exclusion territoriale
- Paiement direct aux bénéficiaires désignés

**🏆 Pourquoi choisir CORIS SOLIDARITÉ ?**

Dans une société où les traditions et les obligations sociales sont importantes, CORIS SOLIDARITÉ représente une solution de prévoyance essentielle. Ce contrat vous permet d'assurer à vos proches des funérailles dignes, tout en les protégeant contre les charges financières que représente la perte d'un être cher.

CORIS SOLIDARITÉ, c'est la tranquillité d'esprit de savoir que votre famille sera protégée, quoi qu'il arrive.

*Protéger sa famille, c'est lui offrir la sécurité et la sérénité pour l'avenir.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'CORIS SOLIDARITÉ',
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
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: const Text(
                          'PROTECTION FAMILLE',
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
                        Icons.family_restroom,
                        size: 48.0,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Protégez vos proches en toute circonstance',
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
                        color: Color(0xFF10B981),
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
                        color: Color(0xFF10B981),
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
                      'Protégez votre famille dès maintenant',
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
                            // Cela permet au commercial de choisir un client existant ou d'en créer un nouveau
                            Navigator.pushNamed(
                              context,
                              '/commercial/select_client',
                              arguments: {
                                'productType': 'solidarite',
                                'simulationData':
                                    null, // Pas de simulation, accès direct
                              },
                            );
                          } else {
                            // Pour les clients, navigation directe vers la page de souscription
                            Navigator.pushNamed(
                              context,
                              '/souscription_solidarite',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
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
                            Icon(Icons.shield_outlined, size: 24),
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
