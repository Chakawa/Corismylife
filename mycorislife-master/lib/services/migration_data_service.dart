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

    // Les données de retraite sont par durée (années) et périodicité
    final Map<int, Map<String, int>> premiumValues = {
      5: {'mensuel': 17386, 'trimestriel': 51343, 'semestriel': 101813, 'annuel': 201890},
      6: {'mensuel': 14238, 'trimestriel': 41979, 'semestriel': 83298, 'annuel': 165176},
      // ... ajoutez toutes les durées
      50: {'mensuel': 1234, 'trimestriel': 3456, 'semestriel': 6789, 'annuel': 12345}, // Exemple
    };

    List<TarifProduit> tarifs = [];
    for (var dureeEntry in premiumValues.entries) {
      int duree = dureeEntry.key;
      for (var periodiciteEntry in dureeEntry.value.entries) {
        String periodicite = periodiciteEntry.key;
        int prime = periodiciteEntry.value;
        
        tarifs.add(TarifProduit(
          produitId: produitId,
          dureeContrat: duree,
          periodicite: periodicite,
          prime: prime.toDouble(),
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












