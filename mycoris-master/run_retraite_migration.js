// Script pour créer et exécuter la migration des données CORIS RETRAITE
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function migrateRetraiteData() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  MIGRATION CORIS RETRAITE - Nouvelles valeurs de capital  ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  
  try {
    // 1. Récupérer l'ID du produit CORIS RETRAITE
    console.log('📊 Récupération du produit CORIS RETRAITE...');
    const { rows: products } = await pool.query(
      'SELECT id FROM produit WHERE libelle = $1',
      ['CORIS RETRAITE']
    );

    let produitId;
    if (products.length === 0) {
      console.log('   ℹ️  Produit non trouvé, création...');
      const { rows } = await pool.query(
        'INSERT INTO produit (libelle, created_at) VALUES ($1, NOW()) RETURNING id',
        ['CORIS RETRAITE']
      );
      produitId = rows[0].id;
      console.log(`   ✅ Produit créé avec l'ID: ${produitId}`);
    } else {
      produitId = products[0].id;
      console.log(`   ✅ Produit trouvé avec l'ID: ${produitId}`);
    }

    // 2. Supprimer les anciens tarifs
    console.log('\n🗑️  Suppression des anciens tarifs...');
    const deleteResult = await pool.query(
      'DELETE FROM tarif_produit WHERE produit_id = $1',
      [produitId]
    );
    console.log(`   ✅ ${deleteResult.rowCount} ancien(s) tarif(s) supprimé(s)`);

    // 3. Nouvelles données: Capital à terme pour prime de référence
    const capitalValues = {
      5: {mensuel: 605463.405379, trimestriel: 615056.504123, semestriel: 620331.447928, annuel: 625666.388106},
      6: {mensuel: 739294.364577, trimestriel: 752266.795228, semestriel: 758213.774878, annuel: 764734.523010},
      7: {mensuel: 877714.810967, trimestriel: 891453.723199, semestriel: 898104.646416, annuel: 908670.042636},
      8: {mensuel: 1020882.065727, trimestriel: 1038327.916972, semestriel: 1045708.931812, annuel: 1057643.305449},
      9: {mensuel: 1168958.840396, trimestriel: 1190342.707527, semestriel: 1190479.470698, annuel: 1211830.632461},
      10: {mensuel: 1322113.421481, trimestriel: 1344587.648202, semestriel: 1356596.978444, annuel: 1371414.515917},
      11: {mensuel: 1480519.861382, trimestriel: 1507300.829349, semestriel: 1520248.598961, annuel: 1536583.835295},
      12: {mensuel: 1644358.175855, trimestriel: 1675729.671837, semestriel: 1689628.026197, annuel: 1707534.080851},
      13: {mensuel: 1813844.548229, trimestriel: 1846605.003713, semestriel: 1861472.384183, annuel: 1880974.450438},
      14: {mensuel: 1989081.640624, trimestriel: 2026309.492304, semestriel: 2042794.643842, annuel: 2063978.367524},
      15: {mensuel: 2170358.312385, trimestriel: 2213524.637995, semestriel: 2230463.182648, annuel: 2253387.421708},
      16: {mensuel: 2361663.347047, trimestriel: 2402847.877909, semestriel: 2424700.120313, annuel: 2449425.792789},
      17: {mensuel: 2559654.057923, trimestriel: 2602620.867097, semestriel: 2625735.350796, annuel: 2652329.506857},
      18: {mensuel: 2764594.793679, trimestriel: 2809385.910906, semestriel: 2833806.814345, annuel: 2862326.710918},
      19: {mensuel: 2976698.105187, trimestriel: 3019148.619548, semestriel: 3044903.438595, annuel: 3079677.957121},
      20: {mensuel: 3196225.032957, trimestriel: 3240492.134693, semestriel: 3267645.786918, annuel: 3304636.466941},
      21: {mensuel: 3423435.402467, trimestriel: 3469582.672868, semestriel: 3498184.113972, annuel: 3537468.588654},
      22: {mensuel: 3658598.135282, trimestriel: 3701991.400963, semestriel: 3736791.284233, annuel: 3778449.797473},
      23: {mensuel: 3901991.563746, trimestriel: 3947234.413457, semestriel: 3983749.705453, annuel: 4027865.351705},
      24: {mensuel: 4153903.762206, trimestriel: 4201060.933389, semestriel: 4239351.671416, annuel: 4286010.450336},
      25: {mensuel: 4414632.887612, trimestriel: 4458560.426312, semestriel: 4498666.347671, annuel: 4547912.261262},
      26: {mensuel: 4684487.532408, trimestriel: 4730283.355211, semestriel: 4772290.396112, annuel: 4824259.001727},
      27: {mensuel: 4963787.683771, trimestriel: 5011516.586104, semestriel: 5055491.266247, annuel: 5110277.878109},
      28: {mensuel: 5252862.131642, trimestriel: 5296815.505562, semestriel: 5348604.207638, annuel: 5406307.415163},
      29: {mensuel: 5552054.799978, trimestriel: 5597877.362131, semestriel: 5651976.081074, annuel: 5712697.986015},
      30: {mensuel: 5861719.211707, trimestriel: 5909476.383267, semestriel: 5965965.970183, annuel: 6029812.226846},
      31: {mensuel: 6182221.877845, trimestriel: 6225575.781317, semestriel: 6284512.371581, annuel: 6358025.466106},
      32: {mensuel: 6513942.137299, trimestriel: 6559144.247123, semestriel: 6620641.030858, annuel: 6697726.168741},
      33: {mensuel: 6857272.605833, trimestriel: 6904387.609234, semestriel: 6968534.193210, annuel: 7049316.395967},
      34: {mensuel: 7212619.840766, trimestriel: 7264612.498187, semestriel: 7328603.616244, annuel: 7413212.281147},
      35: {mensuel: 7580403.821922, trimestriel: 7624197.249084, semestriel: 7701275.469085, annuel: 7789844.522308},
      36: {mensuel: 7961060.449418, trimestriel: 8006717.466263, semestriel: 8086990.836775, annuel: 8179658.891909},
      37: {mensuel: 8355040.058877, trimestriel: 8394751.786861, semestriel: 8478298.278308, annuel: 8575140.790787},
      38: {mensuel: 8762808.954867, trimestriel: 8804241.412862, semestriel: 8891209.444321, annuel: 8992440.529785},
      39: {mensuel: 9184849.761809, trimestriel: 9228063.175773, semestriel: 9318572.501144, annuel: 9424345.759649},
      40: {mensuel: 9621661.997201, trimestriel: 9657988.540329, semestriel: 9760893.264956, annuel: 9871367.672557},
      41: {mensuel: 10073762.660832, trimestriel: 10111691.452702, semestriel: 10218695.255501, annuel: 10334035.352417},
      42: {mensuel: 10541686.847690, trimestriel: 10581273.967007, semestriel: 10692520.315715, annuel: 10812896.401073},
      43: {mensuel: 11025988.381088, trimestriel: 11057612.584807, semestriel: 11173208.346138, annuel: 11308517.586431},
      44: {mensuel: 11527240.468155, trimestriel: 11560302.338736, semestriel: 11680441.364525, annuel: 11821485.513277},
      45: {mensuel: 12046036.378270, trimestriel: 12080582.334053, semestriel: 12205427.538555, annuel: 12352407.317562},
      46: {mensuel: 12582990.145238, trimestriel: 12619080.006705, semestriel: 12748788.228676, annuel: 12901911.384998},
      47: {mensuel: 13138737.294051, trimestriel: 13176421.181466, semestriel: 13311166.542952, annuel: 13470648.094793},
      48: {mensuel: 13713935.593071, trimestriel: 13753269.236278, semestriel: 13893228.098227, annuel: 14059290.589432},
      49: {mensuel: 14309265.832568, trimestriel: 14350306.973009, semestriel: 14483712.331354, annuel: 14668483.327573},
      50: {mensuel: 14925432.630426, trimestriel: 14968241.030525, semestriel: 15106812.989223, annuel: 15286630.055359}
    };

    // 4. Insérer les nouveaux tarifs
    console.log('\n📥 Insertion des nouveaux tarifs...');
    let insertCount = 0;

    for (const [duree, periodicites] of Object.entries(capitalValues)) {
      for (const [periodicite, capitalForRefPrime] of Object.entries(periodicites)) {
        await pool.query(
          `INSERT INTO tarif_produit 
           (produit_id, duree_contrat, periodicite, prime, age, created_at, updated_at) 
           VALUES ($1, $2, $3, $4, 0, NOW(), NOW())`,
          [produitId, parseInt(duree), periodicite, capitalForRefPrime]
        );
        insertCount++;
      }
    }

    console.log(`   ✅ ${insertCount} nouveaux tarifs insérés`);

    // 5. Vérification
    console.log('\n🔍 Vérification...');
    const { rows: tarifs } = await pool.query(
      'SELECT COUNT(*) as count FROM tarif_produit WHERE produit_id = $1',
      [produitId]
    );
    console.log(`   ✅ Total de tarifs en base: ${tarifs[0].count}`);

    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log('║  ✅ MIGRATION RÉUSSIE                                      ║');
    console.log('╚════════════════════════════════════════════════════════════╝');
    console.log('\n📝 Nouvelles données:');
    console.log('   - Capital à terme pour prime de référence');
    console.log('   - Prime ref: mensuel 10k, trimestriel 30k, semestriel 60k, annuel 120k');
    console.log('   - Formule: Prime = (Capital × PrimeRef) / CapitalForRef');
    console.log('   - Formule: Capital = (Prime × CapitalForRef) / PrimeRef');
    console.log('   - Durées: 5 à 50 ans');
    console.log('   - Périodicités: mensuel, trimestriel, semestriel, annuel\n');

  } catch (error) {
    console.error('\n❌ ERREUR lors de la migration:');
    console.error('   ', error.message);
    console.error('\n╔════════════════════════════════════════════════════════════╗');
    console.error('║  ❌ MIGRATION ÉCHOUÉE                                      ║');
    console.error('╚════════════════════════════════════════════════════════════╝\n');
    process.exit(1);
  } finally {
    await pool.end();
    console.log('🔌 Connexion fermée\n');
  }
}

// Exécuter la migration
migrateRetraiteData();
