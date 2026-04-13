import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
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
        title: Text(
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
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
                child: Container(
                  height: 220.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(color: const Color(0x26002B6B), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 14.0,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/Produits_assurances-20.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Contenu Markdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: MarkdownBody(
                  data: markdownContent,
                  styleSheet: MarkdownStyleSheet(
                    h3: TextStyle(
                      fontSize: context.sp(26.0),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B6B),
                    ),
                    h4: TextStyle(
                      fontSize: context.sp(20.0),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                    ),
                    p: TextStyle(
                      fontSize: context.sp(16.0),
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                    listBullet: TextStyle(
                      fontSize: context.sp(16.0),
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
                    Text(
                      'Préparez votre retraite dès maintenant',
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
                        onPressed: () {
                          Navigator.pushNamed(
                              context, '/souscription_retraite');
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.elderly, size: 24),
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
