import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mycorislife/services/database_service.dart';
import 'package:mycorislife/models/produit_model.dart';
import 'package:mycorislife/models/tarif_produit_model.dart';
import 'package:mycorislife/config/app_config.dart';

/// ==========================================
/// SERVICE DE SYNCHRONISATION DES PRODUITS
/// ==========================================
/// Ce service gère la synchronisation entre la base de données locale (SQLite)
/// et la base de données serveur (PostgreSQL).
///
/// Fonctionnalités principales :
/// - Synchronisation des produits et tarifs depuis le serveur
/// - Gestion du mode online/offline
/// - Cache local pour fonctionner sans Internet
/// - Détection automatique de la disponibilité du backend
///
/// Stratégie de synchronisation :
/// 1. Vérifier si le backend est disponible
/// 2. Si oui : récupérer les données depuis le serveur et les mettre en cache local
/// 3. Si non : utiliser les données du cache local (SQLite)
/// 4. Si le cache est vide : utiliser les données hardcodées (fallback)
class ProduitSyncService {
  // Instance du service de base de données locale (SQLite)
  final DatabaseService _dbService = DatabaseService.instance;
  // Mémoïsation en mémoire (TTL) pour accélérer les simulations répétées
  static final Map<String, _MemEntry<List<TarifProduit>>> _memCache = {};
  static const Duration _memTtl = Duration(minutes: 5);
  static String _makeKey(String scope, Map<String, Object?> params) {
    final entries = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$scope?${entries.map((e) => '${e.key}=${e.value ?? ''}').join('&')}';
  }

  /// ==========================================
  /// VÉRIFIER LA CONNEXION INTERNET GÉNÉRALE
  /// ==========================================
  /// Vérifie si l'appareil a une connexion Internet générale en essayant
  /// de résoudre le nom de domaine 'google.com'.
  ///
  /// Note : Cette méthode vérifie seulement l'Internet, pas la disponibilité
  /// du backend spécifique.
  ///
  /// @returns true si Internet est disponible, false sinon
  Future<bool> isConnectedToInternet() async {
    try {
      // Essayer de résoudre google.com avec un timeout court (2 secondes)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Pas de connexion Internet
      return false;
    }
  }

