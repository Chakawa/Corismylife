import 'package:mycorislife/services/database_service.dart';
import 'package:mycorislife/models/produit_model.dart';
import 'package:mycorislife/models/tarif_produit_model.dart';

/// Service pour migrer les données codées en dur vers la base de données
class MigrationDataService {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Migrer toutes les données des produits depuis le code
  Future<void> migrateAllProducts() async {
    await migrateSereniteData();
    await migrateFamilisData();
    await migrateRetraiteData();
    await migrateSolidariteData();
    await migrateEtudeData();
  }

  /// Migrer les données CORIS SÉRÉNITÉ
  Future<void> migrateSereniteData() async {
    // Vérifier si le produit existe
    Produit? produit = await _dbService.getProduitByLibelle('CORIS SÉRÉNITÉ');
    int produitId;
    
    if (produit == null) {
      produitId = await _dbService.insertProduit(Produit(libelle: 'CORIS SÉRÉNITÉ'));
    } else {
      produitId = produit.id!;
    }

    // Supprimer les anciens tarifs
    await _dbService.deleteAllTarifsByProduit(produitId);

    // Données tarifaires CORIS SÉRÉNITÉ (âge: mois de durée)
    final Map<int, Map<int, double>> tarifaire = {
      18: {12: 211.068, 24: 107.682, 36: 73.248, 48: 56.051, 60: 45.749, 72: 38.895, 84: 34.010, 96: 30.356, 108: 27.524, 120: 25.266, 132: 23.426, 144: 21.900, 156: 20.616, 168: 19.521, 180: 18.578},
      19: {12: 216.612, 24: 110.520, 36: 75.183, 48: 57.535, 60: 46.962, 72: 39.927, 84: 34.913, 96: 31.163, 108: 28.256, 120: 25.939, 132: 24.051, 144: 22.485, 156: 21.166, 168: 20.043, 180: 19.075},
      20: {12: 222.215, 24: 113.384, 36: 77.134, 48: 59.030, 60: 48.183, 72: 40.966, 84: 35.822, 96: 31.976, 108: 28.993, 120: 26.616, 132: 24.679, 144: 23.073, 156: 21.721, 168: 20.568, 180: 19.576},
      // Ajoutez les autres âges si nécessaire...
      69: {12: 725.580, 24: 376.248, 36: 259.924, 48: 202.119, 60: 167.741, 72: 145.092, 84: 129.161, 96: 117.443, 108: 108.548, 120: 101.644, 132: 96.202, 144: 91.870, 156: 88.409, 168: 85.646, 180: 83.457},
    };

    List<TarifProduit> tarifs = [];
    for (var ageEntry in tarifaire.entries) {
      int age = ageEntry.key;
      for (var dureeEntry in ageEntry.value.entries) {
        int duree = dureeEntry.key;
        double prime = dureeEntry.value;
        
        tarifs.add(TarifProduit(
          produitId: produitId,
          dureeContrat: duree,
          periodicite: 'annuel',
          prime: prime,
          age: age,
        ));
      }
    }

    if (tarifs.isNotEmpty) {
      await _dbService.insertTarifsBatch(tarifs);
    }
  }

