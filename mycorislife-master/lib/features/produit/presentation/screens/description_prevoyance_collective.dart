import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DescriptionPrevoyanceCollectivePage extends StatelessWidget {
  const DescriptionPrevoyanceCollectivePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String markdownContent = """
### **PRÉVOYANCE SOCIALE COLLECTIVE**

**Protégez vos salariés et leurs familles contre les aléas de la vie.**

---

#### **PRÉVOYANCE SOCIALE COLLECTIVE, pourquoi souscrire ?**

• Garantir la sécurité financière des familles de vos salariés en cas de décès ou PTIA

• Offrir une couverture complète au-delà des prestations légales de la CNPS

• Fidéliser vos collaborateurs grâce à une protection sociale renforcée

• Améliorer votre image d'employeur responsable et attractif

• Compléter la protection sociale avec des garanties optionnelles adaptées

#### **PRÉVOYANCE SOCIALE COLLECTIVE, de quoi s'agit-il ?**

L'objectif de ce contrat est de garantir, en cas de décès ou de PTIA (Perte Totale et Irréversible d'Autonomie) d'un employé de l'entreprise, le versement d'un capital garanti au profit de ses ayants droit, dont le montant est déterminé à l'avance par l'employeur.

Les garanties optionnelles offertes, en plus du décès-PTIA, par le contrat sont :

• Le doublement ou triplement du capital garanti en cas de décès accidentel

• L'Incapacité Temporaire en cas d'Accident (ITA)

• L'Incapacité Partielle Permanente (IPP)

• Les Frais Funéraires (prestations en nature offertes par les pompes funèbres)

• Le remboursement des Frais Médicaux en cas d'accident

#### **PRÉVOYANCE SOCIALE COLLECTIVE, comment ça fonctionne ?**

**Garantie de base : Décès et PTIA**

• L'entreprise détermine le capital garanti pour chaque catégorie de personnel (ex : multiple du salaire annuel)

• En cas de décès ou de PTIA d'un salarié, CORIS VIE CI verse le capital garanti aux bénéficiaires désignés

• Les cotisations peuvent être prises en charge par l'employeur seul ou partagées avec les salariés

**Garanties optionnelles :**

1. **Décès accidentel majoré** : Doublement ou triplement du capital en cas de décès par accident

2. **Incapacité Temporaire en cas d'Accident (ITA)** : Versement d'indemnités journalières en cas d'arrêt de travail suite à un accident

3. **Incapacité Partielle Permanente (IPP)** : Capital proportionnel au taux d'incapacité en cas de séquelles permanentes

4. **Frais Funéraires** : Prestations en nature (cercueil, transport, cérémonie) assurées par des pompes funèbres partenaires

5. **Frais Médicaux accident** : Remboursement des frais médicaux consécutifs à un accident

#### **PRÉVOYANCE SOCIALE COLLECTIVE, quels sont les avantages ?**

**Pour l'entreprise :**

• **Protection sociale renforcée** : Complément essentiel aux prestations légales

• **Outil de fidélisation** : Avantage social très apprécié des salariés

• **Déductibilité fiscale** : Cotisations déductibles des charges de l'entreprise

• **Modularité** : Choix des garanties et du niveau de couverture selon les besoins

• **Gestion simplifiée** : CORIS VIE CI gère l'ensemble du dispositif et les déclarations de sinistres

**Pour les salariés :**

• **Sécurité financière** : Protection de la famille en cas de coup dur

• **Capital garanti connu à l'avance** : Montant défini et communiqué

• **Garanties optionnelles complètes** : Couverture étendue selon le choix de l'entreprise

• **Pas de formalités complexes** : Adhésion automatique pour les salariés éligibles

• **Prestations rapides** : Versement du capital dans les meilleurs délais

• **Couverture accidents majorée** : Protection renforcée en cas de décès ou blessures accidentels

#### **PRÉVOYANCE SOCIALE COLLECTIVE, qui peut souscrire ?**

• Toutes les entreprises privées (TPE, PME, grandes entreprises)

• Les associations et organisations professionnelles

• Possibilité de couvrir tout le personnel ou des catégories spécifiques

• Adaptation du niveau de garantie selon les catégories (cadres, non-cadres, etc.)

#### **PRÉVOYANCE SOCIALE COLLECTIVE, comment souscrire ?**

**Mise en place du contrat :**

1. **Audit des besoins** : Analyse de la population à couvrir et des attentes

2. **Choix des garanties** :
   - Détermination du capital décès/PTIA (ex : 1 à 3 fois le salaire annuel)
   - Sélection des garanties optionnelles souhaitées
   - Définition des catégories de personnel

3. **Tarification** : Calcul des cotisations selon les garanties et la population

4. **Formalisation** :
   - Signature du contrat collectif par l'entreprise
   - Information des salariés sur les garanties
   - Adhésion automatique ou facultative selon les choix

5. **Gestion courante** :
   - Déclaration des mouvements de personnel
   - Paiement des cotisations
   - Déclaration des sinistres

**Cette protection complète permet d'offrir une véritable sécurité à vos salariés et leurs familles, tout en valorisant votre politique de ressources humaines.**

---

**Pour un accompagnement personnalisé dans la mise en place de votre contrat de prévoyance collective, contactez nos experts CORIS VIE CI.**
""";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PRÉVOYANCE SOCIALE COLLECTIVE',
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
            // Image d'en-tête
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/prevoyance_collective.jpg'),
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
