import 'package:flutter/material.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mycorislife/core/utils/responsive.dart';

class HomeSouscriptionPage extends StatelessWidget {
  const HomeSouscriptionPage({super.key}); // ✅ super parameter utilisé

  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color blanc = Colors.white;
  static const Color ombrage = Colors.black;

  /// MODIFICATION: Les routes pointent maintenant directement vers les pages de souscription.
  /// 
  /// FLUX:
  /// 1. L'utilisateur clique sur un produit
  /// 2. Pour les commerciaux: redirection vers sélection de client puis souscription
  /// 3. Pour les clients: redirection directe vers la souscription
  /// 
  /// Plus besoin de passer par la page de description.
  final List<Map<String, dynamic>> produits = const [
    {
      'image': 'assets/images/retraitee.png',
      'title': 'CORIS RETRAITE',
      'route': '/souscription_retraite', // Page de souscription directe
    },
    {
      'image': 'assets/images/etudee.png',
      'title': 'CORIS ETUDE',
      'route': '/souscription_etude', // Page de souscription directe
    },
    {
      'image': 'assets/images/serenite.png',
      'title': 'CORIS SERENITE PLUS',
      'route': '/souscription_serenite', // Page de souscription directe
    },
    {
      'image': 'assets/images/solidarite.png',
      'title': 'CORIS SOLIDARITE',
      'route': '/souscription_solidarite', // Page de souscription directe
    },
    // ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
    // {
    //   'image': 'assets/images/emprunteur.png',
    //   'title': 'FLEX EMPRUNTEUR',
    //   'route': '/souscription_flex', // Page de souscription directe
    // },
    {
      'image': 'assets/images/familis.png',
      'title': 'CORIS FAMILIS',
      'route': '/souscription_familis', // Page de souscription directe
    },
    // ❌ PRODUIT DÉSACTIVÉ - PRETS SCOLAIRE
    // {
    //   'image': 'assets/images/prets.png',
    //   'title': 'PRETS SCOLAIRE',
    //   'route': '/souscription_prets_scolaire', // Page de souscription directe
    // },
    {
      'image': 'assets/images/epargnee.png',
      'title': 'CORIS EPARGNE BONUS',
      'route': '/souscription_epargne', // Page de souscription directe
    },
    {
      'image': 'assets/images/coris_assure_prestige.jpg',
      'title': 'CORIS ASSURE PRESTIGE',
      'route': '/souscription_assure_prestige', // Page de souscription directe
    },
    {
      'image': 'assets/images/bon_plan_coris.jpg',
      'title': 'MON BON PLAN CORIS',
      'route': '/souscription_mon_bon_plan', // Page de souscription directe
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(context),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(context),
              SizedBox(height: context.r(16)),
              _buildProductsSection(context),
              SizedBox(height: context.r(24)),
              _buildAssistanceSection(context),
              SizedBox(height: context.r(24)),
            ],
          ),
        ),
      ),
    );
  }

  /// ----------- APPBAR ---------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: bleuCoris,
      elevation: 2,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: context.r(18)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Souscription Produits",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: context.sp(18),
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bleuCoris, Color.fromRGBO(0, 43, 107, 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  /// ----------- HEADER CARD ---------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(context.r(20), context.r(12), context.r(20), context.r(16)),
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        padding: EdgeInsets.all(context.r(16)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bleuCoris,
              bleuCoris.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bleuCoris.withValues(alpha: 0.25),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: ombrage.withValues(alpha: 0.05),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(context.r(10)),
              decoration: BoxDecoration(
                color: blanc.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: blanc.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.diamond_outlined,
                size: context.r(28),
                color: blanc,
              ),
            ),
            SizedBox(height: context.r(12)),
            Text(
              'Solutions d\'assurance sur mesure',
              style: TextStyle(
                color: blanc,
                fontSize: context.sp(15),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: context.r(6)),
            Text(
              'Découvrez nos produits conçus pour répondre à vos besoins\net protéger votre avenir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: blanc.withValues(alpha: 0.9),
                fontSize: context.sp(11),
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ----------- SECTION PRODUITS ---------------
  Widget _buildProductsSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.r(20)),
      constraints: const BoxConstraints(maxWidth: 600),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.gridColumns,
          crossAxisSpacing: context.r(10),
          mainAxisSpacing: context.r(10),
          childAspectRatio: context.cardAspectRatio,
        ),
        itemCount: produits.length,
        itemBuilder: (context, index) {
          final produit = produits[index];
          return InkWell(
            onTap: () async {
              // Vérifier le rôle de l'utilisateur
              final userRole = await AuthService.getUserRole();

              // Si c'est un commercial, rediriger vers la sélection de client
              if (userRole == 'commercial') {
                // Extraire le type de produit depuis la route
                String productType = produit['route']
                    .replaceAll('/souscription_', '')
                    .replaceAll(
                        '/sousription_', ''); // Gérer la typo dans solidarite

                Navigator.pushNamed(
                  context,
                  '/commercial/select_client',
                  arguments: {
                    'productType': productType,
                    'simulationData': null,
                  },
                );
              } else {
                // Si c'est un client, rediriger directement vers la souscription
                Navigator.pushNamed(context, produit['route']);
              }
            },
            child: Container(
              padding: EdgeInsets.all(context.r(10)),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), // ✅ remplacé
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    produit['image'],
                    width: context.r(32),
                    height: context.r(32),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        size: context.r(30),
                        color: bleuCoris,
                      );
                    },
                  ),
                  SizedBox(width: context.r(10)),
                  Expanded(
                    child: Text(
                      produit['title'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeight.w600,
                        color: bleuCoris,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ----------- SECTION ASSISTANCE ---------------
  Widget _buildAssistanceSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.r(20)),
      constraints: const BoxConstraints(maxWidth: 600),
      child: GestureDetector(
        onTap: () async {
          final Uri phoneUri = Uri.parse('tel:0778685858');
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          }
        },
        child: Container(
          padding: EdgeInsets.all(context.r(12)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
                Colors.grey[100]!.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rougeCoris.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: rougeCoris.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.r(9)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      rougeCoris.withValues(alpha: 0.1),
                      rougeCoris.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: rougeCoris.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.support_agent,
                  color: rougeCoris,
                  size: context.r(22),
                ),
              ),
              SizedBox(width: context.r(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Appeler un Conseiller",
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: bleuCoris,
                      ),
                    ),
                    SizedBox(height: context.r(3)),
                    Text(
                      "Nos conseillers sont à votre écoute",
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(context.r(9)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      rougeCoris,
                      rougeCoris.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rougeCoris.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.phone, color: Colors.white, size: context.r(15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