  /// Migrer les données CORIS FAMILIS
  Future<void> migrateFamilisData() async {
    Produit? produit = await _dbService.getProduitByLibelle('CORIS FAMILIS');
    int produitId;
    
    if (produit == null) {
      produitId = await _dbService.insertProduit(Produit(libelle: 'CORIS FAMILIS'));
    } else {
      produitId = produit.id!;
    }

    await _dbService.deleteAllTarifsByProduit(produitId);

    // Taux unique
    final Map<int, Map<int, double>> tauxUnique = {
      18: {1: 0.272, 2: 0.552, 3: 0.831, 4: 1.106, 5: 1.375, 6: 1.636, 7: 1.892, 8: 2.141, 9: 2.385, 10: 2.625, 11: 2.859, 12: 3.090, 13: 3.316, 14: 3.536, 15: 3.754, 16: 3.971, 17: 4.189, 18: 4.407, 19: 4.627, 20: 4.849},
      // Ajoutez les autres âges...
      65: {1: 2.521, 2: 5.099, 3: 7.700, 4: 10.324, 5: 12.965, 6: 15.621, 7: 18.287, 8: 20.957, 9: 23.623, 10: 26.279, 11: 28.921, 12: 31.547, 13: 34.149, 14: 36.725, 15: 39.275, 16: 41.801, 17: 44.299, 18: 46.757, 19: 49.153, 20: 51.465},
    };

    // Taux annuel
    final Map<int, Map<int, double>> tauxAnnuel = {
      18: {1: 0.272, 2: 0.281, 3: 0.287, 4: 0.292, 5: 0.295, 6: 0.298, 7: 0.300, 8: 0.302, 9: 0.305, 10: 0.307, 11: 0.309, 12: 0.311, 13: 0.314, 14: 0.316, 15: 0.318, 16: 0.321, 17: 0.324, 18: 0.327, 19: 0.330, 20: 0.334},
      // Ajoutez les autres âges...
    };

    List<TarifProduit> tarifs = [];
    
    // Ajouter les tarifs pour periodicite 'unique'
    for (var ageEntry in tauxUnique.entries) {
      int age = ageEntry.key;
      for (var dureeEntry in ageEntry.value.entries) {
        int duree = dureeEntry.key;
        double prime = dureeEntry.value;
        tarifs.add(TarifProduit(
          produitId: produitId,
          dureeContrat: duree,
          periodicite: 'unique',
          prime: prime,
          age: age,
          categorie: 'taux_unique',
        ));
      }
    }

    // Ajouter les tarifs pour periodicite 'annuel'
    for (var ageEntry in tauxAnnuel.entries) {
      int age = ageEntry.key;
      for (var dureeEntry in ageEntry.value.entries) {
        int duree = dureeEntry.key;
        double prime = dureeEntry.value;
        tarifs.add(TarifProduit(
          produitId: produitId,
          dureeContrat: duree,
          periodicite: 'annuel',
          prime: prime,
          age: age,
          categorie: 'taux_annuel',
        ));
      }
    }

    if (tarifs.isNotEmpty) {
      await _dbService.insertTarifsBatch(tarifs);
    }
  }

