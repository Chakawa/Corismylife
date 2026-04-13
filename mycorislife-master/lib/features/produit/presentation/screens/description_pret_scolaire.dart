import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionPretScolairePage extends StatelessWidget {
  const DescriptionPretScolairePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **PRÊT SCOLAIRE** 🎓📚

**Une solution de financement dédiée pour les études de vos enfants.**

---

#### **PRÊT SCOLAIRE, de quoi s'agit-il ?**

Le PRÊT SCOLAIRE est un produit innovant conçu pour accompagner les familles dans le financement des études de leurs enfants. Il offre une solution flexible et accessible pour couvrir les frais de scolarité, les fournitures, et tous les besoins liés à l'éducation.

#### **Caractéristiques principales**

**🎓 Flexibilité**
- Montants adaptés à vos besoins
- Durées de remboursement personnalisées
- Taux d'intérêt compétitifs

**🔒 Sécurité**
- Processus de souscription simplifié
- Accompagnement personnalisé
- Conditions transparentes

**📈 Avantages**
- Financement rapide
- Couverture complète des frais scolaires
- Solution adaptée à chaque situation familiale

#### **PRÊT SCOLAIRE, qui peut souscrire ?**

Toute personne physique âgée de 18 ans minimum souhaitant financer les études de ses enfants ou personnes à charge.

---

### 🚧 **Produit bientôt disponible**

Ce produit est actuellement en cours de finalisation et sera disponible très prochainement.

Pour plus d'informations ou pour être informé de sa disponibilité, n'hésitez pas à contacter nos équipes.

**📞 Contactez-nous :**
- Téléphone : +225 XX XX XX XX XX
- Email : contact@corislife.ci
- Nos agences sont à votre disposition

*Restez connecté pour ne pas manquer le lancement de ce nouveau produit !*
""";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        foregroundColor: Colors.white,
        title: Text(
          'PRÊT SCOLAIRE',
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
                        child: Text(
                          'ÉDUCATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(12.0),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: context.r(16.0)),
                      const Icon(
                        Icons.school_outlined,
                        size: 48.0,
                        color: Colors.white70,
                      ),
                      SizedBox(height: context.r(16.0)),
                      Text(
                        'Financez l\'avenir éducatif de vos enfants',
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
                        color: Color(0xFFE30613),
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
                        color: Color(0xFFE30613),
                        fontSize: context.sp(16.0),
                      ),
                    ),
                  ),
                ),
              ),

              // Coming Soon Notice
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(24.0),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange[100]!,
                      Colors.orange[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 64.0,
                      color: Colors.orange[700],
                    ),
                    SizedBox(height: context.r(16.0)),
                    Text(
                      'BIENTÔT DISPONIBLE',
                      style: TextStyle(
                        fontSize: context.sp(24.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.r(12.0)),
                    Text(
                      'Ce produit sera prochainement disponible.\nNous travaillons activement à sa mise en place pour mieux vous servir.',
                      style: TextStyle(
                        fontSize: context.sp(16.0),
                        color: Colors.orange[800],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.r(24.0)),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF002B6B),
                                size: 20,
                              ),
                              SizedBox(width: context.r(8)),
                              Text(
                                'Pour plus d\'informations',
                                style: TextStyle(
                                  fontSize: context.sp(16.0),
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF002B6B),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.r(12.0)),
                          Text(
                            'Contactez nos équipes',
                            style: TextStyle(
                              fontSize: context.sp(14.0),
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.r(24.0)),
            ],
          ),
        ),
      ),
    );
  }
}
