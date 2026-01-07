const pool = require('./db');

async function showUsersTable() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n' + '='.repeat(100));
    console.log('📋 STRUCTURE DE LA TABLE USERS');
    console.log('='.repeat(100) + '\n');
    
    result.rows.forEach((col, i) => {
      const colNum = String(i + 1).padStart(2, ' ');
      const colName = col.column_name.padEnd(25);
      const colType = col.data_type.padEnd(20);
      const nullable = (col.is_nullable === 'YES' ? '✓' : '✗').padEnd(3);
      const defaultVal = col.column_default || '-';
      
      console.log(`${colNum}. ${colName} | Type: ${colType} | NULL: ${nullable} | Default: ${defaultVal}`);
    });
    
    console.log('\n' + '='.repeat(100));
    console.log(`Total: ${result.rows.length} colonnes`);
    console.log('='.repeat(100) + '\n');
    
    pool.end();
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    pool.end();
    process.exit(1);
  }
}

showUsersTable();
