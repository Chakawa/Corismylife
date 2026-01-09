import { useState, useEffect } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { 
  BarChart3, Users, FileText, ShoppingCart, Briefcase, Settings, 
  Activity, Menu, X, ChevronDown, Lock, Crown, Shield
} from 'lucide-react'
import permissionsService from '../../services/permissions.service'

export default function SidebarNav() {
  const location = useLocation()
  const [isOpen, setIsOpen] = useState(false)
  const [permissions, setPermissions] = useState(null)
  const [userRole, setUserRole] = useState('')

  useEffect(() => {
    loadPermissions()
  }, [])

  const loadPermissions = async () => {
    const data = await permissionsService.fetchPermissions()
    if (data) {
      setPermissions(data.permissions)
      setUserRole(data.role)
    }
  }

  // Définir les routes disponibles
  const allRoutes = [
    { path: '/dashboard', label: 'Tableau de Bord', icon: BarChart3, page: 'stats', requireSuperAdmin: false },
    { path: '/users', label: 'Utilisateurs', icon: Users, page: 'users', requireSuperAdmin: false },
    { path: '/contracts', label: 'Contrats', icon: FileText, page: 'contracts', requireSuperAdmin: false },
    { path: '/subscriptions', label: 'Souscriptions', icon: ShoppingCart, page: 'contracts', requireSuperAdmin: false },
    { path: '/commissions', label: 'Commissions', icon: Briefcase, page: 'contracts', requireSuperAdmin: false },
    { path: '/products', label: 'Produits', icon: ShoppingCart, page: 'products', requireSuperAdmin: false },
    { path: '/activities', label: 'Activités', icon: Activity, page: 'stats', requireSuperAdmin: false },
    { path: '/settings', label: 'Paramètres', icon: Settings, page: 'settings', requireSuperAdmin: true }
  ]

  // Filtrer les routes selon les permissions
  const visibleRoutes = allRoutes.filter(route => {
    // Les modérateurs ne voient que stats et reports
    if (userRole === 'moderation') {
      return route.page === 'stats' || route.path === '/dashboard'
    }

    // Super admin voit tout
    if (userRole === 'super_admin') {
      return true
    }

    // Admin standard voit tout sauf paramètres
    if (userRole === 'admin') {
      return !route.requireSuperAdmin
    }

    return false
  })

  const isActive = (path) => location.pathname === path

  return (
    <>
      {/* Mobile Menu Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="md:hidden fixed bottom-4 right-4 z-40 p-3 bg-coris-blue text-white rounded-full shadow-lg hover:bg-coris-blue-dark transition"
      >
        {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
      </button>

      {/* Sidebar */}
      <aside className={`fixed top-0 left-0 h-screen w-64 bg-coris-blue text-white transition-transform duration-300 z-30 ${
        isOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'
      } flex flex-col`}>
        {/* Header */}
        <div className="p-6 border-b border-blue-800">
          <div className="flex items-center gap-3">
            <img 
              src="/logo.png" 
              alt="CORIS Logo" 
              className="w-10 h-10 object-contain"
            />
            <div>
              <h1 className="font-bold text-lg">CORIS</h1>
              <p className="text-xs text-blue-200">Admin Dashboard</p>
            </div>
          </div>
          
          {/* Admin Type Badge */}
          <div className="mt-3 px-3 py-2 bg-blue-900 rounded text-xs font-semibold flex items-center gap-2">
            {userRole === 'super_admin' ? (
              <>
                <Crown className="w-4 h-4 text-yellow-300 flex-shrink-0" />
                <span className="text-yellow-300">Super Admin</span>
              </>
            ) : userRole === 'admin' ? (
              <>
                <Shield className="w-4 h-4 text-blue-300 flex-shrink-0" />
                <span className="text-blue-300">Admin</span>
              </>
            ) : (
              <>
                <Lock className="w-4 h-4 text-green-300 flex-shrink-0" />
                <span className="text-green-300">Modérateur</span>
              </>
            )}
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4">
          <div className="space-y-2 px-3">
            {visibleRoutes.map((route) => {
              const Icon = route.icon
              const active = isActive(route.path)

              return (
                <Link
                  key={route.path}
                  to={route.path}
                  onClick={() => setIsOpen(false)}
                  className={`flex items-center gap-3 px-4 py-2 rounded-lg transition ${
                    active
                      ? 'bg-white text-coris-blue font-semibold'
                      : 'text-white hover:bg-blue-800'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="font-medium">{route.label}</span>
                </Link>
              )
            })}

            {/* Restricted Sections Info */}
            {userRole === 'moderation' && (
              <div className="mt-6 pt-4 border-t border-blue-800">
                <p className="px-4 text-xs text-blue-200 font-semibold mb-2">ACCÈS LIMITÉ</p>
                <div className="px-4 py-2 bg-blue-900 rounded-lg text-xs text-blue-100">
                  <p className="flex items-center gap-2">
                    <Lock className="w-4 h-4" />
                    Autres sections réservées aux admins
                  </p>
                </div>
              </div>
            )}
          </div>
        </nav>

        {/* Footer */}
        <div className="border-t border-blue-800 p-4 mt-auto">
          <p className="text-xs text-blue-200 text-center">
            © 2026 CORIS Dashboard
          </p>
        </div>
      </aside>

      {/* Mobile Overlay */}
      {isOpen && (
        <div
          onClick={() => setIsOpen(false)}
          className="md:hidden fixed inset-0 bg-black bg-opacity-50 z-20"
        />
      )}
    </>
  )
}
