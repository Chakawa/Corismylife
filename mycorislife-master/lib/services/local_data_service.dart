/// Service de données locales pour les produits
/// Fournit les tarifs et données même en mode hors ligne
class LocalDataService {
  // ========================================
  // CORIS RETRAITE - Tarifs locaux
  // ========================================

  static const Map<String, int> retraiteMinPrimes = {
    'mensuel': 5000,
    'trimestriel': 15000,
    'semestriel': 30000,
    'annuel': 60000,
  };

  static const Map<int, Map<String, double>> retraitePremiumValues = {
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
      'trimestriel': 16251.50009,
      'semestriel': 32225.25076,
      'annuel': 63784.46073
    },
    14: {
      'mensuel': 5025.94766,
      'trimestriel': 14812.80997,
      'semestriel': 29378.55426,
      'annuel': 58155.61527
    },
    15: {
      'mensuel': 4602.66274,
      'trimestriel': 13562.06754,
      'semestriel': 26903.60928,
      'annuel': 53252.28014
    },
    16: {
      'mensuel': 4229.14558,
      'trimestriel': 12461.35516,
      'semestriel': 24721.66146,
      'annuel': 48938.03146
    },
    17: {
      'mensuel': 3896.26707,
      'trimestriel': 11479.83082,
      'semestriel': 22775.30419,
      'annuel': 45086.95158
    },
    18: {
      'mensuel': 3597.36148,
      'trimestriel': 10596.23479,
      'semestriel': 21024.61736,
      'annuel': 41621.78914
    },
    19: {
      'mensuel': 3327.58816,
      'trimestriel': 9794.37756,
      'semestriel': 19436.89945,
      'annuel': 38480.13399
    },
    20: {
      'mensuel': 3082.77894,
      'trimestriel': 9061.10494,
      'semestriel': 17986.52555,
      'annuel': 35608.06630
    },
    21: {
      'mensuel': 2859.64487,
      'trimestriel': 8385.24062,
      'semestriel': 16653.31493,
      'annuel': 32963.57965
    },
    22: {
      'mensuel': 2655.45989,
      'trimestriel': 7757.76992,
      'semestriel': 15420.47337,
      'annuel': 30513.45551
    },
    23: {
      'mensuel': 2467.98607,
      'trimestriel': 7171.73481,
      'semestriel': 14273.92949,
      'annuel': 28229.14859
    },
    24: {
      'mensuel': 2295.32819,
      'trimestriel': 6621.67424,
      'semestriel': 13202.12695,
      'annuel': 26086.96063
    },
    25: {
      'mensuel': 2135.88171,
      'trimestriel': 6103.02014,
      'semestriel': 12195.43878,
      'annuel': 24066.39699
    },
    26: {
      'mensuel': 1988.30992,
      'trimestriel': 5611.94446,
      'semestriel': 11245.70089,
      'annuel': 22150.73881
    },
    27: {
      'mensuel': 1851.49825,
      'trimestriel': 5145.43682,
      'semestriel': 10346.28682,
      'annuel': 20326.78248
    },
    28: {
      'mensuel': 1724.48850,
      'trimestriel': 4700.85859,
      'semestriel': 9491.99397,
      'annuel': 18583.17771
    },
    29: {
      'mensuel': 1606.45881,
      'trimestriel': 4276.05644,
      'semestriel': 8678.15634,
      'annuel': 16910.78936
    },
    30: {
      'mensuel': 1496.72012,
      'trimestriel': 3869.25225,
      'semestriel': 7900.54290,
      'annuel': 15301.49822
    },
    31: {
      'mensuel': 1394.69226,
      'trimestriel': 3478.93788,
      'semestriel': 7155.30376,
      'annuel': 13748.84085
    },
    32: {
      'mensuel': 1299.88846,
      'trimestriel': 3103.80290,
      'semestriel': 6439.03115,
      'annuel': 12247.07088
    },
    33: {
      'mensuel': 1211.89975,
      'trimestriel': 2742.73863,
      'semestriel': 5748.72916,
      'annuel': 10791.22826
    },
    34: {
      'mensuel': 1130.37843,
      'trimestriel': 2395.01025,
      'semestriel': 5081.88394,
      'annuel': 9377.27932
    },
    35: {
      'mensuel': 1055.03415,
      'trimestriel': 2060.12264,
      'semestriel': 4436.32063,
      'annuel': 8001.46043
    },
    36: {
      'mensuel': 985.61968,
      'trimestriel': 1737.70732,
      'semestriel': 3810.15063,
      'annuel': 6661.32568
    },
    37: {
      'mensuel': 921.91732,
      'trimestriel': 1427.60639,
      'semestriel': 3201.66915,
      'annuel': 5354.66997
    },
    38: {
      'mensuel': 863.73680,
      'trimestriel': 1129.76928,
      'semestriel': 2609.36125,
      'annuel': 4079.49829
    },
    39: {
      'mensuel': 810.90312,
      'trimestriel': 844.25053,
      'semestriel': 2031.84207,
      'annuel': 2834.00214
    },
    40: {
      'mensuel': 763.26502,
      'trimestriel': 571.11695,
      'semestriel': 1467.85313,
      'annuel': 1616.56515
    },
    41: {
      'mensuel': 720.68324,
      'trimestriel': 310.53565,
      'semestriel': 916.23623,
      'annuel': 425.64688
    },
    42: {
      'mensuel': 683.02688,
      'trimestriel': 62.68245,
      'semestriel': 375.91882,
      'annuel': -641.24057
    },
    43: {
      'mensuel': 650.17069,
      'trimestriel': -172.08579,
      'semestriel': -154.24758,
      'annuel': -1586.70652
    },
    44: {
      'mensuel': 621.99321,
      'trimestriel': -393.98899,
      'semestriel': -675.74648,
      'annuel': -2412.56932
    },
    45: {
      'mensuel': 598.37477,
      'trimestriel': -603.29539,
      'semestriel': -1189.94598,
      'annuel': -3120.75693
    },
    46: {
      'mensuel': 579.20499,
      'trimestriel': -800.26163,
      'semestriel': -1698.29244,
      'annuel': -3713.25033
    },
    47: {
      'mensuel': 564.37153,
      'trimestriel': -985.13931,
      'semestriel': -2202.19775,
      'annuel': -4192.08764
    },
    48: {
      'mensuel': 553.76058,
      'trimestriel': -1158.16401,
      'semestriel': -2703.03467,
      'annuel': -4559.37648
    },
    49: {
      'mensuel': 547.25694,
      'trimestriel': -1319.55414,
      'semestriel': -3202.13550,
      'annuel': -4817.29541
    },
    50: {
      'mensuel': 544.74445,
      'trimestriel': -1469.51071,
      'semestriel': -3700.81295,
      'annuel': -4968.09426
    },
  };

  // ========================================
  // CORIS SÉRÉNITÉ - Tarifs locaux
  // ========================================

  static const Map<String, int> sereniteMinPrimes = {
    'mensuel': 5000,
    'trimestriel': 15000,
    'semestriel': 30000,
    'annuel': 60000,
  };

  static const int sereniteMaxCapital = 40000000; // 40M FCFA
  static const int sereniteMaxDurationMonths = 180; // 15 ans
  static const int sereniteMinAge = 18;
  static const int sereniteMaxAge = 69;

  // ========================================
  // FLEX EMPRUNTEUR - Tarifs locaux
  // ========================================

  static const int flexMaxLoan = 30000000; // 30M FCFA

  // ========================================
  // CORIS ÉTUDE - Tarifs locaux
  // ========================================

  static const int etudeMaxDuration = 17; // Jusqu'à 17 ans

  // ========================================
  // MÉTHODES UTILITAIRES
  // ========================================

  /// Calcule la prime pour CORIS RETRAITE (mode local)
  static double calculateRetraitePremium(
      int duration, String periodicity, double desiredCapital) {
    if (duration < 5 || duration > 50) return -1;
    if (!retraitePremiumValues.containsKey(duration)) return -1;
    if (!retraitePremiumValues[duration]!.containsKey(periodicity)) return -1;

    final premiumFor1M = retraitePremiumValues[duration]![periodicity]!;
    return (desiredCapital * premiumFor1M) / 1000000;
  }

  /// Calcule le capital pour CORIS RETRAITE (mode local)
  static double calculateRetraiteCapital(
      int duration, String periodicity, double paidPremium) {
    if (duration < 5 || duration > 50) return -1;
    if (!retraitePremiumValues.containsKey(duration)) return -1;
    if (!retraitePremiumValues[duration]!.containsKey(periodicity)) return -1;

    final minPremium = retraiteMinPrimes[periodicity]?.toDouble() ?? 0;
    if (paidPremium < minPremium) return -1;

    final premiumFor1M = retraitePremiumValues[duration]![periodicity]!;
    return (paidPremium * 1000000) / premiumFor1M;
  }

  /// Vérifie si les données locales sont disponibles pour un produit
  static bool hasLocalData(String productType) {
    switch (productType.toLowerCase()) {
      case 'retraite':
        return retraitePremiumValues.isNotEmpty;
      case 'serenite':
      case 'sérénité':
        return true;
      case 'flex':
      case 'emprunteur':
        return true;
      case 'etude':
      case 'étude':
        return true;
      default:
        return false;
    }
  }

  /// Récupère les contraintes d'un produit
  static Map<String, dynamic> getProductConstraints(String productType) {
    switch (productType.toLowerCase()) {
      case 'retraite':
        return {
          'minPrimes': retraiteMinPrimes,
          'minDuration': 5,
          'maxDuration': 50,
          'minAge': 18,
          'maxAge': 69,
        };
      case 'serenite':
      case 'sérénité':
        return {
          'minPrimes': sereniteMinPrimes,
          'maxCapital': sereniteMaxCapital,
          'maxDurationMonths': sereniteMaxDurationMonths,
          'minAge': sereniteMinAge,
          'maxAge': sereniteMaxAge,
        };
      case 'flex':
      case 'emprunteur':
        return {
          'maxLoan': flexMaxLoan,
        };
      case 'etude':
      case 'étude':
        return {
          'maxDuration': etudeMaxDuration,
        };
      default:
        return {};
    }
  }
}
