import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionRetraitePage extends StatelessWidget {
  const DescriptionRetraitePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS RETRAITE**

**Préparez sereinement votre retraite avec une solution d'épargne dédiée.**

---

#### **CORIS RETRAITE, pourquoi souscrire ?**

• Pallier la chute de revenus à la retraite occasionnée par les différents systèmes de calcul de la pension

• Faire face aux charges quotidiennes pendantes à la retraite qui induisent une détérioration du niveau de vie

• Planifier au mieux ses revenus pour faire face aux aléas de la vie et se garantir de vieux jours paisibles et heureux

#### **CORIS RETRAITE, de quoi s'agit-il ?**

Le contrat **CORIS RETRAITE** vous permet de constituer, par des versements périodiques, un capital payable au moment de votre départ à la retraite. L'épargne constituée est liquidée à l'échéance du contrat, soit sous la forme d'un capital en un versement unique, soit sous la forme de rentes certaines ou encore sous une forme combinant les deux (02) options précédentes.

#### **CORIS RETRAITE, comment ça fonctionne ?**

• Les cotisations nettes de frais capitalisées au taux d'intérêt annuel de **3,5%** majorées de la participation aux bénéfices avec une périodicité de paiement des primes : mensuelle, trimestrielle, semestrielle, annuelle, unique

• La durée et le montant de la cotisation sont déterminés par le souscripteur avec une prime minimale de 10 000 F CFA et des frais de dossier de 5 000 F CFA payable une seule fois

• Le souscripteur peut, à tout moment, effectuer des versements libres, en complément des cotisations programmées

#### **Caractéristiques principales**

🔒 **Sécurité**
- Capital garanti à l'échéance
- Protection contre les aléas de la vie

📈 **Performance**
- Rendement attractif
- Participation aux bénéfices

#### **Avantages exclusifs**

💰 **Avantages financiers**
- Constitution progressive d'un capital retraite
#### **CORIS RETRAITE, quels sont les avantages ?**

• Le maintien de votre niveau de vie

• Le bénéfice d'un capital de survie pour votre famille

• Une offre souple et accessible à tous

• Une sérénité pour vos vieux jours

#### **CORIS RETRAITE, qui peut souscrire ?**

Toute personne physique âgée d'au moins 18 ans à la souscription.

#### **CORIS RETRAITE, comment souscrire ?**

Pour souscrire, choisissez le montant de la cotisation ou le capital minimum et renseignez votre proposition d'assurance.
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image d'en-tête
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF002B6B).withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                child: Image.asset(
                  'assets/images/retraitee.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.elderly,
                          size: 80, color: Color(0xFF002B6B)),
                    );
                  },
                ),
              ),
              // Contenu Markdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: MarkdownBody(
                  data: markdownContent,
                  styleSheet: MarkdownStyleSheet(
                    h3: const TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B6B),
                    ),
                    h4: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                    ),
                    p: TextStyle(
                      fontSize: 16.0,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                    listBullet: const TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFFE30613),
                    ),
                  ),
                ),
              ),
              // Section Souscription
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
                      'Préparez votre retraite dès maintenant',
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
                          Navigator.pushNamed(context, '/souscription_retraite');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002B6B),
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
                            Icon(Icons.elderly, size: 24),
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
