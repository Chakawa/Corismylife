import 'package:flutter/material.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_retraite.dart';
import 'package:mycorislife/services/produit_sync_service.dart';
import 'package:mycorislife/models/tarif_produit_model.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/services/connectivity_service.dart';
import 'package:mycorislife/services/local_data_service.dart';

class CorisRetraiteScreen extends StatefulWidget {
  const CorisRetraiteScreen({super.key});

  @override
  State<CorisRetraiteScreen> createState() => _CorisRetraiteScreenState();
}

class _CorisRetraiteScreenState extends State<CorisRetraiteScreen> {
  final _dureeController = TextEditingController();
  final _valeurController = TextEditingController();

  String selectedOption = 'capital';
  String selectedPeriodicite = 'annuel';
  double? result;
  String resultLabel = '';
  bool isLoading = false;
  bool _useLocalData = false;

  // Service pour synchroniser avec la base de données
  final ProduitSyncService _produitSyncService = ProduitSyncService();

  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color vertCoris = Color(0xFF00A650);
  static const Color grisClairBg = Color(0xFFF8FAFB);

  // Primes minimales par périodicité
  final Map<String, int> minPrimes = {
    'mensuel': 10000,
    'trimestriel': 30000,
    'semestriel': 60000,
    'annuel': 120000,
  };

