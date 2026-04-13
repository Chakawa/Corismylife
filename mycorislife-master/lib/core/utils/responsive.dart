import 'package:flutter/material.dart';

/// ============================================================
/// RESPONSIVE UTILITY — Extension sur BuildContext
/// ============================================================
/// Usage:
///   context.sw         → largeur de l'écran
///   context.sh         → hauteur de l'écran
///   context.sp(14)     → taille de texte responsive (base: 390px)
///   context.r(16)      → espacement/taille responsive
///   context.w(5)       → 5% de la largeur de l'écran
///   context.h(3)       → 3% de la hauteur de l'écran
///   context.isTablet   → vrai si largeur >= 600
///   context.isSmall    → vrai si largeur < 360
///   context.hPad       → padding horizontal adaptatif
///   context.cardPad    → padding de carte adaptatif
/// ============================================================
extension Responsive on BuildContext {
  // ─── Dimensions de base ─────────────────────────────────────
  double get sw => MediaQuery.of(this).size.width;
  double get sh => MediaQuery.of(this).size.height;

  // ─── Breakpoints ────────────────────────────────────────────
  /// Petit téléphone (ex : SE, Moto G4) — écran < 360px
  bool get isSmall => sw < 360;

  /// Grand téléphone (ex : Plus, Pro Max) — écran > 430px
  bool get isLargePhone => sw > 430;

  /// Tablette — écran >= 600px
  bool get isTablet => sw >= 600;

  // ─── Mise à l'échelle ────────────────────────────────────────
  /// Taille de texte responsive. Base calibrée sur 390px (iPhone 14).
  /// Clampée entre 80 % et 130 % de la valeur d'origine pour éviter
  /// les extrêmes sur très petits ou très grands écrans.
  double sp(double size) {
    const baseWidth = 390.0;
    final scale = (sw / baseWidth).clamp(0.80, 1.30);
    return size * scale;
  }

  /// Taille / espacement responsive pour marges, icônes, rayons, etc.
  /// Même calcul que sp() mais sans plafond (laisser respirer sur tablette).
  double r(double size) {
    const baseWidth = 390.0;
    final scale = (sw / baseWidth).clamp(0.78, 1.35);
    return size * scale;
  }

  /// Pourcentage de la largeur de l'écran. Ex : context.w(5) → 5 % de sw.
  double w(double percent) => sw * percent / 100;

  /// Pourcentage de la hauteur de l'écran. Ex : context.h(3) → 3 % de sh.
  double h(double percent) => sh * percent / 100;

  // ─── Paddings prêts à l'emploi ───────────────────────────────
  /// Padding horizontal standard adaptatif.
  EdgeInsets get hPad {
    if (isTablet) return EdgeInsets.symmetric(horizontal: w(8));
    if (isSmall) return const EdgeInsets.symmetric(horizontal: 12);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// Padding symétrique horizontal + vertical adaptatif.
  EdgeInsets get screenPad {
    if (isTablet) return EdgeInsets.symmetric(horizontal: w(8), vertical: 20);
    if (isSmall) return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Padding de carte standard adaptatif.
  EdgeInsets get cardPad {
    if (isTablet) return const EdgeInsets.all(20);
    if (isSmall) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  // ─── Helpers affichage ───────────────────────────────────────
  /// Largeur maximale pour centrer le contenu sur tablette.
  double get maxContentWidth => isTablet ? 600 : double.infinity;

  /// Widget centré avec largeur max sur tablette.
  Widget constrained(Widget child) {
    if (!isTablet) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }

  // ─── Grid responsive ─────────────────────────────────────────
  /// Nombre de colonnes pour une grille de produits/cartes.
  int get gridColumns {
    if (isTablet) return 3;
    if (isLargePhone) return 2;
    return 2;
  }

  /// childAspectRatio pour la grille de cartes produit.
  double get cardAspectRatio {
    if (isTablet) return 3.0;
    if (isSmall) return 2.5;
    return 2.8;
  }
}

/// Helper statique (pour les classes sans BuildContext, ex: StatelessWidget global)
class R {
  R._();

  /// Taille de texte responsive à partir du contexte.
  static double sp(BuildContext context, double size) => context.sp(size);

  /// Espacement responsive à partir du contexte.
  static double r(BuildContext context, double size) => context.r(size);
}
