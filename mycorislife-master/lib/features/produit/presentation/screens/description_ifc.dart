import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionIfcPage extends StatelessWidget {
  const DescriptionIfcPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **INDEMNITÉS DE FIN DE CARRIÈRE (IFC)**

**Anticipez vos obligations légales avec sérénité.**

---

#### **IFC, pourquoi souscrire ?**

• Obligation légale pour toutes les entreprises en Côte d'Ivoire

• Éviter une charge financière importante au moment du départ à la retraite d'un salarié

• Anticiper et provisionner de manière sécurisée les indemnités de fin de carrière

• Bénéficier d'un versement anticipé en cas de décès ou de licenciement économique du salarié

#### **IFC, de quoi s'agit-il ?**

L'IFC est une obligation légale découlant de l'Article n°40 de la Convention Collective Interprofessionnelle du 19 juillet 1977 de la Côte d'Ivoire.

Ce contrat a pour objet d'assurer le règlement, par CORIS VIE CI à l'entreprise contractante, des indemnités de fin de carrière dont elle serait débitrice envers son personnel, en vertu d'obligations légales, ou résultant d'une convention collective des statuts du personnel ou d'un accord d'entreprise.

Il prévoit également de verser par anticipation en cas de décès d'un salarié avant l'âge légal de la retraite ou en cas de licenciement économique, la fraction de l'Indemnité de Fin de Carrière théorique telle que fixée aux conditions particulières.

#### **IFC, comment ça fonctionne ?**

• L'entreprise souscrit un contrat collectif couvrant l'ensemble ou une catégorie de son personnel

• Des cotisations périodiques sont versées pour constituer progressivement les provisions nécessaires

• Le montant des indemnités est calculé selon la Convention Collective (généralement basé sur l'ancienneté et le salaire)

• Au départ à la retraite du salarié, CORIS VIE CI verse l'indemnité directement à l'entreprise qui la reverse au salarié

• En cas de décès avant la retraite ou de licenciement économique, CORIS VIE CI verse par anticipation la fraction de l'IFC théorique

#### **IFC, quels sont les avantages ?**

• **Conformité légale garantie** : Respect de l'Article n°40 de la Convention Collective

• **Lissage de la charge** : Provisions constituées progressivement au lieu d'un paiement unique important

• **Sécurité financière** : Capital garanti disponible au moment voulu

• **Gestion simplifiée** : CORIS VIE CI gère l'ensemble du dispositif

• **Versement anticipé** : Protection en cas de décès ou licenciement économique avant la retraite

• **Déductibilité fiscale** : Les cotisations sont déductibles des charges de l'entreprise

• **Pas de risque de placement** : Capital garanti indépendamment des fluctuations du marché

#### **IFC, qui peut souscrire ?**

• Toutes les entreprises établies en Côte d'Ivoire, quelle que soit leur taille

• Les TPE, PME et grandes entreprises

• Tous les secteurs d'activité (commercial, industriel, services, etc.)

• Particulièrement recommandé pour les entreprises ayant des salariés avec une ancienneté importante

#### **IFC, comment souscrire ?**

La souscription se fait auprès de CORIS VIE CI avec :

• Liste nominative du personnel à couvrir (ou catégories de personnel)

• Informations sur les salaires et anciennetés

• Détermination du niveau de garantie selon la Convention Collective applicable

• Calcul des cotisations périodiques nécessaires

• Signature du contrat collectif

• Mise en place du dispositif de cotisation

**La souscription d'un contrat IFC vous permet de sécuriser vos obligations légales tout en optimisant votre gestion financière.**

---

**Pour plus d'informations, contactez nos conseillers CORIS VIE CI spécialisés en prévoyance collective.**
""";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INDEMNITÉS DE FIN DE CARRIÈRE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
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
                    'assets/images/IFC_indemnite_fin_carriere.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFF0288D1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business_center,
                          size: 60,
                          color: Color(0xFF0288D1),
                        ),
                      );
                    },
                  ),
                ),
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

            // Badge "Bientôt disponible"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 16),

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
