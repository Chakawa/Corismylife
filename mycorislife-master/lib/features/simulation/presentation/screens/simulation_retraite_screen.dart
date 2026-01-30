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
  double calculatedPrime = 0.0;  // Prime calculée (toujours afficher)
  double calculatedCapital = 0.0; // Capital calculé (toujours afficher)
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

  // Nouvelles valeurs: CAPITAL À TERME pour une prime de 10000 FCFA (mensuel)
  // ou équivalent (30000 tri, 60000 sem, 120000 ann)
  final Map<int, Map<String, double>> capitalValues = {
    5: {
      'mensuel': 605463.405379,
      'trimestriel': 615056.504123,
      'semestriel': 620331.447928,
      'annuel': 625666.388106
    },
    6: {
      'mensuel': 739294.364577,
      'trimestriel': 752266.795228,
      'semestriel': 758213.774878,
      'annuel': 764734.523010
    },
    7: {
      'mensuel': 877714.810967,
      'trimestriel': 891453.723199,
      'semestriel': 898104.646416,
      'annuel': 908670.042636
    },
    8: {
      'mensuel': 1020882.065727,
      'trimestriel': 1038327.916972,
      'semestriel': 1045708.931812,
      'annuel': 1057643.305449
    },
    9: {
      'mensuel': 1168958.840396,
      'trimestriel': 1190342.707527,
      'semestriel': 1190479.470698,
      'annuel': 1211830.632461
    },
    10: {
      'mensuel': 1322113.421481,
      'trimestriel': 1344587.648202,
      'semestriel': 1356596.978444,
      'annuel': 1371414.515917
    },
    11: {
      'mensuel': 1480519.861382,
      'trimestriel': 1507300.829349,
      'semestriel': 1520248.598961,
      'annuel': 1536583.835295
    },
    12: {
      'mensuel': 1644358.175855,
      'trimestriel': 1675729.671837,
      'semestriel': 1689628.026197,
      'annuel': 1707534.080851
    },
    13: {
      'mensuel': 1813844.548229,
      'trimestriel': 1846605.003713,
      'semestriel': 1861472.384183,
      'annuel': 1880974.450438
    },
    14: {
      'mensuel': 1989081.640624,
      'trimestriel': 2026309.492304,
      'semestriel': 2042794.643842,
      'annuel': 2063978.367524
    },
    15: {
      'mensuel': 2170358.312385,
      'trimestriel': 2213524.637995,
      'semestriel': 2230463.182648,
      'annuel': 2253387.421708
    },
    16: {
      'mensuel': 2361663.347047,
      'trimestriel': 2402847.877909,
      'semestriel': 2424700.120313,
      'annuel': 2449425.792789
    },
    17: {
      'mensuel': 2559654.057923,
      'trimestriel': 2602620.867097,
      'semestriel': 2625735.350796,
      'annuel': 2652329.506857
    },
    18: {
      'mensuel': 2764594.793679,
      'trimestriel': 2809385.910906,
      'semestriel': 2833806.814345,
      'annuel': 2862326.710918
    },
    19: {
      'mensuel': 2976698.105187,
      'trimestriel': 3019148.619548,
      'semestriel': 3044903.438595,
      'annuel': 3079677.957121
    },
    20: {
      'mensuel': 3196225.032957,
      'trimestriel': 3240492.134693,
      'semestriel': 3267645.786918,
      'annuel': 3304636.466941
    },
    21: {
      'mensuel': 3423435.402467,
      'trimestriel': 3469582.672868,
      'semestriel': 3498184.113972,
      'annuel': 3537468.588654
    },
    22: {
      'mensuel': 3658598.135282,
      'trimestriel': 3701991.400963,
      'semestriel': 3736791.284233,
      'annuel': 3778449.797473
    },
    23: {
      'mensuel': 3901991.563746,
      'trimestriel': 3947234.413457,
      'semestriel': 3983749.705453,
      'annuel': 4027865.351705
    },
    24: {
      'mensuel': 4153903.762206,
      'trimestriel': 4201060.933389,
      'semestriel': 4239351.671416,
      'annuel': 4286010.450336
    },
    25: {
      'mensuel': 4414632.887612,
      'trimestriel': 4458560.426312,
      'semestriel': 4498666.347671,
      'annuel': 4547912.261262
    },
    26: {
      'mensuel': 4684487.532408,
      'trimestriel': 4730283.355211,
      'semestriel': 4772290.396112,
      'annuel': 4824259.001727
    },
    27: {
      'mensuel': 4963787.683771,
      'trimestriel': 5011516.586104,
      'semestriel': 5055491.266247,
      'annuel': 5110277.878109
    },
    28: {
      'mensuel': 5252862.131642,
      'trimestriel': 5296815.505562,
      'semestriel': 5348604.207638,
      'annuel': 5406307.415163
    },
    29: {
      'mensuel': 5552054.799978,
      'trimestriel': 5597877.362131,
      'semestriel': 5651976.081074,
      'annuel': 5712697.986015
    },
    30: {
      'mensuel': 5861719.211707,
      'trimestriel': 5909476.383267,
      'semestriel': 5965965.970183,
      'annuel': 6029812.226846
    },
    31: {
      'mensuel': 6182221.877845,
      'trimestriel': 6225575.781317,
      'semestriel': 6284512.371581,
      'annuel': 6358025.466106
    },
    32: {
      'mensuel': 6513942.137299,
      'trimestriel': 6559144.247123,
      'semestriel': 6620641.030858,
      'annuel': 6697726.168741
    },
    33: {
      'mensuel': 6857272.605833,
      'trimestriel': 6904387.609234,
      'semestriel': 6968534.193210,
      'annuel': 7049316.395967
    },
    34: {
      'mensuel': 7212619.840766,
      'trimestriel': 7264612.498187,
      'semestriel': 7328603.616244,
      'annuel': 7413212.281147
    },
    35: {
      'mensuel': 7580403.821922,
      'trimestriel': 7624197.249084,
      'semestriel': 7701275.469085,
      'annuel': 7789844.522308
    },
    36: {
      'mensuel': 7961060.449418,
      'trimestriel': 8006717.466263,
      'semestriel': 8086990.836775,
      'annuel': 8179658.891909
    },
    37: {
      'mensuel': 8355040.058877,
      'trimestriel': 8394751.786861,
      'semestriel': 8478298.278308,
      'annuel': 8575140.790787
    },
    38: {
      'mensuel': 8762808.954867,
      'trimestriel': 8804241.412862,
      'semestriel': 8891209.444321,
      'annuel': 8992440.529785
    },
    39: {
      'mensuel': 9184849.761809,
      'trimestriel': 9228063.175773,
      'semestriel': 9318572.501144,
      'annuel': 9424345.759649
    },
    40: {
      'mensuel': 9621661.997201,
      'trimestriel': 9657988.540329,
      'semestriel': 9760893.264956,
      'annuel': 9871367.672557
    },
    41: {
      'mensuel': 10073762.660832,
      'trimestriel': 10111691.452702,
      'semestriel': 10218695.255501,
      'annuel': 10334035.352417
    },
    42: {
      'mensuel': 10541686.847690,
      'trimestriel': 10581273.967007,
      'semestriel': 10692520.315715,
      'annuel': 10812896.401073
    },
    43: {
      'mensuel': 11025988.381088,
      'trimestriel': 11057612.584807,
      'semestriel': 11173208.346138,
      'annuel': 11308517.586431
    },
    44: {
      'mensuel': 11527240.468155,
      'trimestriel': 11560302.338736,
      'semestriel': 11680441.364525,
      'annuel': 11821485.513277
    },
    45: {
      'mensuel': 12046036.378270,
      'trimestriel': 12080582.334053,
      'semestriel': 12205427.538555,
      'annuel': 12352407.317562
    },
    46: {
      'mensuel': 12582990.145238,
      'trimestriel': 12619080.006705,
      'semestriel': 12748788.228676,
      'annuel': 12901911.384998
    },
    47: {
      'mensuel': 13138737.294051,
      'trimestriel': 13176421.181466,
      'semestriel': 13311166.542952,
      'annuel': 13470648.094793
    },
    48: {
      'mensuel': 13713935.593071,
      'trimestriel': 13753269.236278,
      'semestriel': 13893228.098227,
      'annuel': 14059290.589432
    },
    49: {
      'mensuel': 14309265.832568,
      'trimestriel': 14350306.973009,
      'semestriel': 14483712.331354,
      'annuel': 14668483.327573
    },
    50: {
      'mensuel': 14925432.630426,
      'trimestriel': 14968241.030525,
      'semestriel': 15106812.989223,
      'annuel': 15286630.055359
    },
  };

  final Map<String, double> primeReferenceValues = {
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
        print('      Capital pour prime ref: ${tarifFromDB.prime} FCFA');

        double capitalForRefPrime = tarifFromDB.prime!;

        // Vérifier si les décimales ont été perdues
        // Si la valeur se termine par .0 et que nous avons des données locales plus précises, les utiliser
        bool hasLostDecimals =
            (capitalForRefPrime == capitalForRefPrime.roundToDouble()) &&
                (capitalForRefPrime >
                    100); // Éviter les faux positifs pour les petites valeurs

        if (hasLostDecimals &&
            capitalValues.containsKey(duration) &&
            capitalValues[duration]!.containsKey(periodicity)) {
          double localCapitalForRef = capitalValues[duration]![periodicity]!;
          // Vérifier que la valeur locale a effectivement plus de précision
          if ((localCapitalForRef - localCapitalForRef.roundToDouble()).abs() >
              0.01) {
            print(
                '   ⚠️  ATTENTION: Les décimales ont été perdues dans la DB!');
            print('      Valeur DB: $capitalForRefPrime (arrondie)');
            print('      Valeur locale: $localCapitalForRef (précise)');
            print(
                '      → Utilisation des données locales pour plus de précision');
            capitalForRefPrime = localCapitalForRef;
          }
        }

        double primeReference = primeReferenceValues[periodicity]!;
        double primeCalculee = (desiredCapital * primeReference) / capitalForRefPrime;

        print('   💰 CALCUL (nouvelle méthode):');
        print('      Prime = (Capital_Voulu × Prime_Reference) / Capital_pour_Prime_Reference');
        print(
            '      Prime = (${desiredCapital.toStringAsFixed(0)} × ${primeReference.toStringAsFixed(0)}) / $capitalForRefPrime');
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
    final hasHardcodedData = capitalValues.containsKey(duration) &&
        capitalValues[duration]!.containsKey(periodicity);

    if (hasHardcodedData) {
      double capitalPour10K =
          capitalValues[duration]![periodicity]!.toDouble();
      double primeReference = primeReferenceValues[periodicity]!;
      
      print('   ✅ Données hardcodées disponibles');
      print('      Capital pour prime de ${primeReference.toStringAsFixed(0)} FCFA: ${capitalPour10K.toStringAsFixed(2)} FCFA');

      // NOUVELLE MÉTHODE: Prime = (Capital_Voulu × Prime_Reference) / Capital_pour_Prime_Reference
      double primeCalculee = (desiredCapital * primeReference) / capitalPour10K;

      print('   💰 CALCUL (nouvelle méthode):');
      print('      Prime = (Capital_Voulu × Prime_Reference) / Capital_pour_Prime_Reference');
      print(
          '      Prime = (${desiredCapital.toStringAsFixed(0)} × ${primeReference.toStringAsFixed(0)}) / ${capitalPour10K.toStringAsFixed(2)}');
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
          '      - capitalValues contient la durée $duration? ${capitalValues.containsKey(duration)}');
      if (capitalValues.containsKey(duration)) {
        print(
            '      - capitalValues[$duration] contient $periodicity? ${capitalValues[duration]!.containsKey(periodicity)}');
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
          "Pour cette périodicité ($periodicity), la prime minimale est ${_formatNumber(minPremium)} FCFA.");
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
        print('      Capital pour prime ref: ${tarifFromDB.prime} FCFA');

        double capitalForRefPrime = tarifFromDB.prime!;

        // Vérifier si les décimales ont été perdues
        // Si la valeur se termine par .0 et que nous avons des données locales plus précises, les utiliser
        bool hasLostDecimals =
            (capitalForRefPrime == capitalForRefPrime.roundToDouble()) &&
                (capitalForRefPrime >
                    100); // Éviter les faux positifs pour les petites valeurs

        if (hasLostDecimals &&
            capitalValues.containsKey(duration) &&
            capitalValues[duration]!.containsKey(periodicity)) {
          double localCapitalForRef = capitalValues[duration]![periodicity]!;
          // Vérifier que la valeur locale a effectivement plus de précision
          if ((localCapitalForRef - localCapitalForRef.roundToDouble()).abs() >
              0.01) {
            print(
                '   ⚠️  ATTENTION: Les décimales ont été perdues dans la DB!');
            print('      Valeur DB: $capitalForRefPrime (arrondie)');
            print('      Valeur locale: $localCapitalForRef (précise)');
            print(
                '      → Utilisation des données locales pour plus de précision');
            capitalForRefPrime = localCapitalForRef;
          }
        }

        // NOUVELLE MÉTHODE: Capital = (Prime_Payée × Capital_pour_Prime_Reference) / Prime_Reference
        double primeReference = primeReferenceValues[periodicity]!;
        double capitalCalcule = (paidPremium * capitalForRefPrime) / primeReference;

        print('   💰 CALCUL (nouvelle méthode):');
        print('      Capital = (Prime_Payée × Capital_pour_Prime_Reference) / Prime_Reference');
        print(
            '      Capital = (${paidPremium.toStringAsFixed(0)} × $capitalForRefPrime) / ${primeReference.toStringAsFixed(0)}');
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
    final hasHardcodedData = capitalValues.containsKey(duration) &&
        capitalValues[duration]!.containsKey(periodicity);

    if (hasHardcodedData) {
      double capitalPour10K =
          capitalValues[duration]![periodicity]!.toDouble();
      double primeReference = primeReferenceValues[periodicity]!;
      
      print('   ✅ Données hardcodées disponibles');
      print('      Capital pour prime de ${primeReference.toStringAsFixed(0)} FCFA: ${capitalPour10K.toStringAsFixed(2)} FCFA');

      // NOUVELLE MÉTHODE: Capital = (Prime_Payée × Capital_pour_Prime_Reference) / Prime_Reference
      double capitalCalcule = (paidPremium * capitalPour10K) / primeReference;

      print('   💰 CALCUL (nouvelle méthode):');
      print('      Capital = (Prime_Payée × Capital_pour_Prime_Reference) / Prime_Reference');
      print(
          '      Capital = (${paidPremium.toStringAsFixed(0)} × ${capitalPour10K.toStringAsFixed(2)}) / ${primeReference.toStringAsFixed(0)}');
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
          '      - capitalValues contient la durée $duration? ${capitalValues.containsKey(duration)}');
      if (capitalValues.containsKey(duration)) {
        print(
            '      - capitalValues[$duration] contient $periodicity? ${capitalValues[duration]!.containsKey(periodicity)}');
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
        // Utilisateur saisit le capital souhaité
        calculatedCapital = montant;
        double premium = await calculatePremium(duree, selectedPeriodicite, montant);
        if (premium != -1) {
          calculatedPrime = premium;
          result = premium;
          resultLabel = "Prime $selectedPeriodicite à verser";
        }
      } else {
        // Utilisateur saisit la prime qu'il peut verser
        calculatedPrime = montant;
        double capital = await calculateCapital(duree, selectedPeriodicite, montant);
        if (capital != -1) {
          calculatedCapital = capital;
          result = capital;
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
            // Afficher TOUJOURS capital ET prime (pas seulement l'un ou l'autre)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color.fromRGBO(0, 166, 80, 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prime périodique
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prime $selectedPeriodicite :',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_formatNumber(calculatedPrime)} FCFA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: bleuCoris,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  // Capital au terme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capital au terme :',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_formatNumber(calculatedCapital)} FCFA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: vertCoris,
                        ),
                      ),
                    ],
                  ),
                ],
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
