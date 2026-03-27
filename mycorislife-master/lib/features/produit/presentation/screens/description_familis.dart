import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mycorislife/services/auth_service.dart';

/// ============================================
/// PAGE DESCRIPTION CORIS FAMILIS
/// ============================================
/// Affiche la description complète du produit CORIS FAMILIS
/// avec toutes les caractéristiques, avantages et modalités
class DescriptionFamilisPage extends StatelessWidget {
  const DescriptionFamilisPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS FAMILIS** 

**L'assurance qui garantit l'avenir de vos enfants en toute circonstance.**

---

#### **Présentation du produit**

**CORIS FAMILIS** est un contrat d'assurance vie spécialement conçu pour protéger l'avenir de vos enfants. Il garantit le versement d'un capital dont le montant est défini à la souscription, en cas de décès ou de Perte Totale et Irréversible d'Autonomie de l'Assuré pendant la période de garantie.

Ce produit vous permet d'assurer l'éducation et l'avenir de vos enfants même si vous n'êtes plus là pour veiller sur eux.

#### **Caractéristiques principales**

**👨‍👩‍👧‍👦 Protection familiale complète**
- Capital garanti pour chaque enfant
- Versement automatique en cas de décès du parent
- Couverture jusqu'à la majorité de l'enfant (25 ans)
- Protection contre la perte totale et irréversible d'autonomie

**💰 Capital adapté**
- Montant librement choisi par le souscripteur
- Versement du capital au bénéficiaire désigné
- Garantie de versement même en cas d'arrêt des cotisations
- Revalorisation possible selon l'évolution

**🛡️ Sécurité maximale**
- Couverture 24h/24 et 7j/7
- Aucune exclusion territoriale
- Pas de délai de carence
- Versement rapide en cas de sinistre

#### **Avantages exclusifs**

**🎓 Pour l'éducation des enfants**
* **Financement études** : Garantit la poursuite de la scolarité de vos enfants
* **Sécurité financière** : Capital disponible pour tous les besoins éducatifs
* **Indépendance** : Vos enfants ne dépendront pas d'autres personnes
* **Continuité** : L'éducation n'est jamais interrompue par manque de moyens

**💚 Tranquillité d'esprit**
* **Protection garantie** : Vos enfants sont protégés quoi qu'il arrive
* **Simplicité** : Un seul contrat pour toute la famille
* **Flexibilité** : Adaptation selon le nombre d'enfants
* **Accessibilité** : Primes abordables adaptées à tous les budgets

**📋 Gestion facilitée**
* **Souscription simple** : Procédure rapide et sans complication
* **Prime fixe** : Montant constant pendant toute la durée
* **Gestion automatique** : Aucune démarche administrative complexe
* **Suivi personnalisé** : Accompagnement dédié tout au long du contrat

#### **Public cible**

**CORIS FAMILIS** s'adresse particulièrement à :

**👥 Parents et tuteurs**
- Parents d'enfants mineurs
- Familles monoparentales
- Parents avec plusieurs enfants à charge
- Tuteurs légaux d'enfants

**🎯 Objectifs de protection**
- Garantir l'éducation des enfants
- Assurer leur avenir financier
- Protéger contre les aléas de la vie
- Préparer sereinement leur avenir

#### **Modalités pratiques**

**💵 Capital et durée**
- **Capital** : De 1 000 000 FCFA à 20 000 000 FCFA par enfant
- **Durée** : Jusqu'aux 18, 21 ou 25 ans de l'enfant
- **Bénéficiaires** : Les enfants désignés au contrat
- **Extension** : Possibilité d'ajouter des enfants en cours de contrat

**📋 Garanties couvertes**
- **Décès toutes causes** : Versement intégral du capital
- **PTIA** : Prise en charge en cas de perte totale et irréversible d'autonomie
- **Double capital** : En cas d'accident (option)
- **Rente éducation** : Versement d'une rente mensuelle (option)

**💳 Primes et paiements**
- **Prime** : Calculée selon l'âge, le capital et le nombre d'enfants
- **Périodicité** : Mensuelle, trimestrielle, semestrielle ou annuelle
- **Modes de paiement** : Virement, prélèvement, mobile money
- **Évolution** : Prime constante pendant toute la durée

**📄 Conditions de souscription**
- Âge du souscripteur : 21 à 60 ans
- Âge des enfants : 0 à 21 ans
- Justificatifs d'identité
- Certificats de naissance des enfants
- Questionnaire médical simplifié

**🏆 Pourquoi choisir CORIS FAMILIS ?**

Être parent, c'est vouloir le meilleur pour ses enfants et s'assurer qu'ils auront toujours les moyens de réaliser leurs rêves, même en votre absence. CORIS FAMILIS vous offre cette garantie en protégeant financièrement l'avenir de vos enfants.

Avec CORIS FAMILIS, vous leur offrez bien plus qu'une assurance : vous leur garantissez un avenir serein et des opportunités préservées.

*Protégez aujourd'hui ce qu'ils ont de plus précieux : leur avenir.*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'CORIS FAMILIS',
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
                          'assets/images/Produits_assurances-22.png',
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
                        color: Color(0xFFEC4899),
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
                        color: Color(0xFFEC4899),
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
                      'Protégez l\'avenir de vos enfants dès maintenant',
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
                                'productType': 'familis',
                                'simulationData':
                                    null, // Pas de simulation, accès direct
                              },
                            );
                          } else {
                            // Pour les clients, navigation directe vers la page de souscription
                            Navigator.pushNamed(
                                context, '/souscription_familis');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
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
                            Icon(Icons.favorite, size: 24),
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
