# CORIS Insurance Platform - AI Agent Guide

## Architecture Overview

CORIS is a multi-tier insurance platform with three main components:

1. **Backend API** (`mycoris-master/`) - Node.js/Express REST API with PostgreSQL
2. **Admin Dashboard** (`dashboard-admin/`) - React/Vite web dashboard for administrators
3. **Mobile App** (`mycorislife-master/`) - Flutter mobile application for customers

All components communicate through the backend API at `http://localhost:5000/api`.

## Development Workflow

### Starting the System
Use the automated startup script rather than manual commands:
```bash
# Windows: Double-click or run
start-all.bat

# Manual alternative (3 terminals):
# Terminal 1: Backend
cd mycoris-master && npm start

# Terminal 2: Admin Dashboard  
cd dashboard-admin && npm run dev

# Terminal 3: Flutter (if needed)
cd mycorislife-master && flutter run
```

### Database Migrations
**CRITICAL**: Always run migrations via Node.js scripts, not raw SQL:
```bash
cd mycoris-master
node run_notifications_migration.js
node run_retraite_migration.js
# etc.
```
Each migration script in `mycoris-master/` handles its corresponding SQL file in `migrations/`.

## Authentication & Authorization

### JWT Token Pattern
All protected endpoints require `Authorization: Bearer <token>` header.

**Middleware stack pattern** in `mycoris-master/routes/`:
```javascript
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

// Public routes first
router.post('/login', authController.login);

// Then apply middleware to all subsequent routes
router.use(verifyToken);
router.use(requireAdmin);  // For admin-only routes

// Protected routes follow
router.get('/users', getAllUsers);
```

### Role-Based Access
- `client` - Mobile app users (souscriptions, consultations)
- `commercial` - Sales agents (manage clients, commissions)
- `admin` - Full access (dashboard at `dashboard-admin/`)

Admin routes are in `mycoris-master/routes/adminRoutes.js` and mounted at `/api/admin/*`.

## Database Patterns

### Connection Management
All database queries use the `pool` instance from `mycoris-master/db.js`:
```javascript
const pool = require('../db');
const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
```

**Environment**: Database URL is in `.env` as `DATABASE_URL=postgresql://...`

### Key Tables
- `users` - All user types (role: client/commercial/admin), passwords are bcrypt-hashed
- `souscriptions` - Subscription proposals with JSON fields for product-specific data
- `questionnaire_medical` - Medical questions (shared across products)
- `souscription_questionnaire` - Medical questionnaire responses per subscription
- `notifications` - Admin notifications with auto-creation triggers
- `commission_instance` - Commission tracking per subscription

### Password Security
**ALWAYS** hash passwords with bcrypt before storage:
```javascript
const bcrypt = require('bcrypt');
const hashedPassword = await bcrypt.hash(password, 10);
```
Never return password fields in API responses.

## Frontend Conventions

### Admin Dashboard (React)
Located in `dashboard-admin/src/`:

**API Service Pattern**: All API calls go through `services/api.service.js`:
```javascript
import api from '../services/api.service';

// Usage
const users = await api.users.getAll();
await api.users.create(userData);
```

**Permission-Based Features**: Use `permissionsService` to check admin capabilities:
```javascript
import permissionsService from '../services/permissions.service';

if (permissionsService.hasPermission('users_create')) {
  // Show create button
}
```

**Styling**: Uses Tailwind CSS with CORIS brand colors defined in `tailwind.config.js`:
- `coris-blue`: #002B6B (primary)
- `coris-red`: #E30613 (accent)

### Mobile App (Flutter)
Located in `mycorislife-master/lib/`:

**Feature-Based Structure**:
- `lib/features/auth/` - Login, registration
- `lib/features/souscription/` - Insurance subscriptions (Famillis, Sérénité, Retraite)
- `lib/features/client/` - Client profile, documents
- `lib/services/` - API communication layer

**API Service Pattern**: All HTTP calls use the centralized service in `lib/services/`:
```dart
// Services handle token injection and error handling
final response = await subscriptionService.createSubscription(data);
```

## Subscription (Souscription) Workflow

### Critical Flow
1. Client fills product form in mobile app (`mycorislife-master/lib/features/souscription/`)
2. Medical questionnaire presented (`souscription_questionnaire` table)
3. Data sent to `POST /api/subscriptions` (backend: `controllers/subscriptionController.js`)
4. PDF proposal generated server-side using `pdfkit`
5. Status tracking: `brouillon` → `en_attente` → `validee` → `active`

