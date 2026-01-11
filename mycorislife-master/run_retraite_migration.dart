import 'package:mycorislife/services/migration_data_service.dart';
import 'package:mycorislife/services/database_service.dart';

/// Script pour exécuter la migration des données CORIS RETRAITE
/// avec les nouvelles valeurs de capital à terme
void main() async {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║  MIGRATION CORIS RETRAITE - Nouvelles valeurs de capital  ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  try {
    // Initialiser la base de données
    print('📊 Initialisation de la base de données...');
    await DatabaseService.instance.database;
    print('✅ Base de données initialisée\n');

    // Créer le service de migration
    final migrationService = MigrationDataService();

    // Exécuter la migration CORIS RETRAITE
    print('🔄 Migration des données CORIS RETRAITE en cours...');
    print('   → Suppression des anciennes valeurs');
    print('   → Insertion des nouvelles valeurs de capital à terme');
    print('   → Durées: 5 à 50 ans');
    print('   → Périodicités: mensuel, trimestriel, semestriel, annuel\n');

    await migrationService.migrateRetraiteData();

    print('✅ Migration CORIS RETRAITE terminée avec succès!\n');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║  MIGRATION RÉUSSIE                                         ║');
    print('╚════════════════════════════════════════════════════════════╝');
    print('\n📝 Nouvelles données:');
    print('   - Capital à terme pour prime de référence');
    print('   - Prime ref: mensuel 10k, trimestriel 30k, semestriel 60k, annuel 120k');
    print('   - Formule: Prime = (Capital × PrimeRef) / CapitalForRef');
    print('   - Formule: Capital = (Prime × CapitalForRef) / PrimeRef\n');
  } catch (e) {
    print('\n❌ ERREUR lors de la migration:');
    print('   $e\n');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║  MIGRATION ÉCHOUÉE                                         ║');
    print('╚════════════════════════════════════════════════════════════╝');
  }
}
