import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionRetraiteCollectivePage extends StatelessWidget {
  const DescriptionRetraiteCollectivePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **RETRAITE COMPLÉMENTAIRE COLLECTIVE**

**Offrez à vos salariés une retraite sereine et valorisez votre politique RH.**

---

#### **RETRAITE COMPLÉMENTAIRE COLLECTIVE, pourquoi souscrire ?**

• Pallier la faiblesse des pensions de la CNPS

• Offrir une plus grande espérance de gain à vos salariés lors du départ à la retraite

• Fidéliser et motiver vos collaborateurs grâce à un avantage social attractif

• Renforcer votre attractivité en tant qu'employeur

• Améliorer la retraite de vos salariés par un système de capitalisation basé sur l'effort personnel et celui de l'entreprise

#### **RETRAITE COMPLÉMENTAIRE COLLECTIVE, de quoi s'agit-il ?**

C'est un contrat qui a pour objet de garantir, suite à une capitalisation de l'épargne, le service d'un capital à l'adhérent au moment de son départ à la retraite.

Les droits sont liquidés au moment du départ à la retraite, soit sous la forme d'un capital en un versement unique, soit sous la forme de rentes certaines ou encore sous une forme combinant les deux (02) options précédentes.

Le plan de retraite complémentaire est une couverture en complément de la retraite institutionnelle garantie par la CNPS. C'est un plan par capitalisation basée sur l'effort personnel et celui de l'entreprise.

#### **RETRAITE COMPLÉMENTAIRE COLLECTIVE, comment ça fonctionne ?**

• L'entreprise met en place un plan de retraite complémentaire pour l'ensemble ou une catégorie de ses salariés

• Les cotisations sont versées conjointement par l'employeur et les salariés (répartition définie dans le contrat)

• L'épargne est capitalisée au fil des années avec un taux d'intérêt garanti

• Participation aux bénéfices de CORIS VIE CI en plus du taux garanti

• Au départ à la retraite, le salarié choisit la forme de liquidation :
  - Capital en versement unique
  - Rentes certaines périodiques
  - Combinaison capital + rentes

• Les cotisations versées sont déductibles fiscalement dans les limites légales

#### **RETRAITE COMPLÉMENTAIRE COLLECTIVE, quels sont les avantages ?**

**Pour l'entreprise :**

• **Avantage social attractif** : Outil de motivation et de fidélisation du personnel

• **Déductibilité fiscale** : Les cotisations employeur sont déductibles des charges

• **Image employeur renforcée** : Démontre la préoccupation de l'entreprise pour l'avenir de ses salariés

• **Flexibilité** : Choix des catégories de personnel, du niveau de cotisation, de la répartition employeur/salarié

**Pour les salariés :**

• **Complément de revenus à la retraite** : Capital ou rentes en complément de la pension CNPS

• **Capitalisation garantie** : Épargne sécurisée et productive

• **Avantage fiscal** : Cotisations salariales déductibles du revenu imposable (dans les limites légales)

• **Souplesse de liquidation** : Choix entre capital, rentes ou combinaison

• **Participation aux bénéfices** : Rendement bonifié au-delà du taux garanti

#### **RETRAITE COMPLÉMENTAIRE COLLECTIVE, qui peut souscrire ?**

• Toutes les entreprises privées, quelle que soit leur taille

• Les associations et organisations professionnelles

• Possibilité de couvrir tout le personnel ou des catégories spécifiques (cadres, employés, etc.)

• Particulièrement adapté aux entreprises soucieuses de la qualité de vie de leurs salariés

#### **RETRAITE COMPLÉMENTAIRE COLLECTIVE, comment souscrire ?**

La mise en place se fait en plusieurs étapes :

1. **Diagnostic** : Analyse des besoins de l'entreprise et des salariés

2. **Définition du plan** :
   - Catégories de personnel couvertes
   - Répartition des cotisations (employeur/salarié)
   - Niveau des garanties

3. **Consultation du personnel** : Information et adhésion des salariés

4. **Souscription** : Signature du contrat collectif par l'entreprise

5. **Adhésion** : Adhésion individuelle des salariés éligibles

6. **Mise en place** : Démarrage des cotisations et suivi annuel

**Le choix d'un plan de retraite complémentaire collective trouve sa justesse dans la volonté de l'employeur d'offrir une plus grande espérance de gain et un avantage à ses salariés lors du départ à la retraite.**

---

**Pour plus d'informations et un diagnostic personnalisé, contactez nos experts en prévoyance collective CORIS VIE CI.**
""";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RETRAITE COMPLÉMENTAIRE COLLECTIVE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
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
                    'assets/images/retraite_complementaire_entreprise.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFF5E35B1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 60,
                          color: Color(0xFF5E35B1),
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
