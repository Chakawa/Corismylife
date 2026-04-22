import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/produit_model.dart';
import '../models/tarif_produit_model.dart';

/// ==========================================
/// SERVICE DE BASE DE DONNÉES LOCALE (SQLITE)
/// ==========================================
/// Ce service gère toutes les opérations sur la base de données SQLite locale.
///
/// La base de données locale sert de cache pour :
/// - Les produits (CORIS SÉRÉNITÉ, RETRAITE, etc.)
/// - Les tarifs associés à chaque produit
///
/// Avantages :
/// - Permet de fonctionner sans Internet (mode offline)
/// - Améliore les performances (données locales = accès rapide)
/// - Synchronisable avec le serveur quand Internet est disponible
///
/// Structure de la base :
/// - Table 'produit' : contient les produits (id, libelle)
/// - Table 'tarif_produit' : contient les tarifs (produit_id, age, duree, periodicite, prime, capital, categorie)
///
/// Relations :
/// - tarif_produit.produit_id → produit.id (clé étrangère avec CASCADE DELETE)
class DatabaseService {
  // Singleton : une seule instance de DatabaseService dans toute l'application
  static final DatabaseService instance = DatabaseService._init();
  // Instance de la base de données (lazy loading)
  static Database? _database;
  // Constructeur privé pour forcer l'utilisation du singleton
  DatabaseService._init();

  /// ==========================================
  /// OBTENIR L'INSTANCE DE LA BASE DE DONNÉES
  /// ==========================================
  /// Retourne l'instance de la base de données SQLite.
  /// Si la base n'existe pas encore, elle est créée automatiquement.
  ///
  /// Utilise le pattern Singleton pour garantir une seule instance.
  ///
  /// @returns L'instance Database pour effectuer des requêtes SQL
  Future<Database> get database async {
    // Si la base existe déjà, la retourner directement
    if (_database != null) return _database!;
    // Sinon, initialiser la base de données
    _database = await _initDB('mycorislife.db');
    return _database!;
  }

  /// ==========================================
  /// INITIALISER LA BASE DE DONNÉES
  /// ==========================================
  /// Crée ou ouvre la base de données SQLite avec le nom de fichier spécifié.
  ///
  /// @param filePath: Le nom du fichier de base de données (ex: 'mycorislife.db')
  ///
  /// @returns L'instance Database ouverte
  ///
  /// Gère aussi les migrations de schéma via onUpgrade si la version change.
  Future<Database> _initDB(String filePath) async {
    // Obtenir le chemin du répertoire des bases de données de l'application
    final dbPath = await getDatabasesPath();
    // Construire le chemin complet vers le fichier de base de données
    final path = join(dbPath, filePath);
    // Ouvrir la base de données avec gestion des versions
    return await openDatabase(
      path,
      version:
          2, // Version actuelle de la base (augmentée pour la migration de 'age' nullable)
      onCreate: _createDB, // Fonction appelée lors de la première création
      onUpgrade:
          _onUpgrade, // Fonction appelée lors d'une mise à jour de version
    );
  }

