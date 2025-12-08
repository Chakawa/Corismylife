import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionHommeClePage extends StatelessWidget {
  const DescriptionHommeClePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **CORIS HOMME CLÉ**

**Protégez votre entreprise contre la perte d'une personne clé.**

---

#### **CORIS HOMME CLÉ, pourquoi souscrire ?**

• Protéger l'entreprise contre les risques financiers liés à la perte d'un dirigeant ou d'un collaborateur clé

• Garantir la continuité des activités et le remboursement des engagements financiers

• Sécuriser les relations avec les banques et institutions financières

• Assurer la pérennité de l'entreprise face aux aléas de la vie

#### **CORIS HOMME CLÉ, de quoi s'agit-il ?**

C'est un contrat d'assurance collective de type temporaire décès constant. Il permet à une entreprise (le souscripteur du contrat) de faire face immédiatement aux engagements financiers auxquels elle peut être tenue vis-à-vis de la Banque ou toute autre institution financière suite au décès ou à la Perte Totale et Irréversible d'Autonomie (PTIA) du chef d'entreprise ou toute autre personne considérée comme « Homme clé » dans l'entreprise.

#### **CORIS HOMME CLÉ, comment ça fonctionne ?**

• L'entreprise souscrit un contrat pour assurer une ou plusieurs personnes clés (dirigeant, cadre stratégique, technicien indispensable, etc.)

• Le capital assuré est déterminé en fonction de l'importance de la personne pour l'entreprise et des engagements financiers à couvrir

• En cas de décès ou de PTIA de la personne assurée, CORIS VIE CI verse le capital garanti directement à l'entreprise bénéficiaire

• L'entreprise peut ainsi faire face à ses obligations financières immédiates et prendre les dispositions nécessaires pour assurer sa continuité

#### **CORIS HOMME CLÉ, quels sont les avantages ?**

• **Protection financière immédiate** : Capital versé rapidement pour faire face aux engagements

• **Sécurisation des emprunts** : Garantie pour les banques et institutions financières

• **Continuité de l'entreprise** : Moyens pour recruter et former un remplaçant

• **Couverture PTIA** : Protection également en cas de Perte Totale et Irréversible d'Autonomie

• **Souplesse** : Capital adapté aux besoins spécifiques de l'entreprise

• **Déductibilité fiscale** : Les primes peuvent être déductibles des charges de l'entreprise

#### **CORIS HOMME CLÉ, qui peut souscrire ?**

• Toutes les entreprises (TPE, PME, grandes entreprises)

• Les associations et organismes professionnels

• Toute structure ayant des personnes clés dont la disparition pourrait impacter significativement l'activité

• Particulièrement adapté aux entreprises ayant des engagements financiers importants (prêts bancaires, lignes de crédit, etc.)

#### **CORIS HOMME CLÉ, comment souscrire ?**

La souscription se fait auprès de CORIS VIE CI avec :

• Identification de la ou des personnes clés à assurer

• Détermination du capital à garantir (basé sur les engagements financiers et l'impact potentiel)

• Évaluation de l'état de santé des personnes à assurer (questionnaire médical, examens si nécessaire)

• Signature du contrat collectif par l'entreprise

• Paiement des primes selon la périodicité choisie

**Pour plus d'informations, contactez nos conseillers CORIS VIE CI.**

---
""";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CORIS HOMME CLÉ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF002B6B),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF002B6B),
                Color(0xFF1e3c72),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image d'en-tête
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/homme_cle.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Badge "Bientôt disponible"
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ce produit sera bientôt disponible. Restez connecté !',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                data: markdownContent,
                styleSheet: MarkdownStyleSheet(
                  h3: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002B6B),
                  ),
                  h4: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e3c72),
                  ),
                  p: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                  listBullet: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF002B6B),
                  ),
                ),
              ),
            ),

            // Bouton de souscription désactivé
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: null, // Bouton désactivé
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Souscrire maintenant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
