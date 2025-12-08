import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionBonPlanPage extends StatelessWidget {
  const DescriptionBonPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **MON BON PLAN CORIS**

**L'épargne accessible pour le secteur informel - Réalisez vos projets à votre rythme.**

---

#### **Mon Bon Plan Coris, pourquoi souscrire ?**

• Mettre de côté son argent à son rythme et en toute sécurité

• Transformer ses bénéfices quotidiens en un terrain, une maison, une boutique, un atelier, ou développer son fonds de commerce

• Permettre à ses enfants de poursuivre leurs études

#### **Mon Bon Plan Coris, de quoi s'agit-il ?**

Ce contrat permet à tout acteur du secteur informel de se constituer à travers des cotisations par jour, semaine, mois et/ou libres, une épargne qui servira à financer un projet ou disposer d'un capital (revenus complémentaires). **En plus, les proches du client bénéficient d'un soutien de l'assureur en cas décès.**

#### **Mon Bon Plan Coris, comment ça fonctionne ?**

Mon Bon Plan Coris est souscrit pour une durée minimale de deux (02) ans prorogeable annuellement par tacite reconduction et assure pour nos clients :

**📈 Épargne rémunérée**
• Une cotisation avec des intérêts de **3,5% brut** chaque année plus au minimum 2% des bénéfices avant impôts de CORIS VIE

**🛡️ Protection décès**
• Un soutien de **120 000 F CFA** pour les proches du client en cas de décès

**⚡ Flexibilité totale**
• Une suspension, une résiliation ou une possibilité de retirer une partie des fonds sur le contrat **sans pénalité**, à tout moment, après au moins une année de durée en portefeuille

#### **Mon Bon Plan Coris, combien ça coûte ?**

Une cotisation minimale de **500 F CFA par jour**.

#### **Mon Bon Plan Coris, pour qui ?**

Tout acteur du secteur informel :
• Commerçants
• Artisans
• Transporteurs
• Agriculteurs
• Éleveurs
• Etc.
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: const Text(
          'MON BON PLAN CORIS',
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
                'assets/images/bon_plan_coris.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child:
                        Icon(Icons.savings, size: 80, color: Color(0xFF002B6B)),
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
                    'Intéressé par ce produit ?',
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
                          Icon(Icons.savings, size: 24),
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