  /// ==========================================
  /// VÉRIFIER SI LE BACKEND EST DISPONIBLE
  /// ==========================================
  /// Vérifie si le backend spécifique de l'application est accessible
  /// en faisant une requête vers l'endpoint /produits.
  ///
  /// Cette méthode est plus précise que isConnectedToInternet() car elle
  /// vérifie non seulement Internet, mais aussi la disponibilité du serveur.
  ///
  /// @returns true si le backend répond avec succès (code 200), false sinon
  Future<bool> isBackendAvailable() async {
    try {
      print('   🔍 Test connexion backend: ${AppConfig.baseUrl}/produits');
      // Faire une requête GET vers l'endpoint produits avec timeout court (3 secondes)
      // Ce timeout court permet de détecter rapidement si le serveur n'est pas accessible
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/produits')).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('   ⏱️  Timeout: Le serveur ne répond pas dans les 3 secondes');
          throw Exception('Timeout');
        },
      );
      // Le backend est disponible si la réponse est 200 (OK)
      final isAvailable = response.statusCode == 200;
      if (isAvailable) {
        print('   ✅ Backend répond avec succès (code: ${response.statusCode})');
      } else {
        print(
            '   ❌ Backend répond mais avec erreur (code: ${response.statusCode})');
      }
      return isAvailable;
    } on SocketException catch (e) {
      print('   ❌ SocketException: ${e.message}');
      print('   → Serveur inaccessible ou pas d\'Internet');
      return false;
    } catch (e) {
      print('   ❌ Erreur lors de la vérification backend: ${e.toString()}');
      // Backend non disponible (pas de connexion, serveur éteint, timeout, etc.)
      return false;
    }
  }

  /// ==========================================
  /// RÉCUPÉRER LES PRODUITS DEPUIS L'API
  /// ==========================================
  /// Récupère la liste de tous les produits disponibles depuis le serveur.
  ///
  /// Cette fonction fait une requête GET vers l'endpoint /produits du backend
  /// et retourne une liste d'objets Produit.
  ///
  /// @returns Liste des produits (List<Produit>) ou liste vide en cas d'erreur
  ///
  /// @throws Exception si :
  ///   - Pas de connexion Internet
  ///   - Timeout de la requête (serveur trop lent ou inaccessible)
  ///   - Erreur serveur
  Future<List<Produit>> fetchProduitsFromAPI() async {
    try {
      print(
          '🔄 [SYNC] Récupération produits depuis API: ${AppConfig.baseUrl}/produits');
      // Faire la requête GET avec timeout réduit à 5 secondes pour détecter rapidement l'absence de serveur
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/produits')).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception(
              'Timeout: Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet.');
        },
      );
      print('📡 [SYNC] Réponse API produits: ${response.statusCode}');
      // Vérifier si la requête a réussi (code 200)
      if (response.statusCode == 200) {
        // Décoder la réponse JSON
        final data = json.decode(response.body);
        // Vérifier si le serveur a retourné un succès
        if (data['success'] == true) {
          // Extraire la liste des produits depuis data['data']
          final List<dynamic> produitsData = data['data'];
          print('✅ [SYNC] ${produitsData.length} produits reçus de l\'API');
          // Convertir chaque Map en objet Produit et retourner la liste
          return produitsData.map((p) => Produit.fromMap(p)).toList();
        }
      }

      // Si on arrive ici, la requête n'a pas réussi
      print('⚠️ [SYNC] Aucun produit reçu (code: ${response.statusCode})');
      return [];
    } on SocketException {
      // Erreur de connexion réseau
      print('❌ [SYNC] Erreur réseau: Impossible de se connecter au serveur');
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } on HttpException {
      // Erreur HTTP
      print('❌ [SYNC] Erreur HTTP lors de la récupération des produits');
      throw Exception(
          'Erreur de communication avec le serveur. Veuillez réessayer.');
    } catch (e) {
      // Autre erreur (timeout, format, etc.)
      print('❌ [SYNC] Erreur lors de la récupération des produits: $e');
      // Si c'est déjà une Exception avec message, la relancer
      if (e is Exception && e.toString().contains('Timeout')) {
        rethrow;
      }
      throw Exception(
          'Erreur lors de la récupération des produits: ${e.toString()}');
    }
  }

  /// ==========================================
  /// RÉCUPÉRER LES TARIFS D'UN PRODUIT DEPUIS L'API
  /// ==========================================
  /// Récupère tous les tarifs associés à un produit spécifique depuis le serveur.
  ///
  /// @param produitId: L'ID du produit dont on veut récupérer les tarifs.
  ///                   Si null, récupère tous les tarifs de tous les produits.
  ///
  /// @returns Liste des tarifs (List<TarifProduit>) ou liste vide en cas d'erreur
  ///
  /// @throws Exception si :
  ///   - Pas de connexion Internet
  ///   - Timeout de la requête (serveur trop lent ou inaccessible)
  ///   - Erreur serveur
  Future<List<TarifProduit>> fetchTarifsFromAPI(int? produitId) async {
    try {
      // Construire l'URL de l'endpoint avec le paramètre produit_id si fourni
      String url = '${AppConfig.baseUrl}/produits/tarifs';
      if (produitId != null) {
        url += '?produit_id=$produitId';
      }

      print('🔄 [SYNC] Récupération tarifs depuis API: $url');
      // Faire la requête GET avec timeout réduit à 8 secondes
      // (légèrement plus long que pour les produits car il peut y avoir beaucoup de tarifs)
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception(
              'Timeout: La récupération des tarifs prend trop de temps. Vérifiez votre connexion Internet.');
        },
      );
      print('📡 [SYNC] Réponse API tarifs: ${response.statusCode}');
      // Vérifier si la requête a réussi (code 200)
      if (response.statusCode == 200) {
        // Décoder la réponse JSON
        final data = json.decode(response.body);
        // Vérifier si le serveur a retourné un succès
        if (data['success'] == true) {
          // Extraire la liste des tarifs depuis data['data']
          final List<dynamic> tarifsData = data['data'];
          print(
              '✅ [SYNC] ${tarifsData.length} tarifs reçus pour produit_id=$produitId');
          // Convertir chaque Map en objet TarifProduit et retourner la liste
          return tarifsData.map((t) => TarifProduit.fromMap(t)).toList();
        }
      }

      // Si on arrive ici, la requête n'a pas réussi
      print('⚠️ [SYNC] Aucun tarif reçu (code: ${response.statusCode})');
      return [];
    } on SocketException {
      // Erreur de connexion réseau
      print('❌ [SYNC] Erreur réseau: Impossible de se connecter au serveur');
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } on HttpException {
      // Erreur HTTP
      print('❌ [SYNC] Erreur HTTP lors de la récupération des tarifs');
      throw Exception(
          'Erreur de communication avec le serveur. Veuillez réessayer.');
    } catch (e) {
      // Autre erreur (timeout, format, etc.)
      print('❌ [SYNC] Erreur lors de la récupération des tarifs: $e');
      // Si c'est déjà une Exception avec message, la relancer
      if (e is Exception && e.toString().contains('Timeout')) {
        rethrow;
      }
      throw Exception(
          'Erreur lors de la récupération des tarifs: ${e.toString()}');
    }
  }

  /// ==========================================
  /// SYNCHRONISER TOUS LES PRODUITS ET TARIFS
  /// ==========================================
  /// Cette fonction synchronise tous les produits et leurs tarifs depuis le serveur
  /// vers la base de données locale (SQLite).
  ///
  /// Processus de synchronisation :
  /// 1. Vérifier la connexion Internet
  /// 2. Récupérer tous les produits depuis le serveur
  /// 3. Pour chaque produit :
  ///    a. Vérifier si le produit existe déjà localement (par libellé)
  ///    b. Si oui : utiliser l'ID local existant
  ///    c. Si non : créer le produit localement et obtenir son ID local
  ///    d. Récupérer tous les tarifs du produit depuis le serveur (en utilisant l'ID serveur)
  ///    e. Supprimer les anciens tarifs locaux du produit
  ///    f. Insérer les nouveaux tarifs en batch (pour performance)
  ///
  /// @returns true si la synchronisation a réussi, false sinon
  ///
  /// @throws Exception si :
  ///   - Pas de connexion Internet
  ///   - Erreur lors de la récupération des produits ou tarifs
  ///   - Erreur lors de l'insertion en base locale
  Future<bool> syncProduits() async {
    print('🚀 [SYNC] Démarrage synchronisation...');
    // Vérifier d'abord la connexion Internet
    if (!await isConnectedToInternet()) {
      print(
          '⚠️ [SYNC] Pas de connexion Internet, utilisation des données locales');
      throw Exception(
          'Synchronisation impossible. Vérifiez votre connexion Internet.');
    }

    try {
      // Étape 1: Récupérer tous les produits depuis le serveur
      final produitsAPI = await fetchProduitsFromAPI();
      // Étape 2: Pour chaque produit, récupérer et sauvegarder ses tarifs
      for (var produit in produitsAPI) {
        print('📦 [SYNC] Traitement produit: ${produit.libelle}');
        // Vérifier si le produit existe déjà dans la base locale
        Produit? existingProduit =
            await _dbService.getProduitByLibelle(produit.libelle);
        int produitIdLocal;
        if (existingProduit != null) {
          // Le produit existe déjà, utiliser son ID local
          produitIdLocal = existingProduit.id!;
          print('   ✅ Produit existe déjà localement avec id: $produitIdLocal');
        } else {
          // Le produit n'existe pas, le créer dans la base locale
          produitIdLocal = await _dbService.insertProduit(produit);
          print('   ✅ Produit créé localement avec id: $produitIdLocal');
        }

        // IMPORTANT: Utiliser l'ID du serveur (produit.id) pour récupérer les tarifs,
        // car l'API attend l'ID serveur, pas l'ID local
        final tarifsAPI =
            await fetchTarifsFromAPI(produit.id); // produit.id = ID serveur
        // Supprimer les anciens tarifs locaux du produit avant d'insérer les nouveaux
        // Cela garantit que les données sont toujours à jour
        await _dbService.deleteAllTarifsByProduit(produitIdLocal);
        print('   🗑️  Anciens tarifs supprimés');
        if (tarifsAPI.isNotEmpty) {
          // Préparer tous les tarifs avec l'ID local (produitIdLocal) pour l'insertion
          // car dans la base locale, on doit utiliser l'ID local, pas l'ID serveur
          final tarifsToInsert = tarifsAPI
              .map((tarif) => TarifProduit(
                    produitId:
                        produitIdLocal, // Utiliser l'ID local pour l'insertion locale
                    dureeContrat: tarif.dureeContrat,
                    periodicite: tarif.periodicite,
                    prime: tarif.prime,
                    capital: tarif.capital,
                    age: tarif.age,
                    categorie: tarif.categorie,
                  ))
              .toList();
          // Insérer tous les tarifs en batch pour une meilleure performance
          // (plus rapide que d'insérer un par un)
          await _dbService.insertTarifsBatch(tarifsToInsert);
          print('   ✅ ${tarifsAPI.length} tarifs insérés localement (batch)');
          // Debug: Afficher un échantillon pour vérifier que les données sont correctes
          if (tarifsToInsert.isNotEmpty) {
            final sample = tarifsToInsert.first;
            print(
                '   🔍 [DEBUG] Échantillon tarif inséré: produitId=${sample.produitId}, age=${sample.age}, duree=${sample.dureeContrat}, period=${sample.periodicite}, prime=${sample.prime}');
          }
        } else {
          print('   ⚠️  Aucun tarif à insérer');
        }
      }

      print('✅ [SYNC] Synchronisation terminée avec succès !');
      return true;
    } on SocketException {
      print('❌ [SYNC] Erreur réseau lors de la synchronisation');
      throw Exception(
          'Erreur réseau lors de la synchronisation. Vérifiez votre connexion Internet.');
    } catch (e) {
      print('❌ [SYNC] Erreur lors de la synchronisation: $e');
      // Si c'est déjà une Exception avec message clair, la relancer
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors de la synchronisation: ${e.toString()}');
    }
  }

  /// ==========================================
  /// RÉCUPÉRER PLUSIEURS TARIFS AVEC FILTRES
  /// ==========================================
  /// Récupère une liste de tarifs selon différents critères de filtrage.
  ///
  /// Stratégie de récupération :
  /// 1. Rechercher d'abord dans la base locale (SQLite)
  /// 2. Si le produit n'existe pas localement et qu'Internet est disponible :
  ///    - Synchroniser depuis le serveur
  ///    - Re-chercher dans la base locale
  /// 3. Rechercher les tarifs avec les filtres fournis
  ///
  /// @param produitLibelle: Le libellé du produit (ex: "CORIS SÉRÉNITÉ")
  /// @param age: L'âge pour filtrer (optionnel, null pour les produits sans âge)
  /// @param dureeContrat: La durée du contrat en mois/années (optionnel)
  /// @param periodicite: La périodicité ('mensuel', 'trimestriel', etc.) (optionnel)
  /// @param capital: Le capital pour filtrer (optionnel, pour SOLIDARITÉ)
  /// @param categorie: La catégorie pour filtrer (optionnel, pour SOLIDARITÉ)
  ///
  /// @returns Liste des tarifs correspondant aux critères
  ///
  /// IMPORTANT: Cette fonction ne retourne des données QUE si le backend est accessible.
  /// Si le backend n'est pas accessible, retourne une liste vide pour forcer l'utilisation du fallback.
  Future<List<TarifProduit>> getTarifs({
    required String produitLibelle,
    int? age,
    int? dureeContrat,
    String? periodicite,
    double? capital,
    String? categorie,
  }) async {
    // 1) Memo cache hit
    final cacheKey = _makeKey('getTarifs', {
      'produit': produitLibelle,
      'age': age ?? '',
      'duree': dureeContrat ?? '',
      'periodicite': periodicite ?? '',
      'capital': capital ?? '',
      'categorie': categorie ?? ''
    });
    final now = DateTime.now();
    final entry = _memCache[cacheKey];
    if (entry != null && entry.expiresAt.isAfter(now)) {
      return entry.value;
    }

    // 2) Try local SQLite first (fast path)
    final produit = await _dbService.getProduitByLibelle(produitLibelle);
    List<TarifProduit> locaux = [];
    if (produit != null) {
      locaux = await _dbService.searchTarifs(
        produitId: produit.id,
        age: age,
        dureeContrat: dureeContrat,
        periodicite: periodicite,
        capital: capital,
        categorie: categorie,
      );
      if (locaux.isNotEmpty) {
        _memCache[cacheKey] = _MemEntry(locaux, now.add(_memTtl));
        return locaux;
      }
    }

    // 3) If nothing local, try syncing quickly if backend is reachable
    if (await isBackendAvailable()) {
      try {
        await syncProduits();
        final p2 = await _dbService.getProduitByLibelle(produitLibelle);
        if (p2 != null) {
          final synced = await _dbService.searchTarifs(
            produitId: p2.id,
            age: age,
            dureeContrat: dureeContrat,
            periodicite: periodicite,
            capital: capital,
            categorie: categorie,
          );
          _memCache[cacheKey] = _MemEntry(synced, now.add(_memTtl));
          return synced;
        }
      } catch (_) {}
    }

    // 4) Fallback: nothing available (UI can use hardcoded tables)
    return [];
  }

  /// ==========================================
  /// RÉCUPÉRER UN TARIF AVEC INFO SUR LA SOURCE
  /// ==========================================
  /// Récupère un tarif spécifique selon des critères précis et retourne aussi
  /// l'information indiquant si le tarif vient du serveur ou du cache local.
  ///
  /// Cette fonction est utile pour afficher à l'utilisateur la source des données
  /// utilisées (serveur ou cache local).
  ///
  /// Stratégie de récupération :
  /// 1. Vérifier si le backend est disponible
  /// 2. Rechercher le produit dans la base locale
  /// 3. Si produit non trouvé ET backend disponible : synchroniser puis re-chercher
  /// 4. Rechercher le tarif avec les critères fournis
  /// 5. Si tarif non trouvé ET backend disponible : synchroniser puis re-chercher
  /// 6. Déterminer la source des données (serveur ou cache local)
  ///
  /// @param produitLibelle: Le libellé du produit (ex: "CORIS SÉRÉNITÉ")
  /// @param age: L'âge pour filtrer (optionnel, null pour produits sans âge)
  /// @param dureeContrat: La durée du contrat (requis)
  /// @param periodicite: La périodicité (requis, ex: 'mensuel', 'annuel')
  ///
  /// @returns Map contenant :
  ///   - 'tarif': Le tarif trouvé (TarifProduit?) ou null si non trouvé
  ///   - 'isFromServer': true si les données viennent du serveur, false si du cache local
  Future<Map<String, dynamic>> getTarifWithSource({
    required String produitLibelle,
    int? age,
    required int? dureeContrat,
    required String periodicite,
    String?
        categorie, // Optionnel - pour différencier les types (ex: 'amortissable', 'decouvert', 'perte_emploi')
  }) async {
    // Memo cache
    final cacheKey = _makeKey('getTarifWithSource', {
      'produit': produitLibelle,
      'age': age ?? '',
      'duree': dureeContrat ?? '',
      'periodicite': periodicite,
      'categorie': categorie ?? ''
    });
    final now = DateTime.now();
    final memo = _memCache[cacheKey];
    if (memo != null && memo.expiresAt.isAfter(now) && memo.value.isNotEmpty) {
      return {'tarif': memo.value.first, 'isFromServer': false};
    }

    // Try local DB first
    final produit = await _dbService.getProduitByLibelle(produitLibelle);
    if (produit != null) {
      final tarifLocal = await _dbService.getTarifByParams(
        produitId: produit.id!,
        age: age,
        dureeContrat: dureeContrat,
        periodicite: periodicite,
        categorie: categorie,
      );
      if (tarifLocal != null) {
        _memCache[cacheKey] = _MemEntry([tarifLocal], now.add(_memTtl));
        return {'tarif': tarifLocal, 'isFromServer': false};
      }
    }

    // If not local, attempt sync once
    if (await isBackendAvailable()) {
      try {
        await syncProduits();
        final p2 = await _dbService.getProduitByLibelle(produitLibelle);
        if (p2 != null) {
          final tarifServer = await _dbService.getTarifByParams(
            produitId: p2.id!,
            age: age,
            dureeContrat: dureeContrat,
            periodicite: periodicite,
            categorie: categorie,
          );
          if (tarifServer != null) {
            _memCache[cacheKey] = _MemEntry([tarifServer], now.add(_memTtl));
            return {'tarif': tarifServer, 'isFromServer': true};
          }
        }
      } catch (_) {}
    }

    return {'tarif': null, 'isFromServer': false};
  }

  /// ==========================================
  /// RÉCUPÉRER UN TARIF SPÉCIFIQUE (VERSION SIMPLIFIÉE)
  /// ==========================================
  /// Version simplifiée de getTarifWithSource() qui retourne seulement le tarif,
  /// sans information sur la source.
  ///
  /// Cette fonction est maintenue pour compatibilité avec le code existant.
  /// Pour une meilleure traçabilité, utilisez getTarifWithSource() à la place.
  ///
  /// @param produitLibelle: Le libellé du produit (ex: "CORIS SÉRÉNITÉ")
  /// @param age: L'âge pour filtrer (optionnel)
  /// @param dureeContrat: La durée du contrat (requis)
  /// @param periodicite: La périodicité (requis)
  ///
  /// @returns Le tarif trouvé (TarifProduit?) ou null si non trouvé
  Future<TarifProduit?> getTarif({
    required String produitLibelle,
    int? age,
    required int? dureeContrat,
    required String periodicite,
  }) async {
    // Utiliser getTarifWithSource et extraire seulement le tarif
    final result = await getTarifWithSource(
      produitLibelle: produitLibelle,
      age: age,
      dureeContrat: dureeContrat,
      periodicite: periodicite,
    );
    return result['tarif'] as TarifProduit?;
  }

  /// ==========================================
  /// INITIALISER LES DONNÉES OFFLINE
  /// ==========================================
  /// Vérifie si les données existent déjà en local.
  ///
  /// Cette fonction peut être utilisée pour initialiser les données par défaut
  /// si la base locale est vide et qu'aucune synchronisation n'est possible.
  ///
  /// Note : Actuellement, cette fonction ne fait que vérifier. Les données
  /// sont généralement chargées via syncProduits() ou depuis les données
  /// hardcodées dans les écrans de simulation (fallback).
  Future<void> initializeOfflineData() async {
    // Vérifier si des produits existent déjà dans la base locale
    final produits = await _dbService.getAllProduits();
    if (produits.isNotEmpty) {
      print('Les données existent déjà en local (${produits.length} produits)');
      return;
    }

    // Si aucun produit en local, les données seront chargées :
    // 1. Via synchronisation depuis le serveur (si Internet disponible)
    // 2. Ou via les données hardcodées dans les écrans de simulation (fallback)
    print('Initialisation des données offline...');
  }
}

/// Petite structure de cache mémoire avec TTL
class _MemEntry<T> {
  final T value;
  final DateTime expiresAt;
  _MemEntry(this.value, this.expiresAt);
}
