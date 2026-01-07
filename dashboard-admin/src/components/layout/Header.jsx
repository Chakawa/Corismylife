import { useState, useEffect } from 'react'
import { Bell, Search, User, LogOut, ChevronDown } from 'lucide-react'
import { notificationsService } from '../../services/api.service'

export default function Header({ onLogout }) {
  const [showUserMenu, setShowUserMenu] = useState(false)
  const [showNotifications, setShowNotifications] = useState(false)
  const [notifications, setNotifications] = useState([])
  const [unreadCount, setUnreadCount] = useState(0)

  useEffect(() => {
    loadNotifications()
    // Recharger les notifications toutes les 30 secondes
    const interval = setInterval(loadNotifications, 30000)
    return () => clearInterval(interval)
  }, [])

  const loadNotifications = async () => {
    try {
      const data = await notificationsService.getNotifications({ limit: 10, unread_only: false })
      setNotifications(data.notifications || [])
      setUnreadCount(data.unread_count || 0)
    } catch (error) {
      console.error('Erreur chargement notifications:', error)
    }
  }

  const handleMarkAsRead = async (id) => {
    try {
      await notificationsService.markAsRead(id)
      loadNotifications()
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  const getTypeColor = (type) => {
    switch(type) {
      case 'new_user': return 'bg-blue-100 text-blue-800';
      case 'new_subscription': return 'bg-green-100 text-green-800';
      case 'contract_update': return 'bg-purple-100 text-purple-800';
      case 'commercial_action': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }

  return (
    <header className="bg-white border-b border-gray-200 px-6 py-4">
      <div className="flex items-center justify-between">
        {/* Search Bar */}
        <div className="flex-1 max-w-xl">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue focus:border-transparent"
            />
          </div>
        </div>

        {/* Right Section */}
        <div className="flex items-center gap-4">
          {/* Notifications */}
          <div className="relative">
            <button 
              onClick={() => setShowNotifications(!showNotifications)}
              className="relative p-2 hover:bg-gray-100 rounded-lg transition-colors">
              <Bell className="w-5 h-5 text-gray-600" />
              {unreadCount > 0 && (
                <span className="absolute top-1 right-1 w-5 h-5 bg-coris-red text-white text-xs flex items-center justify-center rounded-full font-bold">
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </button>

            {/* Notifications Dropdown */}
            {showNotifications && (
              <div className="absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-xl border border-gray-200 z-50 max-h-96 overflow-y-auto">
                <div className="p-4 border-b border-gray-200">
                  <h3 className="font-semibold text-gray-900">Notifications</h3>
                </div>
                {notifications.length > 0 ? (
                  <div className="divide-y divide-gray-100">
                    {notifications.map((notif) => (
                      <div
                        key={notif.id}
                        className={`p-4 hover:bg-gray-50 cursor-pointer transition ${!notif.is_read ? 'bg-blue-50' : ''}`}
                        onClick={() => !notif.is_read && handleMarkAsRead(notif.id)}
                      >
                        <div className="flex items-start gap-3">
                          <span className={`px-2 py-1 rounded text-xs font-medium ${getTypeColor(notif.type)}`}>
                            {notif.type === 'new_user' && 'Nouvel utilisateur'}
                            {notif.type === 'new_subscription' && 'Nouvelle souscription'}
                            {notif.type === 'contract_update' && 'Mise à jour contrat'}
                            {notif.type === 'commercial_action' && 'Action commercial'}
                          </span>
                        </div>
                        <p className="mt-1 font-medium text-sm text-gray-900">{notif.title}</p>
                        <p className="mt-1 text-sm text-gray-600">{notif.message}</p>
                        <p className="mt-2 text-xs text-gray-500">
                          {new Date(notif.created_at).toLocaleString('fr-FR')}
                        </p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="p-8 text-center">
                    <p className="text-gray-500 text-sm">Aucune notification</p>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* User Menu */}
          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-2 p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <div className="w-8 h-8 bg-coris-blue rounded-full flex items-center justify-center">
                <User className="w-5 h-5 text-white" />
              </div>
              <span className="text-sm font-medium text-gray-700">Admin</span>
              <ChevronDown className="w-4 h-4 text-gray-500" />
            </button>

            {/* Dropdown */}
            {showUserMenu && (
              <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-50">
                <button
                  onClick={() => {
                    setShowUserMenu(false)
                    onLogout()
                  }}
                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Se déconnecter</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  )
}
