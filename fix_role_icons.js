const fs = require('fs');

const file = 'dashboard-admin/src/components/layout/SidebarNav.jsx';
let content = fs.readFileSync(file, 'utf-8');

// 1. D'abord ajouter Crown et Shield aux imports
content = content.replace(
  '  Activity, Menu, X, ChevronDown, Lock\n} from \'lucide-react\'',
  '  Activity, Menu, X, ChevronDown, Lock, Crown, Shield\n} from \'lucide-react\''
);

// 2. Remplacer le badge
const oldBadge = `          {/* Admin Type Badge */}
          <div className="mt-3 px-2 py-1 bg-blue-900 rounded text-xs font-semibold">
            <span className={userRole === 'super_admin' ? 'text-purple-400' : userRole === 'admin' ? 'text-blue-400' : 'text-green-400'}>
              {userRole === 'super_admin' ? 'Super Admin' : userRole === 'admin' ? '🔧 Admin' : '🔒 Modérateur'}
            </span>
          </div>`;

const newBadge = `          {/* Admin Type Badge */}
          <div className="mt-3 px-2 py-2 bg-blue-900 rounded text-xs font-semibold flex items-center gap-2">
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
console.log('✅ SidebarNav - icônes lucide-react pour rôles ajoutées');