### Product Types
Each has unique data schema stored in `souscriptions.product_data` (JSON):
- **Famillis** - Family death insurance
- **Sérénité** - Life insurance with savings
- **Retraite** - Retirement plan (newest, added via `run_retraite_migration.js`)

### Medical Questionnaire Integration
**Endpoints** in `mycoris-master/routes/subscriptionRoutes.js`:
```
GET  /api/subscriptions/questionnaire-medical/questions
POST /api/subscriptions/:id/questionnaire-medical
GET  /api/subscriptions/:id/questionnaire-medical
```

Questions are pulled from `questionnaire_medical` table, answers saved to `souscription_questionnaire`.

## Notifications System

### Auto-Creation Pattern
Notifications are automatically created in `adminRoutes.js` after key events:
```javascript
// After user creation
await createNotificationForAllAdmins({
  type: 'new_user',
  title: 'Nouvel utilisateur Commercial',
  message: `${prenom} ${nom} (${email})`,
  reference_id: userId,
  reference_type: 'user',
  action_url: `/utilisateurs?user=${userId}`
});
```

**Supported types**: `new_user`, `new_subscription`, `contract_update`, `commercial_action`

**Frontend Display**: Real-time bell icon in `dashboard-admin/src/components/layout/Header.jsx` with 30-second auto-refresh.

## Common Pitfalls

1. **Don't run `npm install` in `mycorislife-master/`** - Use `flutter pub get` instead
2. **Don't bypass migration scripts** - Always use `node run_*_migration.js`, never direct SQL execution
3. **Don't modify `subscriptionController.js` lightly** - It's 191KB with complex PDF generation; preserved from GitHub master branch
4. **Frontend port conflicts** - Dashboard is port 3000, Backend is port 5000, Flutter uses device-specific ports
5. **JWT expiry is 30 days** - Set in `.env` as `JWT_EXPIRES_IN=30d`

## Testing & Debugging

### API Testing
Backend includes test scripts:
```bash
cd mycoris-master
node test_questionnaire_endpoint.js  # Tests medical questionnaire API
```

### Database Inspection
Use utility scripts in `mycoris-master/`:
```bash
node check_users_structure.js    # Verify users table schema
node check_questionnaire.js       # Check medical questions
node check_admins.js             # List admin accounts
```

### Creating Test Data
```bash
node create_test_admins.js       # Seeds admin users
node insert_test_commissions.js  # Seeds commission data
```

## File Naming Conventions

- **Backend controllers**: `*Controller.js` (camelCase filename)
- **Backend routes**: `*Routes.js` (camelCase)
- **Frontend pages**: `*Page.jsx` (PascalCase)
- **Flutter screens**: `*_screen.dart` (snake_case)
- **Migration scripts**: `run_*_migration.js`
- **SQL migrations**: `create_*_table.sql` or `add_*.sql`

## Documentation References

For detailed implementation context, see workspace root:
- `SYSTEM_DIAGRAMS.md` - Visual architecture flows
- `README_IMPLEMENTATIONS.md` - Feature implementation details
- `WORKSPACE_INVENTORY.md` - Complete file inventory
- `ETAT_PROJET_12JAN2026.md` - Current project state snapshot
- `dashboard-admin/GUIDE_DEMARRAGE.md` - Admin dashboard quick start

## Key Files to Reference

**Backend Entry**: [mycoris-master/server.js](mycoris-master/server.js) - All route mounting  
**Admin Routes**: [mycoris-master/routes/adminRoutes.js](mycoris-master/routes/adminRoutes.js) - Dashboard API  
**Subscription Logic**: [mycoris-master/controllers/subscriptionController.js](mycoris-master/controllers/subscriptionController.js) - PDF generation, workflows  
**Auth Middleware**: [mycoris-master/middlewares/authMiddleware.js](mycoris-master/middlewares/authMiddleware.js) - JWT verification  
**Dashboard Layout**: [dashboard-admin/src/components/layout/DashboardLayout.jsx](dashboard-admin/src/components/layout/DashboardLayout.jsx) - Navigation structure  
**API Service**: [dashboard-admin/src/services/api.service.js](dashboard-admin/src/services/api.service.js) - Centralized HTTP client