  /// Migrer les données CORIS RETRAITE
  Future<void> migrateRetraiteData() async {
    Produit? produit = await _dbService.getProduitByLibelle('CORIS RETRAITE');
    int produitId;
    
    if (produit == null) {
      produitId = await _dbService.insertProduit(Produit(libelle: 'CORIS RETRAITE'));
    } else {
      produitId = produit.id!;
    }

    await _dbService.deleteAllTarifsByProduit(produitId);

    // NOUVELLES DONNÉES: Capital à terme pour une prime de référence
    // Prime ref: mensuel 10k, trimestriel 30k, semestriel 60k, annuel 120k
    final Map<int, Map<String, double>> capitalValues = {
      5: {'mensuel': 605463.405379, 'trimestriel': 615056.504123, 'semestriel': 620331.447928, 'annuel': 625666.388106},
      6: {'mensuel': 739294.364577, 'trimestriel': 752266.795228, 'semestriel': 758213.774878, 'annuel': 764734.523010},
      7: {'mensuel': 877714.810967, 'trimestriel': 891453.723199, 'semestriel': 898104.646416, 'annuel': 908670.042636},
      8: {'mensuel': 1020882.065727, 'trimestriel': 1038327.916972, 'semestriel': 1045708.931812, 'annuel': 1057643.305449},
      9: {'mensuel': 1168958.840396, 'trimestriel': 1190342.707527, 'semestriel': 1190479.470698, 'annuel': 1211830.632461},
      10: {'mensuel': 1322113.421481, 'trimestriel': 1344587.648202, 'semestriel': 1356596.978444, 'annuel': 1371414.515917},
      11: {'mensuel': 1480519.861382, 'trimestriel': 1507300.829349, 'semestriel': 1520248.598961, 'annuel': 1536583.835295},
      12: {'mensuel': 1644358.175855, 'trimestriel': 1675729.671837, 'semestriel': 1689628.026197, 'annuel': 1707534.080851},
      13: {'mensuel': 1813844.548229, 'trimestriel': 1846605.003713, 'semestriel': 1861472.384183, 'annuel': 1880974.450438},
      14: {'mensuel': 1989081.640624, 'trimestriel': 2026309.492304, 'semestriel': 2042794.643842, 'annuel': 2063978.367524},
      15: {'mensuel': 2170358.312385, 'trimestriel': 2213524.637995, 'semestriel': 2230463.182648, 'annuel': 2253387.421708},
      16: {'mensuel': 2361663.347047, 'trimestriel': 2402847.877909, 'semestriel': 2424700.120313, 'annuel': 2449425.792789},
      17: {'mensuel': 2559654.057923, 'trimestriel': 2602620.867097, 'semestriel': 2625735.350796, 'annuel': 2652329.506857},
      18: {'mensuel': 2764594.793679, 'trimestriel': 2809385.910906, 'semestriel': 2833806.814345, 'annuel': 2862326.710918},
      19: {'mensuel': 2976698.105187, 'trimestriel': 3019148.619548, 'semestriel': 3044903.438595, 'annuel': 3079677.957121},
      20: {'mensuel': 3196225.032957, 'trimestriel': 3240492.134693, 'semestriel': 3267645.786918, 'annuel': 3304636.466941},
      21: {'mensuel': 3423435.402467, 'trimestriel': 3469582.672868, 'semestriel': 3498184.113972, 'annuel': 3537468.588654},
      22: {'mensuel': 3658598.135282, 'trimestriel': 3701991.400963, 'semestriel': 3736791.284233, 'annuel': 3778449.797473},
      23: {'mensuel': 3901991.563746, 'trimestriel': 3947234.413457, 'semestriel': 3983749.705453, 'annuel': 4027865.351705},
      24: {'mensuel': 4153903.762206, 'trimestriel': 4201060.933389, 'semestriel': 4239351.671416, 'annuel': 4286010.450336},
      25: {'mensuel': 4414632.887612, 'trimestriel': 4458560.426312, 'semestriel': 4498666.347671, 'annuel': 4547912.261262},
      26: {'mensuel': 4684487.532408, 'trimestriel': 4730283.355211, 'semestriel': 4772290.396112, 'annuel': 4824259.001727},
      27: {'mensuel': 4963787.683771, 'trimestriel': 5011516.586104, 'semestriel': 5055491.266247, 'annuel': 5110277.878109},
      28: {'mensuel': 5252862.131642, 'trimestriel': 5296815.505562, 'semestriel': 5348604.207638, 'annuel': 5406307.415163},
      29: {'mensuel': 5552054.799978, 'trimestriel': 5597877.362131, 'semestriel': 5651976.081074, 'annuel': 5712697.986015},
      30: {'mensuel': 5861719.211707, 'trimestriel': 5909476.383267, 'semestriel': 5965965.970183, 'annuel': 6029812.226846},
      31: {'mensuel': 6182221.877845, 'trimestriel': 6225575.781317, 'semestriel': 6284512.371581, 'annuel': 6358025.466106},
      32: {'mensuel': 6513942.137299, 'trimestriel': 6559144.247123, 'semestriel': 6620641.030858, 'annuel': 6697726.168741},
      33: {'mensuel': 6857272.605833, 'trimestriel': 6904387.609234, 'semestriel': 6968534.193210, 'annuel': 7049316.395967},
      34: {'mensuel': 7212619.840766, 'trimestriel': 7264612.498187, 'semestriel': 7328603.616244, 'annuel': 7413212.281147},
      35: {'mensuel': 7580403.821922, 'trimestriel': 7624197.249084, 'semestriel': 7701275.469085, 'annuel': 7789844.522308},
      36: {'mensuel': 7961060.449418, 'trimestriel': 8006717.466263, 'semestriel': 8086990.836775, 'annuel': 8179658.891909},
      37: {'mensuel': 8355040.058877, 'trimestriel': 8394751.786861, 'semestriel': 8478298.278308, 'annuel': 8575140.790787},
      38: {'mensuel': 8762808.954867, 'trimestriel': 8804241.412862, 'semestriel': 8891209.444321, 'annuel': 8992440.529785},
      39: {'mensuel': 9184849.761809, 'trimestriel': 9228063.175773, 'semestriel': 9318572.501144, 'annuel': 9424345.759649},
      40: {'mensuel': 9621661.997201, 'trimestriel': 9657988.540329, 'semestriel': 9760893.264956, 'annuel': 9871367.672557},
      41: {'mensuel': 10073762.660832, 'trimestriel': 10111691.452702, 'semestriel': 10218695.255501, 'annuel': 10334035.352417},
      42: {'mensuel': 10541686.847690, 'trimestriel': 10581273.967007, 'semestriel': 10692520.315715, 'annuel': 10812896.401073},
      43: {'mensuel': 11025988.381088, 'trimestriel': 11057612.584807, 'semestriel': 11173208.346138, 'annuel': 11308517.586431},
      44: {'mensuel': 11527240.468155, 'trimestriel': 11560302.338736, 'semestriel': 11680441.364525, 'annuel': 11821485.513277},
      45: {'mensuel': 12046036.378270, 'trimestriel': 12080582.334053, 'semestriel': 12205427.538555, 'annuel': 12352407.317562},
      46: {'mensuel': 12582990.145238, 'trimestriel': 12619080.006705, 'semestriel': 12748788.228676, 'annuel': 12901911.384998},
      47: {'mensuel': 13138737.294051, 'trimestriel': 13176421.181466, 'semestriel': 13311166.542952, 'annuel': 13470648.094793},
      48: {'mensuel': 13713935.593071, 'trimestriel': 13753269.236278, 'semestriel': 13893228.098227, 'annuel': 14059290.589432},
      49: {'mensuel': 14309265.832568, 'trimestriel': 14350306.973009, 'semestriel': 14483712.331354, 'annuel': 14668483.327573},
      50: {'mensuel': 14925432.630426, 'trimestriel': 14968241.030525, 'semestriel': 15106812.989223, 'annuel': 15286630.055359},
    };

    List<TarifProduit> tarifs = [];
    for (var dureeEntry in capitalValues.entries) {
      int duree = dureeEntry.key;
      for (var periodiciteEntry in dureeEntry.value.entries) {
        String periodicite = periodiciteEntry.key;
        double capitalForRefPrime = periodiciteEntry.value;
        
        tarifs.add(TarifProduit(
          produitId: produitId,
          dureeContrat: duree,
          periodicite: periodicite,
          prime: capitalForRefPrime, // Stocker le capital à terme pour prime de référence
          age: 0, // Pour RETRAITE, l'âge n'est pas utilisé dans ce format
        ));
      }
    }

    if (tarifs.isNotEmpty) {
      await _dbService.insertTarifsBatch(tarifs);
    }
  }

