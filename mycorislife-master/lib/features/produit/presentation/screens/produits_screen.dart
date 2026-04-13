import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mycorislife/core/utils/responsive.dart';

class ProduitsPage extends StatelessWidget {
  const ProduitsPage({super.key}); // ✅ super paramètre moderne

  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color blanc = Colors.white;
  static const Color ombrage = Colors.black;

  final List<Map<String, dynamic>> produits = const [
    {
      'image': 'assets/images/retraitee.png',
      'title': 'CORIS RETRAITE',
      'route': '/simulation_retraite',
    },
    {
      'image': 'assets/images/etudee.png',
      'title': 'CORIS ETUDE',
      'route': '/simulation_etude',
    },
    {
      'image': 'assets/images/serenite.png',
      'title': 'CORIS SERENITE PLUS',
      'route': '/simulation_serenite',
    },
    {
      'image': 'assets/images/solidarite.png',
      'title': 'CORIS SOLIDARITE',
      'route': '/simulation_solidarite',
    },
    // ❌ PRODUIT MASQUÉ - PRÊT SCOLAIRE (code conservé)
    // {
    //   'image': 'assets/images/etudee.png',
    //   'title': 'PRÊT SCOLAIRE',
    //   'route': '/description_pret_scolaire',
    // },
    // ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
    // {
    //   'image': 'assets/images/emprunteur.png',
    //   'title': 'FLEX EMPRUNTEUR',
    //   'route': '/simulation_emprunteur',
    // },
    {
      'image': 'assets/images/familis.png',
      'title': 'CORIS FAMILIS',
      'route': '/simulation_familis',
    },
  ];

  /// ----------- HEADER MODERNE ---------------
  Widget _buildModernHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bleuCoris,
            bleuCoris.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.r(16),
            vertical: context.r(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: context.r(24)),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: context.r(8)),
              Icon(Icons.shopping_bag_outlined, color: Colors.white, size: context.r(28)),
              SizedBox(width: context.r(8)),
              Expanded(
                child: Text(
                  "Nos Produits",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ----------- CARD BLEUE ---------------
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.r(16), context.r(16), context.r(16), context.r(16)),
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        padding: EdgeInsets.all(context.r(18)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bleuCoris, Color.fromARGB(255, 0, 60, 140)],
          ),
          borderRadius: BorderRadius.circular(context.r(18)),
          boxShadow: [
            BoxShadow(
              color: bleuCoris.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.r(12)),
              decoration: BoxDecoration(
                color: blanc.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.r(12)),
                border: Border.all(color: blanc.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.calculate_outlined, size: context.r(32), color: blanc),
            ),
            SizedBox(width: context.r(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation Personnalisée',
                    style: TextStyle(
                      color: blanc,
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: context.r(5)),
                  Text(
                    'Découvrez la solution qui vous correspond avec notre outil de simulation avancé',
                    style: TextStyle(
                      color: blanc.withValues(alpha: 0.9),
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w400,
                      height: 1.3,
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

  /// ----------- SECTION PRODUITS ---------------
  Widget _buildProductsSection(BuildContext context) {
    final iconSize = context.r(30);
    final fontSize = context.sp(12.5);
    final pad = context.r(10);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.r(16)),
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
            borderRadius: BorderRadius.circular(context.r(12)),
            onTap: () => Navigator.pushNamed(context, produit['route']),
            child: Container(
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(context.r(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    produit['image'],
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image_not_supported,
                          size: iconSize, color: bleuCoris);
                    },
                  ),
                  SizedBox(width: context.r(8)),
                  Expanded(
                    child: Text(
                      produit['title'],
                      style: TextStyle(
                        fontSize: fontSize,
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
  Widget _buildAssistanceSection() {
    return Builder(builder: (context) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: context.r(16)),
        constraints: const BoxConstraints(maxWidth: 600),
        child: GestureDetector(
          onTap: () async {
            final Uri phoneUri = Uri.parse('tel:0778685858');
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri);
            }
          },
          child: Container(
            padding: EdgeInsets.all(context.r(16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!, Colors.grey[100]!.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(color: rougeCoris.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [
                BoxShadow(color: rougeCoris.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.r(10)),
                  decoration: BoxDecoration(
                    color: rougeCoris.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(color: rougeCoris.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Icon(Icons.support_agent, color: rougeCoris, size: context.r(24)),
                ),
                SizedBox(width: context.r(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Appeler un Conseiller",
                        style: TextStyle(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w600,
                          color: bleuCoris,
                        ),
                      ),
                      SizedBox(height: context.r(3)),
                      Text(
                        "Nos conseillers sont à votre écoute",
                        style: TextStyle(fontSize: context.sp(12), color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(context.r(10)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [rougeCoris, rougeCoris.withValues(alpha: 0.8)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: rougeCoris.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Icon(Icons.phone, color: Colors.white, size: context.r(17)),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildModernHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderCard(context),
                  SizedBox(height: context.r(10)),
                  _buildProductsSection(context),
                  SizedBox(height: context.r(24)),
                  _buildAssistanceSection(),
                  SizedBox(height: context.r(24)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}