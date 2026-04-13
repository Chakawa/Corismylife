import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// ============================================
/// PAGE DESCRIPTION FLEX EMPRUNTEUR
/// ============================================
/// Affiche la description complète du produit FLEX EMPRUNTEUR
/// avec toutes les caractéristiques, avantages et modalités
class DescriptionFlexPage extends StatelessWidget {
  const DescriptionFlexPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **FLEX EMPRUNTEUR**

**L'assurance qui protège votre prêt et votre famille en cas d'imprévu.**

---

#### **Présentation du produit**

**FLEX EMPRUNTEUR** est une assurance emprunteur innovante qui garantit le remboursement de votre crédit en cas de décès ou d'invalidité. Conçue pour vous offrir une tranquillité d'esprit totale, cette assurance protège à la fois votre famille et votre patrimoine contre les aléas de la vie.

Que vous ayez contracté un prêt immobilier, un crédit automobile ou un prêt à la consommation, FLEX EMPRUNTEUR s'adapte à vos besoins et vous accompagne tout au long de la durée de votre emprunt.

#### **Caractéristiques principales**

**🛡️ Protection complète**
- Garantie décès toutes causes
- Couverture invalidité permanente totale (IPT)
- Prise en charge de l'incapacité temporaire de travail (ITT)
- Protection en cas de perte totale et irréversible d'autonomie (PTIA)

**💼 Flexibilité adaptée**
- Montant ajustable selon votre prêt
- Durée correspondant à votre crédit
- Possibilité de couverture simple ou double
- Prime modulable selon vos besoins

**⚡ Garanties renforcées**
- Versement immédiat en cas de sinistre
- Prise en charge directe auprès de l'organisme prêteur
- Aucune franchise sur les garanties principales
- Couverture mondiale 24h/24

#### **Avantages exclusifs**

**💰 Protection financière**
* **Sécurité du prêt** : Votre crédit est remboursé en cas de décès ou d'invalidité
* **Protection de la famille** : Vos proches ne supportent pas le poids de vos dettes
* **Préservation du patrimoine** : Vos biens ne sont pas saisis pour rembourser le prêt
* **Sérénité totale** : Empruntez l'esprit tranquille

**🎯 Avantages pratiques**
* **Souscription simple** : Procédure rapide et sans complication
* **Tarifs compétitifs** : Prime adaptée à votre profil et votre emprunt
* **Gestion facilitée** : Un seul contrat pour tout gérer
* **Service dédié** : Équipe spécialisée pour vous accompagner

**🏥 Couverture santé**
* **ITT couverte** : Prise en charge en cas d'arrêt de travail
* **IPT garantie** : Remboursement si invalidité permanente
* **PTIA incluse** : Protection maximale en cas de perte d'autonomie
* **Pas de franchise** : Indemnisation dès le premier jour

#### **Public cible**

**FLEX EMPRUNTEUR** s'adresse particulièrement à :

**👥 Profils d'emprunteurs**
- Personnes ayant contracté un prêt immobilier
- Emprunteurs pour crédit automobile
- Souscripteurs de prêts à la consommation
- Professionnels ayant des crédits professionnels

**🎯 Objectifs de protection**
- Sécuriser le remboursement de son crédit
- Protéger sa famille contre l'endettement
- Préserver son patrimoine en cas d'accident
- Emprunter en toute sérénité

#### **Modalités pratiques**

**💳 Couverture**
- **Capital assuré** : Égal au montant de votre prêt
- **Durée** : Identique à celle de votre crédit
- **Type de couverture** : Individuelle ou conjointe
- **Bénéficiaire** : L'organisme prêteur directement

**📊 Garanties incluses**
- **Décès** : Remboursement total du capital restant dû
- **PTIA** : Prise en charge à 100% en cas de perte d'autonomie
- **IPT** : Indemnisation en cas d'invalidité permanente (taux > 66%)
- **ITT** : Versement d'indemnités journalières en cas d'arrêt de travail

**💳 Primes et paiements**
- **Prime calculée** : Selon l'âge, le capital et la durée
- **Paiement** : Mensuel, trimestriel, semestriel ou annuel
- **Évolution** : Prime constante ou dégressive selon l'option choisie
- **Modes de règlement** : Virement, prélèvement, mobile money

**🏆 Pourquoi choisir FLEX EMPRUNTEUR ?**

Emprunter est un engagement important qui ne doit pas devenir un fardeau pour vos proches en cas d'imprévu. FLEX EMPRUNTEUR vous garantit que votre crédit sera remboursé quoi qu'il arrive, vous permettant d'emprunter en toute confiance et de protéger ceux que vous aimez.

Avec FLEX EMPRUNTEUR, transformez votre emprunt en un acte responsable et protecteur pour votre famille.

*Empruntez sereinement, nous vous protégeons.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: Text(
          'FLEX EMPRUNTEUR',
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
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: Text(
                        'ASSURANCE CRÉDIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.sp(12.0),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: context.r(16.0)),
                    Icon(
                      Icons.account_balance,
                      size: 48.0,
                      color: Colors.white70,
                    ),
                    SizedBox(height: context.r(16.0)),
                    Text(
                      'Protégez votre crédit et votre famille',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.sp(18.0),
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
                      color: Color(0xFFF59E0B),
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
                      color: Color(0xFFF59E0B),
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
                    'Protégez votre crédit dès maintenant',
                    style: TextStyle(
                      fontSize: context.sp(20.0),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.r(16.0)),
                  // Badge "Bientôt disponible"
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 28),
                        SizedBox(width: context.r(12)),
                        Expanded(
                          child: Text(
                            'Ce produit sera bientôt disponible. Restez connecté !',
                            style: TextStyle(
                              fontSize: context.sp(15),
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null, // Bouton désactivé
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        disabledBackgroundColor: Colors.grey[400],
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
                          Icon(Icons.shield, size: 24),
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
      ),
    );
  }
}
