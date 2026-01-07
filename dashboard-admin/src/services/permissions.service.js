/**
 * Service de gestion des permissions administrateur
 * Permet de vérifier les accès selon le rôle
 */

import api from '../utils/api'

// Permissions par défaut (cache local)
let cachedPermissions = null
let cachedRole = null

/**
 * Récupère les permissions de l'admin connecté
 */
export const permissionsService = {
  /**
   * Charge les permissions depuis le backend
   */
  async fetchPermissions() {
    try {
      const response = await api.get('/admin/permissions')
      if (response.data.success) {
        cachedPermissions = response.data.permissions
        cachedRole = response.data.role
        return response.data
      }
      throw new Error('Impossible de récupérer les permissions')
    } catch (error) {
      console.error('Erreur récupération permissions:', error)
      return null
    }
  },

  /**
   * Vérifie si l'admin a une permission spécifique
   * @param {string} permission - Nom de la permission à vérifier
   * @returns {boolean}
   */
  hasPermission(permission) {
    if (!cachedPermissions) return false
    return cachedPermissions[permission] === true
  },

  /**
   * Vérifie si l'admin peut accéder à une page du dashboard
   * @param {string} page - Nom de la page
   * @returns {boolean}
   */
  canAccessPage(page) {
    if (!cachedPermissions || !cachedPermissions.dashboardAccess) return false
    return cachedPermissions.dashboardAccess.includes(page)
  },

  /**
   * Retourne le rôle
   * @returns {string} - 'super_admin', 'admin', 'moderation', 'commercial', ou 'client'
   */
  getAdminType() {
    return cachedRole || 'client'
  },

  /**
   * Vérifie si c'est un super admin
   * @returns {boolean}
   */
  isSuperAdmin() {
    return cachedRole === 'super_admin'
  },

  /**
   * Vérifie si c'est au moins un admin standard
   * @returns {boolean}
   */
  isAdmin() {
    return cachedRole === 'super_admin' || cachedRole === 'admin'
  },

  /**
   * Retourne toutes les permissions
   * @returns {object}
   */
  getAllPermissions() {
    return cachedPermissions
  },

  /**
   * Vide le cache des permissions (lors de la déconnexion)
   */
  clearCache() {
    cachedPermissions = null
    cachedRole = null
  },

  /**
   * Filtre les routes de navigation selon les permissions
   * @param {Array} routes - Liste des routes
   * @returns {Array} - Routes filtrées
   */
  filterRoutes(routes) {
    if (!cachedPermissions) return []
    
    return routes.filter(route => {
      // Si pas de restriction de page, autoriser
      if (!route.page) return true
      
      // Vérifier si l'admin peut accéder à cette page
      return this.canAccessPage(route.page)
    })
  }
}

/**
 * Hook React pour utiliser les permissions
 */
export const usePermissions = () => {
  const [permissions, setPermissions] = React.useState(null)
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    permissionsService.fetchPermissions().then(data => {
      setPermissions(data?.permissions || null)
      setLoading(false)
    })
  }, [])

  return {
    permissions,
    loading,
    hasPermission: permissionsService.hasPermission.bind(permissionsService),
    canAccessPage: permissionsService.canAccessPage.bind(permissionsService),
    isSuperAdmin: permissionsService.isSuperAdmin.bind(permissionsService),
    isAdmin: permissionsService.isAdmin.bind(permissionsService)
  }
}

export default permissionsService
