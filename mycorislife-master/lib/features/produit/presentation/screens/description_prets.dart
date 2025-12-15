import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// ============================================
/// PAGE DESCRIPTION PRÊTS SCOLAIRES
/// ============================================
/// Affiche la description complète du produit PRÊTS SCOLAIRES
/// avec toutes les caractéristiques, avantages et modalités
class DescriptionPretsPage extends StatelessWidget {
  const DescriptionPretsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **PRÊTS SCOLAIRES**

**Investissez dans l'avenir de vos enfants avec notre solution de financement éducatif.**

---

#### **Présentation du produit**

**PRÊTS SCOLAIRES** est une solution de financement spécialement conçue pour accompagner les parents dans le financement des études de leurs enfants. Que ce soit pour l'inscription, les frais de scolarité, l'achat de fournitures ou le logement étudiant, nous vous aidons à réaliser les rêves éducatifs de vos enfants.

Ce produit combine un prêt avantageux avec une assurance qui garantit la poursuite des études de vos enfants même en cas d'imprévu.

#### **Caractéristiques principales**

**📚 Financement complet**
- Frais de scolarité et d'inscription
- Fournitures scolaires et matériel pédagogique
- Logement et pension pour étudiants
- Voyages d'études et formations complémentaires

**💰 Conditions avantageuses**
- Taux d'intérêt préférentiels
- Durée de remboursement flexible
- Possibilité de différé de paiement
- Remboursement anticipé sans pénalités

**🛡️ Protection intégrée**
- Assurance décès de l'emprunteur incluse
- Garantie de poursuite des études
- Couverture en cas d'invalidité
- Protection du capital emprunté

#### **Avantages exclusifs**

**🎓 Pour l'éducation**
* **Financement global** : Couvre tous les besoins liés à la scolarité
* **Montants adaptés** : De 500 000 FCFA à 10 000 000 FCFA selon les besoins
* **Tous niveaux** : Du primaire aux études supérieures
* **Formation continue** : Financement des formations professionnelles

**💳 Facilités de paiement**
* **Mensualités réduites** : Adaptées à vos capacités de remboursement
* **Différé possible** : Report de paiement pendant les études
* **Remboursement flexible** : Mensuel, trimestriel ou semestriel
* **Anticipation gratuite** : Remboursez avant la fin sans frais

**🤝 Accompagnement personnalisé**
* **Conseil dédié** : Nos experts vous guident dans votre projet
* **Dossier simplifié** : Procédure rapide et documentation minimale
* **Réponse rapide** : Décision sous 48h maximum
* **Suivi continu** : Accompagnement tout au long du prêt

#### **Public cible**

**PRÊTS SCOLAIRES** s'adresse particulièrement à :

**👨‍👩‍👧‍👦 Parents et tuteurs**
- Parents d'élèves du primaire au supérieur
- Tuteurs légaux d'enfants scolarisés
- Familles avec plusieurs enfants à scolariser
- Parents d'étudiants à l'étranger

**🎯 Besoins éducatifs**
- Frais de scolarité annuels
- Inscription dans des établissements privés
- Études supérieures
- Formations spécialisées
- Voyages d'études

#### **Modalités pratiques**

**💵 Montants et durée**
- **Capital** : De 500 000 FCFA à 10 000 000 FCFA
- **Durée** : De 1 an à 10 ans
- **Différé** : Jusqu'à 24 mois possibles
- **Taux** : Compétitif et préférentiel pour l'éducation

**📋 Conditions d'éligibilité**
- Être âgé de 21 à 60 ans
- Avoir un revenu régulier justifiable
- Fournir les justificatifs de scolarité
- Présenter un projet éducatif cohérent

**📄 Documents requis**
- Pièce d'identité valide
- Justificatif de domicile
- Bulletins de paie ou relevés bancaires
- Certificat de scolarité de l'enfant
- Devis ou factures des frais de scolarité

**💳 Modalités de remboursement**
- **Périodicité** : Mensuelle, trimestrielle ou semestrielle
- **Modes de paiement** : Virement, prélèvement automatique, mobile money
- **Assurance** : Prime d'assurance incluse dans la mensualité
- **Pénalités** : Aucune pour remboursement anticipé

**🏆 Pourquoi choisir PRÊTS SCOLAIRES ?**

L'éducation est l'investissement le plus important que vous puissiez faire pour vos enfants. PRÊTS SCOLAIRES vous permet de leur offrir les meilleures opportunités éducatives sans compromettre votre équilibre financier.

Avec notre solution, vous investissez dans l'avenir de vos enfants tout en bénéficiant d'une protection complète en cas d'imprévu.

*Investissez dans leur avenir, construisez leur réussite.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'PRÊTS SCOLAIRES',
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
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: const Text(
                          'FINANCEMENT ÉTUDES',
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
                        Icons.school,
                        size: 48.0,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'L\'avenir de vos enfants commence ici',
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
                        color: Color(0xFF3B82F6),
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
                        color: Color(0xFF3B82F6),
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
                      'Financez l\'éducation de vos enfants',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002B6B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
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
                          Icon(Icons.info_outline,
                              color: Colors.orange[700], size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ce produit sera bientôt disponible. Restez connecté !',
                              style: TextStyle(
                                fontSize: 15,
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
                          elevation: 0.0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 24),
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
