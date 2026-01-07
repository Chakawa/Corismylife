const fs = require('fs');
const path = require('path');
const db = require('./db');

async function runMigration() {
  try {
    console.log('Starting consolidation of role and admin_type columns...');
    
    // Read the migration file
    const migrationPath = path.join(__dirname, 'migrations/consolidate_role_admin_type.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    // Execute the migration
    await db.query(sql);
    
    console.log('✅ Migration completed successfully!');
    console.log('- Updated existing admin users with new role values');
    console.log('- Dropped admin_type column');
    console.log('- Added constraint for valid role values');
    
    // Verify the users table structure
    const result = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    console.log('\nUpdated users table structure:');
    result.rows.forEach(col => {
      console.log(`  - ${col.column_name} (${col.data_type}, nullable: ${col.is_nullable})`);
    });
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration();
