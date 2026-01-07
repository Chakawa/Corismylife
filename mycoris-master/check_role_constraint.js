const db = require('./db');

async function checkConstraint() {
  try {
    const result = await db.query(`
      SELECT conname, pg_get_constraintdef(oid) as definition
      FROM pg_constraint
      WHERE conrelid = 'users'::regclass 
      AND contype = 'c'
    `);
    
    console.log('Current CHECK constraints on users table:');
    result.rows.forEach(row => {
      console.log(`  ${row.conname}: ${row.definition}`);
    });
    
    // Also show the role values
    const roleValues = await db.query(`SELECT DISTINCT role FROM users ORDER BY role`);
    console.log('\nCurrent role values in database:');
    roleValues.rows.forEach(row => {
      console.log(`  - ${row.role}`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await db.end();
  }
}

checkConstraint();
