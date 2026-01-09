const fs = require('fs');

const file = 'dashboard-admin/src/components/layout/SidebarNav.jsx';
let content = fs.readFileSync(file, 'utf-8');

// 1. Ajouter Crown et Shield aux imports de lucide-react
content = content.replace(
  'BarChart3, Users, FileText, ShoppingCart, Briefcase, Settings, \n  Activity, Menu, X, ChevronDown, Lock',
  'BarChart3, Users, FileText, ShoppingCart, Briefcase, Settings, \n  Activity, Menu, X, ChevronDown, Lock, Crown, Shield'
);

// 2. Remplacer les emojis par des icônes lucide-react avec du HTML JSX
const oldBadge = `<div className="mt-3 px-2 py-1 bg-blue-900 rounded text-xs font-semibold">
            <span className={userRole === 'super_admin' ? 'text-purple-400' : userRole === 'admin' ? 'text-blue-400' : 'text-green-400'}>
              {userRole === 'super_admin' ? '👑 Super Admin' : userRole === 'admin' ? '🔧 Admin' : '🔒 Modérateur'}
            </span>
          </div>`;

const newBadge = `<div className="mt-3 px-2 py-2 bg-blue-900 rounded text-xs font-semibold flex items-center gap-2">
            {userRole === 'super_admin' ? (
              <>
                <Crown className="w-4 h-4 text-purple-400" />
                <span className="text-purple-400">Super Admin</span>
              </>
            ) : userRole === 'admin' ? (
              <>
                <Shield className="w-4 h-4 text-blue-400" />
                <span className="text-blue-400">Admin</span>
              </>
            ) : (
              <>
                <Lock className="w-4 h-4 text-green-400" />
                <span className="text-green-400">Modérateur</span>
              </>
            )}
          </div>`;

content = content.replace(oldBadge, newBadge);

fs.writeFileSync(file, content, 'utf-8');
console.log('✅ SidebarNav - icônes lucide-react ajoutées pour les rôles');
