import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionAssurePrestigePage extends StatelessWidget {
  const DescriptionAssurePrestigePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS ASSURE PRESTIGE**

**Une solution d'épargne flexible pour concrétiser vos projets et bâtir votre avenir.**

---

#### **Objectif**

Ce contrat permet de se constituer à travers des versements libres, une épargne qui servira à financer un projet ou disposer d'un capital (revenus complémentaires). Au terme, l'assuré perçoit un capital revalorisé d'année en année grâce au taux d'intérêts et à la participation aux bénéfices distribués par Coris Assurances Vie.

#### **Fonctionnement**

**Versements libres et flexibles**
À la souscription, l'assuré choisit le montant de son premier versement. Par la suite, il peut faire des versements complémentaires à son rythme tout au long de la durée du contrat.

**Capitalisation attractive**
L'épargne est constituée par les cotisations nettes de frais, capitalisée au taux d'intérêt technique annuel garanti de **3,5%** et augmentées des participations aux bénéfices techniques et financiers de Coris Assurances Vie.

**Disponibilité de l'épargne**
En cas de coup dur, l'épargne constituée reste accessible à tout moment selon les conditions prévues au contrat.

**Au terme du contrat**
Au terme du contrat ou au moment du départ à la retraite, l'assuré perçoit l'épargne constituée sous forme de capital ou de rentes.

**Protection en cas de décès**
En cas de décès avant le terme du contrat, l'épargne constituée au jour du décès est versée au(x) bénéficiaires désignés.

#### **Avantages**

**💰 Liberté**
L'assuré choisit librement le montant, la durée, et la périodicité de ses primes.

**⚡ Disponibilité**
En cas de coup dur, l'épargne reste disponible sous certaines conditions.

**📈 Rentabilité**
L'épargne constituée bénéficie des intérêts et participations aux bénéfices distribués.

**🎯 Transmission**
Grâce au cadre juridique et fiscal de l'assurance-vie, le contrat CORIS ASSUR PRESTIGE permet de léguer un capital exonéré de droits de successions à la (aux) personne(s) de son choix.
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: Text(
          'CORIS ASSURE PRESTIGE',
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 48.0),
            child: Column(
              children: [
                // Image d'en-tête réduite
                Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/coris_assure_prestige.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF002B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.diamond,
                            size: 60,
                            color: Color(0xFF002B6B),
                          ),
                        );
                      },
                    ),
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
                      'Intéressé par ce produit prestige ?',
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
                          final args = ModalRoute.of(context)?.settings.arguments
                              as Map<String, dynamic>?;
                          final bool isCommercial = args?['isCommercial'] == true;

                          if (isCommercial) {
                            Navigator.pushNamed(
                              context,
                              '/commercial/select_client',
                              arguments: {
                                'isCommercial': true,
                                'productType': 'assure_prestige'
                              },
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/souscription_assure_prestige',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002B6B),
                          disabledBackgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 2.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, size: 24),
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
            ],            ),          ),
        ),
      ),
    );
  }
}
