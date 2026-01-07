# 🚀 Notifications System - Setup Guide

## Overview
The notifications system has been fully implemented for the CORIS admin dashboard. Here's what was added:

### ✅ Completed Features

#### 1. **Notification Bell in Header**
- Real-time notification display with unread count badge
- Dropdown menu showing recent notifications (max 10)
- Color-coded notification types (new_user: blue, new_subscription: green, contract_update: purple, commercial_action: yellow)
- Auto-refresh every 30 seconds
- Click to mark notification as read

#### 2. **Database Schema**
- New `notifications` table with:
  - admin_id (FK to users)
  - type (new_user, new_subscription, contract_update, commercial_action)
  - title, message, reference_id, reference_type
  - is_read, read_at, action_url
  - Indexes for performance (admin_id, is_read, type, created_at DESC)

#### 3. **Backend API Endpoints**
- `GET /api/admin/notifications` - Get admin's notifications with unread count
- `PUT /api/admin/notifications/:id/mark-read` - Mark notification as read
- `POST /api/admin/notifications/create` - Create notification for all admins

#### 4. **Automatic Notification Triggers**
- **New User Registration**: Creates notification when new user/admin created
- **New Subscription**: Creates notification when new subscription created
- More triggers can be added for:
  - Contract status changes
  - Commercial actions
  - Payment updates
  - User suspension/activation

#### 5. **Frontend Service Layer**
- `notificationsService` in api.service.js with methods:
  - `getNotifications(params)` - Fetch notifications
  - `markAsRead(id)` - Mark as read
  - `create(data)` - Create notification

---

## 🔧 Setup Instructions

### Step 1: Execute the Database Migration
```bash
cd mycoris-master
node run_notifications_migration.js
```

This will:
- Create the `notifications` table with all required columns
- Create necessary indexes for performance
- Ready the database for notifications

### Step 2: Restart Backend Server
```bash
npm start
# or
node server.js
```

The backend is now running on `http://localhost:5000`

### Step 3: Restart Frontend Dashboard
```bash
cd dashboard-admin
npm run dev
```

The dashboard is now running on `http://localhost:3000`

---

## 📊 Testing the Notifications System

### Test 1: Create a New User
1. Go to Dashboard → Users page
2. Click "Nouveau utilisateur"
3. Fill in all fields and click "Créer"
4. **Expected**: A notification appears in the bell icon dropdown with "Nouvel utilisateur"

### Test 2: Create a New Subscription
1. Use the subscription creation endpoint (or mobile app)
2. Create a subscription with product_type (e.g., 'coris_serenite')
3. **Expected**: A notification appears with "Nouvelle souscription"

### Test 3: Mark Notification as Read
1. Click on a notification in the dropdown
2. **Expected**: The notification badge count decreases, notification no longer highlighted

### Test 4: Refresh Notifications
- Notifications auto-refresh every 30 seconds
- Click the bell icon again to manually refresh

---

## 🔌 Adding More Notification Triggers

To add notifications to other events, follow this pattern:

```javascript
// After creating/updating a resource:
try {
  const adminQuery = "SELECT id FROM users WHERE role = 'admin'";
  const adminResult = await pool.query(adminQuery);
  
  if (adminResult.rows.length > 0) {
    for (const admin of adminResult.rows) {
      await pool.query(`
        INSERT INTO notifications 
          (admin_id, type, title, message, reference_id, reference_type, action_url, created_at)
        VALUES 
          ($1, $2, $3, $4, $5, $6, $7, NOW())
      `, [
        admin.id,
        'event_type',      // e.g., 'contract_update'
        'Event Title',
        'Event Message',
        resourceId,
        'resource_type',   // e.g., 'contract'
        '/page?id=resourceId'
      ]);
    }
  }
} catch (notifError) {
  console.error('Notification error:', notifError.message);
}
```

### Suggested Events to Add:
1. **Contract Status Changes**: When contract moves from proposition → contrat → annulé
2. **Payment Received**: When payment status updated to paid
3. **Document Upload**: When client uploads required documents
4. **KYC Verification**: When KYC status changes
5. **User Suspension**: When user account suspended

---

## 📝 Current Implementation Details

### Files Modified:
1. **routes/adminRoutes.js**
   - Updated POST /users to create notification on new user
   - Added GET /notifications endpoint
   - Added PUT /notifications/:id/mark-read endpoint
   - Added POST /notifications/create endpoint

2. **controllers/subscriptionController.js**
   - Updated createSubscription to create notification on new subscription

3. **src/components/layout/Header.jsx**
   - Added notification bell with dropdown
   - Added polling for auto-refresh (30s interval)
   - Display unread count badge

4. **src/services/api.service.js**
   - Added notificationsService with CRUD methods

5. **migrations/create_notifications_admin_table.sql**
   - Created notifications table schema

6. **run_notifications_migration.js**
   - Migration runner script

---

## 🎨 UI/UX Details

### Notification Bell Icon
- Shows count badge when unread notifications exist
- Color badge: Red (badge) on Blue (bell)
- Click to toggle dropdown

### Notification Dropdown
- Shows last 10 notifications
- Color-coded by type
- Timestamp shows creation time (FR locale)
- Click notification to mark as read
- "Aucune notification" message when empty

### Notification Types & Colors:
- 🔵 **new_user** (Blue): New user/admin registration
- 🟢 **new_subscription** (Green): New subscription created
- 🟣 **contract_update** (Purple): Contract status changed
- 🟡 **commercial_action** (Yellow): Commercial activities

---

## 🐛 Troubleshooting

### Issue: No notifications appear
**Solution**: 
1. Check that migration was run: `SELECT * FROM notifications;`
2. Verify backend is restarted
3. Check browser console for errors
4. Ensure logged-in user is admin

### Issue: Notifications not auto-refreshing
**Solution**:
1. Check network tab (DevTools → Network)
2. Verify `/api/admin/notifications` endpoint returns data
3. Restart frontend server

### Issue: "notifications table does not exist"
**Solution**:
1. Run migration: `node run_notifications_migration.js`
2. Verify table was created: `\dt notifications` in PostgreSQL

---

## 📱 Next Steps (Optional Enhancements)

1. **Real-time Updates via WebSocket**
   - Replace 30s polling with WebSocket push
   - Instant notifications without refresh

2. **Sound/Toast Alerts**
   - Add browser notification sound
   - Toast pop-up for critical notifications

3. **Notification History**
   - Add "View All" link to see full history
   - Filter by type/date
   - Export notifications as report

4. **Notification Settings**
   - Admin can configure which events to notify
   - Notification preferences (email, in-app, etc.)

5. **Delete Old Notifications**
   - Add cleanup script for notifications older than 30 days

---

## 📞 Support

If you encounter any issues:
1. Check backend logs: `console.log` output in terminal
2. Check frontend console: F12 → Console tab
3. Verify database: `psql` and query notifications table
4. Check network requests: DevTools → Network tab