  // Tableau tarifaire (à insérer manuellement)
  final Map<int, Map<String, double>> premiumValues = {
    5: {
      'mensuel': 17385.55245,
      'trimestriel': 51343.16466,
      'semestriel': 101813.14352,
      'annuel': 201890.00380
    },
    6: {
      'mensuel': 14238.32819,
      'trimestriel': 41978.94598,
      'semestriel': 83298.26868,
      'annuel': 165175.99987
    },
    7: {
      'mensuel': 11992.86563,
      'trimestriel': 35424.10172,
      'semestriel': 70323.54417,
      'annuel': 139011.72433
    },
    8: {
      'mensuel': 10311.00079,
      'trimestriel': 30413.27008,
      'semestriel': 60397.20310,
      'annuel': 119431.37050
    },
    9: {
      'mensuel': 9004.86435,
      'trimestriel': 26529.29040,
      'semestriel': 52698.35344,
      'annuel': 104235.51451
    },
    10: {
      'mensuel': 7563.64759,
      'trimestriel': 22312.00493,
      'semestriel': 44228.31611,
      'annuel': 87500.89678
    },
    11: {
      'mensuel': 6754.38423,
      'trimestriel': 19903.12711,
      'semestriel': 39467.22927,
      'annuel': 78095.31588
    },
    12: {
      'mensuel': 6081.40012,
      'trimestriel': 17902.64892,
      'semestriel': 35510.77460,
      'annuel': 70276.78179
    },
    13: {
      'mensuel': 5513.24280,
      'trimestriel': 16246.02984,
      'semestriel': 32232.54909,
      'annuel': 63796.71982
    },
    14: {
      'mensuel': 5027.44598,
      'trimestriel': 14800.85821,
      'semestriel': 29371.52796,
      'annuel': 58140.14424
    },
    15: {
      'mensuel': 4607.53413,
      'trimestriel': 13553.04544,
      'semestriel': 26900.24228,
      'annuel': 53253.15960
    },
    16: {
      'mensuel': 4234.30376,
      'trimestriel': 12485.18488,
      'semestriel': 24745.32809,
      'annuel': 48991.07389
    },
    17: {
      'mensuel': 3906.76267,
      'trimestriel': 11526.84218,
      'semestriel': 22850.74160,
      'annuel': 45243.31561
    },
    18: {
      'mensuel': 3617.16662,
      'trimestriel': 10678.49023,
      'semestriel': 21172.93236,
      'annuel': 41923.93536
    },
    19: {
      'mensuel': 3359.42700,
      'trimestriel': 9936.57609,
      'semestriel': 19705.05837,
      'annuel': 38965.11313
    },
    20: {
      'mensuel': 3128.69085,
      'trimestriel': 9257.85305,
      'semestriel': 18361.84334,
      'annuel': 36312.61717
    },
    21: {
      'mensuel': 2921.04241,
      'trimestriel': 8646.57304,
      'semestriel': 17151.75590,
      'annuel': 33922.56273
    },
    22: {
      'mensuel': 2733.28735,
      'trimestriel': 8103.74654,
      'semestriel': 16056.55640,
      'annuel': 31759.05634
    },
    23: {
      'mensuel': 2562.79385,
      'trimestriel': 7600.25802,
      'semestriel': 15061.18718,
      'annuel': 29792.45569
    },
    24: {
      'mensuel': 2407.37402,
      'trimestriel': 7141.05329,
      'semestriel': 14153.10752,
      'annuel': 27998.06519
    },
    25: {
      'mensuel': 2265.19402,
      'trimestriel': 6728.62923,
      'semestriel': 13337.28607,
      'annuel': 26385.73330
    },
    26: {
      'mensuel': 2134.70522,
      'trimestriel': 6342.11478,
      'semestriel': 12572.57942,
      'annuel': 24874.28638
    },
    27: {
      'mensuel': 2014.59084,
      'trimestriel': 5986.21186,
      'semestriel': 11868.28274,
      'annuel': 23482.08901
    },
    28: {
      'mensuel': 1903.72406,
      'trimestriel': 5663.78043,
      'semestriel': 11217.87997,
      'annuel': 22196.29606
    },
    29: {
      'mensuel': 1801.13496,
      'trimestriel': 5359.17421,
      'semestriel': 10615.75618,
      'annuel': 21005.83652
    },
    30: {
      'mensuel': 1705.98414,
      'trimestriel': 5076.59191,
      'semestriel': 10057.04697,
      'annuel': 19901.11723
    },
    31: {
      'mensuel': 1617.54143,
      'trimestriel': 4818.83139,
      'semestriel': 9547.28012,
      'annuel': 18873.78411
    },
    32: {
      'mensuel': 1535.16869,
      'trimestriel': 4573.76738,
      'semestriel': 9062.56656,
      'annuel': 17916.52823
    },
    33: {
      'mensuel': 1458.30574,
      'trimestriel': 4345.06312,
      'semestriel': 8610.13211,
      'annuel': 17022.92723
    },
    34: {
      'mensuel': 1386.45880,
      'trimestriel': 4135.30013,
      'semestriel': 8187.09854,
      'annuel': 16187.31468
    },
    35: {
      'mensuel': 1319.19093,
      'trimestriel': 3934.84048,
      'semestriel': 7790.91726,
      'annuel': 15404.67203
    },
    36: {
      'mensuel': 1256.11406,
      'trimestriel': 3746.85383,
      'semestriel': 7419.32336,
      'annuel': 14670.53842
    },
    37: {
      'mensuel': 1196.88235,
      'trimestriel': 3573.66135,
      'semestriel': 7076.89185,
      'annuel': 13993.93933
    },
    38: {
      'mensuel': 1141.18658,
      'trimestriel': 3407.44859,
      'semestriel': 6748.23829,
      'annuel': 13344.54196
    },
    39: {
      'mensuel': 1088.74944,
      'trimestriel': 3250.95304,
      'semestriel': 6438.75443,
      'annuel': 12732.97936
    },
    40: {
      'mensuel': 1039.32148,
      'trimestriel': 3106.23686,
      'semestriel': 6146.97839,
      'annuel': 12156.37022
    },
    41: {
      'mensuel': 992.67774,
      'trimestriel': 2966.86268,
      'semestriel': 5871.59109,
      'annuel': 11612.11433
    },
    42: {
      'mensuel': 948.61478,
      'trimestriel': 2835.19736,
      'semestriel': 5611.39921,
      'annuel': 11097.85903
    },
    43: {
      'mensuel': 906.94817,
      'trimestriel': 2713.06304,
      'semestriel': 5369.98847,
      'annuel': 10611.47043
    },
    44: {
      'mensuel': 867.51031,
      'trimestriel': 2595.08784,
      'semestriel': 5136.79219,
      'annuel': 10151.00851
    },
    45: {
      'mensuel': 830.14858,
      'trimestriel': 2483.32319,
      'semestriel': 4915.84582,
      'annuel': 9714.70556
    },
    46: {
      'mensuel': 794.72366,
      'trimestriel': 2377.35238,
      'semestriel': 4706.32965,
      'annuel': 9300.94747
    },
    47: {
      'mensuel': 761.10815,
      'trimestriel': 2276.79425,
      'semestriel': 4507.49375,
      'annuel': 8908.25736
    },
    48: {
      'mensuel': 729.18528,
      'trimestriel': 2181.29955,
      'semestriel': 4318.65075,
      'annuel': 8535.28130
    },
    49: {
      'mensuel': 698.84787,
      'trimestriel': 2090.54761,
      'semestriel': 4142.58435,
      'annuel': 8187.50292
    },
    50: {
      'mensuel': 669.99733,
      'trimestriel': 2004.24351,
      'semestriel': 3971.71793,
      'annuel': 7849.99700
    },
  };

