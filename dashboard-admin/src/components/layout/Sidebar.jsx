import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  FileText,
  ClipboardList,
  DollarSign,
  Package,
  Settings,
  LogOut
} from 'lucide-react'

const menuItems = [
  { path: '/dashboard', icon: LayoutDashboard, label: 'Tableau de bord' },
  { path: '/users', icon: Users, label: 'Utilisateurs' },
  { path: '/contracts', icon: FileText, label: 'Contrats' },
  { path: '/subscriptions', icon: ClipboardList, label: 'Souscriptions' },
  { path: '/commissions', icon: DollarSign, label: 'Commissions' },
  { path: '/products', icon: Package, label: 'Produits' },
  { path: '/settings', icon: Settings, label: 'Paramètres' },
]

export default function Sidebar() {
  return (
    <aside className="w-64 bg-coris-blue text-white flex flex-col">
      {/* Logo */}
      <div className="p-6 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-coris-red rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-xl">C</span>
          </div>
          <div>
            <h1 className="text-xl font-bold">CORIS</h1>
            <p className="text-xs text-white/70">Administration</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-1">
        {menuItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                isActive
                  ? 'bg-white/10 text-white'
                  : 'text-white/70 hover:bg-white/5 hover:text-white'
              }`
            }
          >
            <item.icon className="w-5 h-5" />
            <span className="font-medium">{item.label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-white/10">
        <div className="text-xs text-white/50 text-center">
          Version 1.0.0
        </div>
      </div>
    </aside>
  )
}
