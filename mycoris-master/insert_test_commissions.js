const db = require('./db');

async function insertTestCommissions() {
  try {
    console.log('🔄 Insertion de commissions fictives...');

    const testCommissions = [
      { code_apporteur: '1003', montant: 15000, date: '2026-01-01' },
      { code_apporteur: '1003', montant: 22500, date: '2026-01-02' },
      { code_apporteur: '1003', montant: 8750, date: '2026-01-03' },
      { code_apporteur: '1003', montant: 31200, date: '2026-01-04' },
      { code_apporteur: '1003', montant: 12000, date: '2026-01-05' },
      { code_apporteur: '1003', montant: 18500, date: '2025-12-28' },
      { code_apporteur: '1003', montant: 25000, date: '2025-12-25' },
      { code_apporteur: '1003', montant: 9500, date: '2025-12-20' },
    ];

    for (const commission of testCommissions) {
      const query = `
        INSERT INTO commission_instance 
        (code_apporteur, montant_commission, date_calcul)
        VALUES ($1, $2, $3)
        RETURNING id, code_apporteur, montant_commission, date_calcul
      `;

      const result = await db.query(query, [
        commission.code_apporteur,
        commission.montant,
        commission.date
      ]);

      console.log(`  ✅ Commission #${result.rows[0].id} créée: ${commission.montant} FCFA - ${commission.date}`);
    }

    // Vérifier le total
    const totalQuery = `
      SELECT 
        COUNT(*) as nombre,
        SUM(montant_commission) as total
      FROM commission_instance
      WHERE code_apporteur = '1003'
    `;

    const totalResult = await db.query(totalQuery);
    const { nombre, total } = totalResult.rows[0];

    console.log('\n📊 RÉSUMÉ:');
    console.log(`  💰 Total des commissions: ${parseFloat(total).toLocaleString('fr-FR')} FCFA`);
    console.log(`  📈 Nombre de commissions: ${nombre}`);
    console.log('\n✅✅✅ INSERTION RÉUSSIE ✅✅✅');

  } catch (error) {
    console.error('❌ Erreur insertion:', error.message);
  } finally {
    process.exit(0);
  }
}

insertTestCommissions();