  /// ==========================================
  /// CRÉER LE SCHÉMA DE LA BASE DE DONNÉES
  /// ==========================================
  /// Cette fonction est appelée lors de la première création de la base de données.
  /// Elle crée toutes les tables et index nécessaires.
  ///
  /// Tables créées :
  /// 1. 'produit' : Stocke les produits (CORIS SÉRÉNITÉ, RETRAITE, etc.)
  ///    - id : Identifiant unique auto-incrémenté
  ///    - libelle : Nom du produit (UNIQUE pour éviter les doublons)
  ///    - created_at / updated_at : Horodatage automatique
  ///
  /// 2. 'tarif_produit' : Stocke les tarifs de chaque produit
  ///    - id : Identifiant unique auto-incrémenté
  ///    - produit_id : Référence vers produit.id (clé étrangère)
  ///    - duree_contrat : Durée en mois ou années
  ///    - periodicite : 'mensuel', 'trimestriel', 'semestriel', 'annuel'
  ///    - prime : Montant de la prime
  ///    - capital : Montant du capital (pour certains produits)
  ///    - age : Âge de l'assuré (NULLABLE car RETRAITE et SOLIDARITÉ n'utilisent pas l'âge)
  ///    - categorie : Catégorie du tarif (pour SOLIDARITÉ : 'famille_base', 'avec_ascendant', etc.)
  ///
  /// Index créés pour améliorer les performances des requêtes :
  /// - idx_tarif_produit_id : Accélère les recherches par produit_id
  /// - idx_tarif_age : Accélère les recherches par âge
  /// - idx_tarif_periodicite : Accélère les recherches par périodicité
  /// - idx_tarif_duree : Accélère les recherches par durée
  /// - idx_tarif_produit_age_duree : Index composite pour les recherches combinées
  ///
  /// @param db: L'instance Database où créer les tables
  /// @param version: La version de la base (non utilisée dans onCreate)
  Future<void> _createDB(Database db, int version) async {
    // Créer la table 'produit' pour stocker les produits
    await db.execute('''
      CREATE TABLE produit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL UNIQUE,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    // Créer la table 'tarif_produit' pour stocker les tarifs
    // Note : age est nullable car RETRAITE et SOLIDARITÉ n'utilisent pas l'âge
    await db.execute('''
      CREATE TABLE tarif_produit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produit_id INTEGER NOT NULL,
        duree_contrat INTEGER,
        periodicite TEXT NOT NULL,
        prime REAL,
        capital REAL,
        age INTEGER, -- NULLABLE car RETRAITE et SOLIDARITÉ n'utilisent pas l'âge
        categorie TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (produit_id) REFERENCES produit(id) ON DELETE CASCADE
      )
    ''');
    // Créer des index pour améliorer les performances des requêtes de recherche
    // Index sur produit_id : accélère les recherches de tarifs par produit
    await db.execute('''
      CREATE INDEX idx_tarif_produit_id ON tarif_produit(produit_id)
    ''');
    // Index sur age : accélère les recherches par âge
    await db.execute('''
      CREATE INDEX idx_tarif_age ON tarif_produit(age)
    ''');
    // Index sur periodicite : accélère les recherches par périodicité
    await db.execute('''
      CREATE INDEX idx_tarif_periodicite ON tarif_produit(periodicite)
    ''');
    // Index sur duree_contrat : accélère les recherches par durée
    await db.execute('''
      CREATE INDEX idx_tarif_duree ON tarif_produit(duree_contrat)
    ''');
    // Index composite : accélère les recherches combinant produit_id, age et duree_contrat
    // Utile pour les requêtes qui filtrent par ces 3 critères simultanément
    await db.execute('''
      CREATE INDEX idx_tarif_produit_age_duree ON tarif_produit(produit_id, age, duree_contrat)
    ''');
  }

  /// ==========================================
  /// MIGRER LE SCHÉMA DE LA BASE DE DONNÉES
  /// ==========================================
  /// Cette fonction est appelée lorsque la version de la base de données change.
  /// Elle permet de modifier le schéma sans perdre les données existantes.
  ///
  /// Migration actuelle (version 1 → 2) :
  /// - Rendre la colonne 'age' nullable dans 'tarif_produit'
  /// - Nécessaire car RETRAITE et SOLIDARITÉ n'utilisent pas l'âge
  ///
  /// Processus de migration :
  /// 1. Créer une nouvelle table avec le nouveau schéma (age nullable)
  /// 2. Copier toutes les données de l'ancienne table vers la nouvelle
  /// 3. Supprimer l'ancienne table
  /// 4. Renommer la nouvelle table avec l'ancien nom
  /// 5. Recréer tous les index pour maintenir les performances
  ///
  /// Note : SQLite ne supporte pas ALTER COLUMN pour modifier NULL/NOT NULL,
  /// donc on doit recréer la table complètement.
  ///
  /// @param db: L'instance Database à migrer
  /// @param oldVersion: L'ancienne version de la base
  /// @param newVersion: La nouvelle version de la base
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // SQLite ne supporte pas ALTER COLUMN, il faut recréer la table
      print('🔄 [DB] Migration vers version 2: rendre age nullable');
      // Créer une table temporaire avec le nouveau schéma
      await db.execute('''
        CREATE TABLE tarif_produit_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          produit_id INTEGER NOT NULL,
          duree_contrat INTEGER,
          periodicite TEXT NOT NULL,
          prime REAL,
          capital REAL,
          age INTEGER,
          categorie TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (produit_id) REFERENCES produit(id) ON DELETE CASCADE
        )
      ''');
      // Copier les données
      await db.execute('''
        INSERT INTO tarif_produit_new 
        (id, produit_id, duree_contrat, periodicite, prime, capital, age, categorie, created_at, updated_at)
        SELECT id, produit_id, duree_contrat, periodicite, prime, capital, age, categorie, created_at, updated_at
        FROM tarif_produit
      ''');
      // Supprimer l'ancienne table
      await db.execute('DROP TABLE tarif_produit');
      // Renommer la nouvelle table
      await db.execute('ALTER TABLE tarif_produit_new RENAME TO tarif_produit');
      // Recréer les index
      await db.execute(
          'CREATE INDEX idx_tarif_produit_id ON tarif_produit(produit_id)');
      await db.execute('CREATE INDEX idx_tarif_age ON tarif_produit(age)');
      await db.execute(
          'CREATE INDEX idx_tarif_periodicite ON tarif_produit(periodicite)');
      await db.execute(
          'CREATE INDEX idx_tarif_duree ON tarif_produit(duree_contrat)');
      await db.execute(
          'CREATE INDEX idx_tarif_produit_age_duree ON tarif_produit(produit_id, age, duree_contrat)');
      print('✅ [DB] Migration terminée: age est maintenant nullable');
    }
  }

  // ==========================================
  // OPÉRATIONS SUR LES PRODUITS
  // ==========================================

  /// ==========================================
  /// INSÉRER UN NOUVEAU PRODUIT
  /// ==========================================
  /// Ajoute un nouveau produit dans la table 'produit'.
  ///
  /// @param produit: L'objet Produit à insérer (doit contenir au minimum le libellé)
  ///
  /// @returns L'ID du produit inséré (int)
  ///
  /// Note : Le libellé doit être unique (contrainte UNIQUE dans la base)
  Future<int> insertProduit(Produit produit) async {
    final db = await database;
    return await db.insert('produit', produit.toMap());
  }

  /// ==========================================
  /// RÉCUPÉRER UN PRODUIT PAR SON ID
  /// ==========================================
  /// Recherche un produit dans la base locale par son identifiant numérique.
  ///
  /// @param id: L'identifiant du produit à rechercher
  ///
  /// @returns Le produit trouvé (Produit?) ou null si non trouvé
  Future<Produit?> getProduitById(int id) async {
    final db = await database;
    final maps = await db.query(
      'produit',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Produit.fromMap(maps.first);
    }
    return null;
  }

  /// ==========================================
  /// RÉCUPÉRER UN PRODUIT PAR SON LIBELLÉ
  /// ==========================================
  /// Recherche un produit dans la base locale par son libellé (nom).
  /// Cette fonction est utilisée pour trouver un produit par son nom
  /// (ex: "CORIS SÉRÉNITÉ", "CORIS RETRAITE").
  ///
  /// @param libelle: Le nom/libellé du produit à rechercher
  ///
  /// @returns Le produit trouvé (Produit?) ou null si non trouvé
  Future<Produit?> getProduitByLibelle(String libelle) async {
    final db = await database;
    final maps = await db.query(
      'produit',
      where: 'libelle = ?',
      whereArgs: [libelle],
    );
    if (maps.isNotEmpty) {
      return Produit.fromMap(maps.first);
    }
    return null;
  }

  /// ==========================================
  /// RÉCUPÉRER TOUS LES PRODUITS
  /// ==========================================
  /// Récupère tous les produits stockés dans la base locale,
  /// triés par ordre alphabétique de leur libellé.
  ///
  /// @returns Liste de tous les produits (List<Produit>)
  Future<List<Produit>> getAllProduits() async {
    final db = await database;
    final maps = await db.query('produit', orderBy: 'libelle');
    return maps.map((map) => Produit.fromMap(map)).toList();
  }

  Future<int> updateProduit(Produit produit) async {
    final db = await database;
    return await db.update(
      'produit',
      produit.toMap(),
      where: 'id = ?',
      whereArgs: [produit.id],
    );
  }

  Future<int> deleteProduit(int id) async {
    final db = await database;
    return await db.delete(
      'produit',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== TARIF PRODUIT ==========

  Future<int> insertTarif(TarifProduit tarif) async {
    final db = await database;
    return await db.insert('tarif_produit', tarif.toMap());
  }

  Future<int> insertTarifsBatch(List<TarifProduit> tarifs) async {
    final db = await database;
    final batch = db.batch();
    for (var tarif in tarifs) {
      batch.insert('tarif_produit', tarif.toMap());
    }

    await batch.commit(noResult: true);
    return tarifs.length;
  }

  Future<List<TarifProduit>> getTarifsByProduit(int produitId) async {
    final db = await database;
    final maps = await db.query(
      'tarif_produit',
      where: 'produit_id = ?',
      whereArgs: [produitId],
      orderBy: 'age, duree_contrat',
    );
    return maps.map((map) => TarifProduit.fromMap(map)).toList();
  }

  Future<List<TarifProduit>> getTarifsByProduitAndAge(
    int produitId,
    int age,
  ) async {
    final db = await database;
    final maps = await db.query(
      'tarif_produit',
      where: 'produit_id = ? AND age = ?',
      whereArgs: [produitId, age],
      orderBy: 'duree_contrat',
    );
    return maps.map((map) => TarifProduit.fromMap(map)).toList();
  }

  /// Récupère un tarif spécifique par ses paramètres
  /// IMPORTANT: produit_id est OBLIGATOIRE pour garantir qu'on ne mélange pas les données entre produits
  Future<TarifProduit?> getTarifByParams({
    required int
        produitId, // OBLIGATOIRE - garantit l'intégrité des données par produit
    int? age,
    required int? dureeContrat,
    required String periodicite,
    String?
        categorie, // Optionnel - pour différencier les types (ex: 'amortissable', 'decouvert', 'perte_emploi')
  }) async {
    final db = await database;
    // TOUJOURS filtrer par produit_id en premier pour éviter les mélanges entre produits
    // Utiliser LOWER() pour comparaison case-insensitive de la périodicité
    String whereClause = 'produit_id = ? AND LOWER(TRIM(periodicite)) = ?';
    List<dynamic> whereArgs = [produitId, periodicite.toLowerCase().trim()];
    // Ajouter la condition age seulement si fourni
    if (age != null) {
      whereClause += ' AND age = ?';
      whereArgs.add(age);
    } else {
      // Pour les produits sans age (RETRAITE, SOLIDARITÉ, PERte EMPLOI), chercher where age IS NULL
      whereClause += ' AND age IS NULL';
    }

    if (dureeContrat != null) {
      whereClause += ' AND duree_contrat = ?';
      whereArgs.add(dureeContrat);
    }

    // Filtrer par catégorie si spécifiée (pour FLEX EMPRUNTEUR)
    if (categorie != null) {
      whereClause += ' AND categorie = ?';
      whereArgs.add(categorie);
    }

    print(
        '🔍 [DB] getTarifByParams: whereClause="$whereClause", whereArgs=$whereArgs');
    final maps = await db.query(
      'tarif_produit',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    print('🔍 [DB] getTarifByParams: ${maps.length} résultat(s) trouvé(s)');
    if (maps.isNotEmpty) {
      final tarif = TarifProduit.fromMap(maps.first);
      print(
          '✅ [DB] Tarif trouvé: prime=${tarif.prime}, periodicite=${tarif.periodicite}, age=${tarif.age}, duree=${tarif.dureeContrat}, categorie=${tarif.categorie}');
      return tarif;
    }
    return null;
  }

  Future<List<TarifProduit>> searchTarifs({
    int? produitId,
    int? age,
    int? dureeContrat,
    String? periodicite,
    double? capital,
    String? categorie,
  }) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> args = [];
    // IMPORTANT: produit_id doit TOUJOURS être spécifié pour éviter les mélanges entre produits
    if (produitId != null) {
      conditions.add('produit_id = ?');
      args.add(produitId);
    } else {
      // Pour la sécurité, on pourrait lancer une exception
      // Mais on laisse passer pour compatibilité (à améliorer si besoin)
      print(
          '⚠️ [DB] ATTENTION: searchTarifs appelé sans produit_id - risque de mélange entre produits!');
    }

    // Gérer age null (pour RETRAITE, SOLIDARITÉ) vs age spécifique
    if (age != null) {
      conditions.add('age = ?');
      args.add(age);
    } else {
      // Si age n'est pas spécifié, on ne filtre PAS par age
      // (les produits avec age NULL seront inclus)
      // Pour les produits qui nécessitent age NULL explicitement, utiliser getTarifByParams
    }
    if (dureeContrat != null) {
      conditions.add('duree_contrat = ?');
      args.add(dureeContrat);
    }
    if (periodicite != null) {
      conditions.add('periodicite = ?');
      args.add(periodicite);
    }
    if (capital != null) {
      conditions.add('capital = ?');
      args.add(capital);
    }
    if (categorie != null) {
      conditions.add('categorie = ?');
      args.add(categorie);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final maps = await db.query(
      'tarif_produit',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'age, duree_contrat',
    );
    return maps.map((map) => TarifProduit.fromMap(map)).toList();
  }

  Future<int> updateTarif(TarifProduit tarif) async {
    final db = await database;
    return await db.update(
      'tarif_produit',
      tarif.toMap(),
      where: 'id = ?',
      whereArgs: [tarif.id],
    );
  }

  Future<int> deleteTarif(int id) async {
    final db = await database;
    return await db.delete(
      'tarif_produit',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTarifsByProduit(int produitId) async {
    final db = await database;
    return await db.delete(
      'tarif_produit',
      where: 'produit_id = ?',
      whereArgs: [produitId],
    );
  }

  Future<int> deleteAllTarifs() async {
    final db = await database;
    return await db.delete('tarif_produit');
  }

  Future<int> deleteAllProduits() async {
    final db = await database;
    return await db.delete('produit');
  }

  // Vider toutes les tables
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tarif_produit');
    await db.delete('produit');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