  /// Migrer les données CORIS SOLIDARITÉ
  Future<void> migrateSolidariteData() async {
    Produit? produit = await _dbService.getProduitByLibelle('CORIS SOLIDARITÉ');
    int produitId;
    
    if (produit == null) {
      produitId = await _dbService.insertProduit(Produit(libelle: 'CORIS SOLIDARITÉ'));
    } else {
      produitId = produit.id!;
    }

    await _dbService.deleteAllTarifsByProduit(produitId);

    // Données CORIS SOLIDARITÉ (capital et périodicité)
    final Map<int, Map<String, double>> primeTotaleFamilleBase = {
      500000: {'mensuel': 2699, 'trimestriel': 8019, 'semestriel': 15882, 'annuelle': 31141},
      1000000: {'mensuel': 5398, 'trimestriel': 16038, 'semestriel': 31764, 'annuelle': 62283},
      1500000: {'mensuel': 8097, 'trimestriel': 24057, 'semestriel': 47646, 'annuelle': 93424},
      2000000: {'mensuel': 10796, 'trimestriel': 32076, 'semestriel': 63529, 'annuelle': 124566},
    };

    List<TarifProduit> tarifs = [];
    for (var capitalEntry in primeTotaleFamilleBase.entries) {
      int capital = capitalEntry.key;
      for (var periodiciteEntry in capitalEntry.value.entries) {
        String periodicite = periodiciteEntry.key;
        if (periodicite == 'annuelle') periodicite = 'annuel';
        double prime = periodiciteEntry.value;
        
        tarifs.add(TarifProduit(
          produitId: produitId,
          capital: capital.toDouble(),
          periodicite: periodicite,
          prime: prime,
          age: 0, // Pas d'âge pour SOLIDARITÉ
        ));
      }
    }

    if (tarifs.isNotEmpty) {
      await _dbService.insertTarifsBatch(tarifs);
    }
  }

  /// Migrer les données CORIS ÉTUDE
  Future<void> migrateEtudeData() async {
    Produit? produit = await _dbService.getProduitByLibelle('CORIS ÉTUDE');
    int produitId;
    
    if (produit == null) {
      produitId = await _dbService.insertProduit(Produit(libelle: 'CORIS ÉTUDE'));
    } else {
      produitId = produit.id!;
    }

    await _dbService.deleteAllTarifsByProduit(produitId);

    // Données CORIS ÉTUDE (rentes fixes)
    final Map<int, Map<int, double>> tarifRenteFixe = {
      18: {60: 754, 72: 623, 84: 530, 96: 460, 108: 406, 120: 362, 132: 327, 144: 298, 156: 273, 168: 252, 180: 234, 192: 219, 204: 205, 216: 193, 228: 182, 240: 173},
      // Ajoutez les autres âges...
    };

    List<TarifProduit> tarifs = [];
    for (var ageEntry in tarifRenteFixe.entries) {
      int age = ageEntry.key;
      for (var dureeEntry in ageEntry.value.entries) {
        int duree = dureeEntry.key;
        double prime = dureeEntry.value;
        
        tarifs.add(TarifProduit(
          produitId: produitId,
          dureeContrat: duree,
          periodicite: 'mensuel',
          prime: prime,
          age: age,
          categorie: 'rente_fixe',
        ));
      }
    }

    if (tarifs.isNotEmpty) {
      await _dbService.insertTarifsBatch(tarifs);
    }
  }
}















