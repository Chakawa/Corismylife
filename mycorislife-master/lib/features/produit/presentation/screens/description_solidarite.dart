import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionSolidaritePage extends StatelessWidget {
  const DescriptionSolidaritePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS SOLIDARITÉ**

**Le contrat qui vous permet de faire face aux événements sociaux de la vie.**

---

#### **Présentation du produit**

**CORIS SOLIDARITÉ** est un contrat d'assurance conçu pour vous accompagner dans les moments difficiles de la vie. Que ce soit pour les obsèques, les frais funéraires ou les dépenses imprévues lors du décès d'un membre de la famille assurée, CORIS SOLIDARITÉ garantit le versement d'un capital forfaitaire destiné à couvrir ces dépenses.

Ce contrat permet de protéger financièrement votre famille en cas de décès, en vous assurant que les frais liés aux funérailles et aux autres obligations ne deviennent pas un fardeau pour vos proches.

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

**💚 Protection complète de la famille**
* **Sécurité financière** : Garantit que les funérailles et obsèques de tous les membres couverts soient dignement organisées
* **Soutien immédiat** : Versement rapide du capital pour faire face aux dépenses urgentes
* **Sérénité d'esprit** : Vous protégez vos proches contre les difficultés financières liées au deuil

**📋 Simplicité et accessibilité**
* **Souscription facile** : Procédure simple et rapide
* **Primes abordables** : Tarifs adaptés à tous les budgets
* **Gestion simplifiée** : Un seul contrat pour toute la famille
* **Sans questionnaire médical** : Pas d'examen médical requis

**🤝 Accompagnement personnalisé**
* **Assistance 24/7** : Service d'assistance disponible en permanence
* **Conseil personnalisé** : Nos experts vous accompagnent dans le choix de vos garanties
* **Suivi régulier** : Révision annuelle de vos besoins
* **Service de qualité** : Équipe dédiée pour vous accompagner

#### **Public cible**

**CORIS SOLIDARITÉ** s'adresse particulièrement à :

**👨‍👩‍👧‍👦 Familles soucieuses de protection**
- Chefs de famille souhaitant protéger leurs proches
- Parents avec enfants à charge
- Personnes avec ascendants à leur charge
- Familles élargies recherchant une couverture globale

**💼 Objectifs de protection**
- Couverture des frais funéraires
- Protection financière de la famille
- Prévention des difficultés financières liées au deuil
- Préservation de la dignité lors des obsèques

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
                      onPressed: () {
                        // Navigation directe vers la page de souscription CORIS SOLIDARITÉ
                        Navigator.pushNamed(
                            context, '/souscription_solidarite');
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
    );
  }
}
