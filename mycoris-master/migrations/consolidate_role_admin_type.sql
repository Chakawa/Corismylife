-- Migration: Consolidate role and admin_type into single role column
-- Date: 2026-01-07

-- Step 1: Drop existing CHECK constraint on role
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Step 2: Update existing admin users to use new role values (only if admin_type column exists)
UPDATE users SET role = 'super_admin' WHERE role = 'admin' AND admin_type = 'super_admin';
UPDATE users SET role = 'admin' WHERE role = 'admin' AND admin_type = 'admin';
UPDATE users SET role = 'moderation' WHERE role = 'admin' AND admin_type = 'moderation';

-- Step 3: Drop the admin_type column (if it exists)
ALTER TABLE users DROP COLUMN IF EXISTS admin_type;

-- Step 4: Add new CHECK constraint with all valid role values
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('super_admin', 'admin', 'moderation', 'commercial', 'client'));