  final Map<String, double> capitalValues = {
    'mensuel': 10000.00000,
    'trimestriel': 30000.00000,
    'semestriel': 60000.00000,
    'annuel': 120000.00000,
  };
  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  void _formatMontantInput() {
    final text = _valeurController.text.replaceAll(' ', '');
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null) {
        _valeurController.text = _formatNumber(value);
        _valeurController.selection = TextSelection.fromPosition(
          TextPosition(offset: _valeurController.text.length),
        );
      }
    }
  }

  void _resetSimulation() {
    setState(() {
      _dureeController.clear();
      _valeurController.clear();
      selectedOption = 'capital';
      selectedPeriodicite = 'annuel';
      result = null;
      resultLabel = '';
    });
  }

  void _showProfessionalDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                        backgroundColor.withAlpha(25), Colors.white),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002B6B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002B6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Compris',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showError(String message) {
    _showProfessionalDialog(
      title: 'Paramètres invalides',
      message: message,
      icon: Icons.warning_rounded,
      iconColor: Colors.orange,
      backgroundColor: Colors.orange,
    );
  }

  bool _validateInputs() {
    if (_dureeController.text.trim().isEmpty) {
      _showProfessionalDialog(
        title: 'Champ obligatoire',
        message:
            'Veuillez renseigner la durée du contrat pour continuer la simulation.',
        icon: Icons.edit_outlined,
        iconColor: Colors.orange,
        backgroundColor: Colors.orange,
      );
      return false;
    }

    if (_valeurController.text.trim().isEmpty) {
      String fieldName =
          selectedOption == 'capital' ? 'capital souhaité' : 'prime à verser';
      _showProfessionalDialog(
        title: 'Champ obligatoire',
        message:
            'Veuillez renseigner le $fieldName pour continuer la simulation.',
        icon: Icons.edit_outlined,
        iconColor: Colors.orange,
        backgroundColor: Colors.orange,
      );
      return false;
    }

    return true;
  }

  String get currentHint {
    if (selectedOption == 'capital') {
      return 'Montant en FCFA';
    } else {
      final minPrime = minPrimes[selectedPeriodicite]!;
      return 'Minimum ${_formatNumber(minPrime.toDouble())} FCFA';
    }
  }

  Future<double> calculatePremium(
      int duration, String periodicity, double desiredCapital) async {
    print(
        '\n╔═══════════════════════════════════════════════════════════════╗');
    print('║ 🧮 [RETRAITE] CALCUL PRIME DÉMARRÉ                           ║');
    print('╚═══════════════════════════════════════════════════════════════╝');
    print('   📊 Paramètres:');
    print('      - Durée: $duration ans');
    print('      - Périodicité: $periodicity');
    print(
        '      - Capital souhaité: ${desiredCapital.toStringAsFixed(0)} FCFA');
    print(
        '   🌐 Mode: ${_useLocalData ? "HORS LIGNE (données locales)" : "EN LIGNE"}');

    if (duration < 5 || duration > 50) {
      print('   ❌ ERREUR: Durée invalide ($duration ans)');
      showError(
          "Durée comprise entre 5 et 50 ans selon les principes du contrat CORIS RETRAITE.");
      return -1;
    }

    // Si hors ligne, utiliser les données locales directement
    if (_useLocalData) {
      print('\n   📍 MODE HORS LIGNE: Utilisation des données locales...');
      final localPremium = LocalDataService.calculateRetraitePremium(
          duration, periodicity, desiredCapital);

      if (localPremium > 0) {
        print('   ✅ Calcul réussi avec données locales');
        print('      Prime = ${localPremium.toStringAsFixed(2)} FCFA');
        return localPremium;
      } else {
        print('   ❌ Erreur calcul avec données locales');
        showError("Paramètres invalides pour le calcul.");
        return -1;
      }
    }

    // Étape 1: Essayer de récupérer depuis la base de données
    print('\n   📍 ÉTAPE 1: Tentative récupération depuis BASE DE DONNÉES...');
    try {
      final result = await _produitSyncService.getTarifWithSource(
        produitLibelle: 'CORIS RETRAITE',
        age: null, // RETRAITE n'utilise pas l'âge
        dureeContrat: duration,
        periodicite: periodicity,
      );
      final tarifFromDB = result['tarif'] as TarifProduit?;
      final isFromServer = result['isFromServer'] as bool;

      if (tarifFromDB != null && tarifFromDB.prime != null) {
        print('   ✅ Tarif trouvé dans BASE DE DONNÉES');
        print('      Source: ${isFromServer ? "SERVEUR" : "CACHE LOCAL"}');
        print('      Prime pour 1M: ${tarifFromDB.prime} FCFA');

        double primePour1Million = tarifFromDB.prime!;

        // Vérifier si les décimales ont été perdues (ex: 6081.0 au lieu de 6081.40012)
        // Si la valeur se termine par .0 et que nous avons des données locales plus précises, les utiliser
        bool hasLostDecimals =
            (primePour1Million == primePour1Million.roundToDouble()) &&
                (primePour1Million >
                    100); // Éviter les faux positifs pour les petites valeurs

        if (hasLostDecimals &&
            premiumValues.containsKey(duration) &&
            premiumValues[duration]!.containsKey(periodicity)) {
          double localPrimePour1M = premiumValues[duration]![periodicity]!;
          // Vérifier que la valeur locale a effectivement plus de précision
          if ((localPrimePour1M - localPrimePour1M.roundToDouble()).abs() >
              0.01) {
            print(
                '   ⚠️  ATTENTION: Les décimales ont été perdues dans la DB!');
            print('      Valeur DB: $primePour1Million (arrondie)');
            print('      Valeur locale: $localPrimePour1M (précise)');
            print(
                '      → Utilisation des données locales pour plus de précision');
            primePour1Million = localPrimePour1M;
          }
        }

        double primeCalculee = (desiredCapital * primePour1Million) / 1000000;

        print('   💰 CALCUL:');
        print('      Prime = (Capital × PrimePour1M) / 1,000,000');
        print(
            '      Prime = (${desiredCapital.toStringAsFixed(0)} × $primePour1Million) / 1,000,000');
        print('      Prime = ${primeCalculee.toStringAsFixed(2)} FCFA');

        print(
            '\n╔═══════════════════════════════════════════════════════════════╗');
        print(
            '║ ✅ [RETRAITE] CALCUL RÉUSSI                                  ║');
        print(
            '╚═══════════════════════════════════════════════════════════════╝\n');

        return primeCalculee;
      } else {
        print('   ⚠️  Tarif NON trouvé dans BASE DE DONNÉES');
        print('      → Passage à l\'ÉTAPE 2 (Fallback)');
      }
    } catch (e) {
      print('   ❌ ERREUR lors de la récupération DB: $e');
      print('      → Passage à l\'ÉTAPE 2 (Fallback)');
    }

    // Étape 2: Fallback - Utiliser les données codées en dur
    print(
        '\n   📍 ÉTAPE 2: Tentative utilisation FALLBACK (données hardcodées)...');

    // Vérifier si les données hardcodées sont disponibles
    final hasHardcodedData = premiumValues.containsKey(duration) &&
        premiumValues[duration]!.containsKey(periodicity);

    if (hasHardcodedData) {
      double primePour1Million =
          premiumValues[duration]![periodicity]!.toDouble();
      print('   ✅ Données hardcodées disponibles');
      print('      Prime pour 1M: $primePour1Million FCFA');

      double primeCalculee = (desiredCapital * primePour1Million) / 1000000;

      print('   💰 CALCUL:');
      print('      Prime = (Capital × PrimePour1M) / 1,000,000');
      print(
          '      Prime = (${desiredCapital.toStringAsFixed(0)} × $primePour1Million) / 1,000,000');
      print('      Prime = ${primeCalculee.toStringAsFixed(2)} FCFA');

      print(
          '\n╔═══════════════════════════════════════════════════════════════╗');
      print('║ ⚠️  [RETRAITE] CALCUL RÉUSSI (FALLBACK - données hardcodées) ║');
      print(
          '╚═══════════════════════════════════════════════════════════════╝\n');

      return primeCalculee;
    } else {
      print('   ❌ Données hardcodées NON disponibles');
      print(
          '      - premiumValues contient la durée $duration? ${premiumValues.containsKey(duration)}');
      if (premiumValues.containsKey(duration)) {
        print(
            '      - premiumValues[$duration] contient $periodicity? ${premiumValues[duration]!.containsKey(periodicity)}');
      }
      print('   ⚠️  IMPOSSIBLE DE CALCULER: Aucune donnée disponible');
      print('      → Ni base de données, ni données hardcodées');

      showError(
          "Données non disponibles pour cette combinaison durée/périodicité. Veuillez vérifier votre connexion Internet ou contacter le support.");

      print(
          '\n╔═══════════════════════════════════════════════════════════════╗');
      print('║ ❌ [RETRAITE] CALCUL ÉCHOUÉ                                   ║');
      print(
          '╚═══════════════════════════════════════════════════════════════╝\n');

      return -1;
    }
  }

  Future<double> calculateCapital(
      int duration, String periodicity, double paidPremium) async {
    print(
        '\n╔═══════════════════════════════════════════════════════════════╗');
    print('║ 🧮 [RETRAITE] CALCUL CAPITAL DÉMARRÉ                         ║');
    print('╚═══════════════════════════════════════════════════════════════╝');
    print('   📊 Paramètres:');
    print('      - Durée: $duration ans');
    print('      - Périodicité: $periodicity');
    print('      - Prime payée: ${paidPremium.toStringAsFixed(0)} FCFA');
    print(
        '   🌐 Mode: ${_useLocalData ? "HORS LIGNE (données locales)" : "EN LIGNE"}');

    if (duration < 5 || duration > 50) {
      print('   ❌ ERREUR: Durée invalide ($duration ans)');
      showError(
          "Durée comprise entre 5 et 50 ans selon les principes du contrat CORIS RETRAITE.");
      return -1;
    }

    double minPremium = minPrimes[periodicity]!.toDouble();
    if (paidPremium < minPremium) {
      print('   ❌ ERREUR: Prime inférieure au minimum');
      showError(
          "Pour cette périodicité ($periodicity), la prime minimum est ${_formatNumber(minPremium)} FCFA.");
      return -1;
    }

    // Si hors ligne, utiliser les données locales directement
    if (_useLocalData) {
      print('\n   📍 MODE HORS LIGNE: Utilisation des données locales...');
      final localCapital = LocalDataService.calculateRetraiteCapital(
          duration, periodicity, paidPremium);

      if (localCapital > 0) {
        print('   ✅ Calcul réussi avec données locales');
        print('      Capital = ${localCapital.toStringAsFixed(2)} FCFA');
        return localCapital;
      } else {
        print('   ❌ Erreur calcul avec données locales');
        showError("Paramètres invalides pour le calcul.");
        return -1;
      }
    }

    // Étape 1: Essayer de récupérer depuis la base de données
    print('\n   📍 ÉTAPE 1: Tentative récupération depuis BASE DE DONNÉES...');
    try {
      final result = await _produitSyncService.getTarifWithSource(
        produitLibelle: 'CORIS RETRAITE',
        age: null, // RETRAITE n'utilise pas l'âge
        dureeContrat: duration,
        periodicite: periodicity,
      );
      final tarifFromDB = result['tarif'] as TarifProduit?;
      final isFromServer = result['isFromServer'] as bool;

      if (tarifFromDB != null && tarifFromDB.prime != null) {
        print('   ✅ Tarif trouvé dans BASE DE DONNÉES');
        print('      Source: ${isFromServer ? "SERVEUR" : "CACHE LOCAL"}');
        print('      Prime pour 1M: ${tarifFromDB.prime} FCFA');

        double primePour1Million = tarifFromDB.prime!;

        // Vérifier si les décimales ont été perdues (ex: 6081.0 au lieu de 6081.40012)
        // Si la valeur se termine par .0 et que nous avons des données locales plus précises, les utiliser
        bool hasLostDecimals =
            (primePour1Million == primePour1Million.roundToDouble()) &&
                (primePour1Million >
                    100); // Éviter les faux positifs pour les petites valeurs

        if (hasLostDecimals &&
            premiumValues.containsKey(duration) &&
            premiumValues[duration]!.containsKey(periodicity)) {
          double localPrimePour1M = premiumValues[duration]![periodicity]!;
          // Vérifier que la valeur locale a effectivement plus de précision
          if ((localPrimePour1M - localPrimePour1M.roundToDouble()).abs() >
              0.01) {
            print(
                '   ⚠️  ATTENTION: Les décimales ont été perdues dans la DB!');
            print('      Valeur DB: $primePour1Million (arrondie)');
            print('      Valeur locale: $localPrimePour1M (précise)');
            print(
                '      → Utilisation des données locales pour plus de précision');
            primePour1Million = localPrimePour1M;
          }
        }

        double capitalCalcule = (paidPremium * 1000000) / primePour1Million;

        print('   💰 CALCUL:');
        print('      Capital = (Prime × 1,000,000) / PrimePour1M');
        print(
            '      Capital = (${paidPremium.toStringAsFixed(0)} × 1,000,000) / $primePour1Million');
        print('      Capital = ${capitalCalcule.toStringAsFixed(2)} FCFA');

        print(
            '\n╔═══════════════════════════════════════════════════════════════╗');
        print(
            '║ ✅ [RETRAITE] CALCUL RÉUSSI                                  ║');
        print(
            '╚═══════════════════════════════════════════════════════════════╝\n');

        return capitalCalcule;
      } else {
        print('   ⚠️  Tarif NON trouvé dans BASE DE DONNÉES');
        print('      → Passage à l\'ÉTAPE 2 (Fallback)');
      }
    } catch (e) {
      print('   ❌ ERREUR lors de la récupération DB: $e');
      print('      → Passage à l\'ÉTAPE 2 (Fallback)');
    }

    // Étape 2: Fallback - Utiliser les données codées en dur
    print(
        '\n   📍 ÉTAPE 2: Tentative utilisation FALLBACK (données hardcodées)...');

    // Vérifier si les données hardcodées sont disponibles
    final hasHardcodedData = premiumValues.containsKey(duration) &&
        premiumValues[duration]!.containsKey(periodicity);

    if (hasHardcodedData) {
      double primePour1Million =
          premiumValues[duration]![periodicity]!.toDouble();
      print('   ✅ Données hardcodées disponibles');
      print('      Prime pour 1M: $primePour1Million FCFA');

      double capitalCalcule = (paidPremium * 1000000) / primePour1Million;

      print('   💰 CALCUL:');
      print('      Capital = (Prime × 1,000,000) / PrimePour1M');
      print(
          '      Capital = (${paidPremium.toStringAsFixed(0)} × 1,000,000) / $primePour1Million');
      print('      Capital = ${capitalCalcule.toStringAsFixed(2)} FCFA');

      print(
          '\n╔═══════════════════════════════════════════════════════════════╗');
      print('║ ⚠️  [RETRAITE] CALCUL RÉUSSI (FALLBACK - données hardcodées) ║');
      print(
          '╚═══════════════════════════════════════════════════════════════╝\n');

      return capitalCalcule;
    } else {
      print('   ❌ Données hardcodées NON disponibles');
      print(
          '      - premiumValues contient la durée $duration? ${premiumValues.containsKey(duration)}');
      if (premiumValues.containsKey(duration)) {
        print(
            '      - premiumValues[$duration] contient $periodicity? ${premiumValues[duration]!.containsKey(periodicity)}');
      }
      print('   ⚠️  IMPOSSIBLE DE CALCULER: Aucune donnée disponible');
      print('      → Ni base de données, ni données hardcodées');

      showError(
          "Données non disponibles pour cette combinaison durée/périodicité. Veuillez vérifier votre connexion Internet ou contacter le support.");

      print(
          '\n╔═══════════════════════════════════════════════════════════════╗');
      print('║ ❌ [RETRAITE] CALCUL ÉCHOUÉ                                   ║');
      print(
          '╚═══════════════════════════════════════════════════════════════╝\n');

      return -1;
    }
  }

  void simuler() async {
    if (!_validateInputs()) return;

    setState(() {
      isLoading = true;
      result = null;
      resultLabel = '';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      int duree = int.tryParse(_dureeController.text) ?? 0;
      double montant = double.tryParse(
              _valeurController.text.replaceAll(' ', '').replaceAll(',', '')) ??
          0;

      if (montant <= 0) {
        showError("Montant invalide. Veuillez entrer un montant positif.");
        setState(() => isLoading = false);
        return;
      }

      if (selectedOption == 'capital') {
        double calculatedPremium =
            await calculatePremium(duree, selectedPeriodicite, montant);
        if (calculatedPremium != -1) {
          result = calculatedPremium;
          resultLabel = "Prime $selectedPeriodicite à verser";
        }
      } else {
        double calculatedCapital =
            await calculateCapital(duree, selectedPeriodicite, montant);
        if (calculatedCapital != -1) {
          result = calculatedCapital;
          resultLabel = "Capital estimé au terme";
        }
      }
    } catch (e) {
      showError(
          "Une erreur est survenue lors du calcul. Veuillez vérifier vos données.");
    }

    setState(() => isLoading = false);
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bleuCoris, Color.lerp(bleuCoris, Colors.black, 0.2)!],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 43, 107, 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.emoji_people, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "CORIS RETRAITE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

  @override
  Widget build(BuildContext context) {
    return ConnectivityBuilder(
      builder: (context, isConnected) {
        _useLocalData = !isConnected;

        return Scaffold(
          backgroundColor: grisClairBg,
          body: Column(
            children: [
              if (!isConnected) ConnectivityBanner(isConnected: isConnected),
              _buildModernHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(0, 43, 107, 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.settings,
                                        color: bleuCoris, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Paramètres de simulation",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002B6B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildSimulationTypeDropdown(),
                              const SizedBox(height: 16),
                              _buildDureeField(),
                              const SizedBox(height: 16),
                              _buildPeriodiciteDropdown(),
                              const SizedBox(height: 16),
                              _buildMontantField(),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : simuler,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rougeCoris,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_circle_filled,
                                                size: 22),
                                            SizedBox(width: 8),
                                            Text(
                                              "Simuler",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (result != null) _buildResultCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulationTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: selectedOption,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.calculate, color: Color(0xFF002B6B)),
            labelText: 'Type de simulation',
          ),
          items: const [
            DropdownMenuItem(
              value: 'capital',
              child: Text('Par Capital'),
            ),
            DropdownMenuItem(
              value: 'prime',
              child: Text('Par Prime'),
            ),
          ],
          onChanged: (val) => setState(() {
            selectedOption = val!;
            _valeurController.clear();
            result = null;
          }),
        ),
      ),
    );
  }

  Widget _buildPeriodiciteDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: selectedPeriodicite,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF002B6B)),
            labelText: 'Périodicité',
          ),
          items: const [
            DropdownMenuItem(
              value: 'mensuel',
              child: Text('Mensuel'),
            ),
            DropdownMenuItem(
              value: 'trimestriel',
              child: Text('Trimestriel'),
            ),
            DropdownMenuItem(
              value: 'semestriel',
              child: Text('Semestriel'),
            ),
            DropdownMenuItem(
              value: 'annuel',
              child: Text('Annuel'),
            ),
          ],
          onChanged: (val) => setState(() {
            selectedPeriodicite = val!;
            _valeurController.clear();
            result = null;
          }),
        ),
      ),
    );
  }

  Widget _buildDureeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durée du contrat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dureeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: 'Entre 5 et 50 ans',
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: Icon(Icons.schedule,
                size: 20, color: Color.fromRGBO(0, 43, 107, 0.7)),
            suffixText: 'ans',
            filled: true,
            fillColor: Color.fromRGBO(232, 244, 253, 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: bleuCoris, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMontantField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedOption == 'capital' ? 'Capital souhaité' : 'Prime à verser',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _valeurController,
          keyboardType: TextInputType.number,
          onChanged: (value) => _formatMontantInput(),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: currentHint,
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: Icon(Icons.monetization_on,
                size: 20, color: Color.fromRGBO(0, 43, 107, 0.7)),
            suffixText: 'FCFA',
            filled: true,
            fillColor: Color.fromRGBO(232, 244, 253, 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: bleuCoris, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(0, 166, 80, 0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(0, 166, 80, 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 166, 80, 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.monetization_on, color: vertCoris, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Résultat de la simulation",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: bleuCoris,
                        ),
                      ),
                      Text(
                        resultLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: bleuCoris),
                  onPressed: _resetSimulation,
                  tooltip: 'Nouvelle simulation',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color.fromRGBO(0, 166, 80, 0.1)),
              ),
              child: Text(
                '${_formatNumber(result!)} FCFA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: vertCoris,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  // Préparer les données de simulation
                  final simulationData = {
                    'type': selectedOption,
                    'duree': int.parse(_dureeController.text),
                    'periodicite': selectedPeriodicite,
                    'capital': selectedOption == 'capital'
                        ? double.parse(
                            _valeurController.text.replaceAll(' ', ''))
                        : result!,
                    'prime': selectedOption == 'prime'
                        ? double.parse(
                            _valeurController.text.replaceAll(' ', ''))
                        : result!,
                  };

                  // Vérifier le rôle et rediriger
                  final userRole = await AuthService.getUserRole();
                  if (userRole == 'commercial') {
                    // Pour les commerciaux, rediriger vers la sélection de client
                    Navigator.pushNamed(
                      context,
                      '/commercial/select_client',
                      arguments: {
                        'productType': 'retraite',
                        'simulationData': simulationData,
                      },
                    );
                  } else {
                    // Pour les clients, rediriger directement vers la souscription
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SouscriptionRetraitePage(
                          simulationData: simulationData,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vertCoris,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Souscrire",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
