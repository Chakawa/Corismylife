import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import permissionsService from '../services/permissions.service'
import AccessDeniedPage from '../pages/AccessDeniedPage'

/**
 * Composant de protection de route basé sur les permissions
 * Vérifie si l'utilisateur a accès à la page demandée
 */
export default function ProtectedRoute({ 
  children, 
  requiredPage = null, 
  requiredPermission = null,
  requiredAdminTypes = []
}) {
  const [authorized, setAuthorized] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    checkAccess()
  }, [])

  const checkAccess = async () => {
    try {
      // Charger les permissions si nécessaire
      const data = await permissionsService.fetchPermissions()
      
      if (!data) {
        setAuthorized(false)
        setLoading(false)
        return
      }

      let hasAccess = true

      // Vérifier l'accès à une page spécifique
      if (requiredPage) {
        hasAccess = permissionsService.canAccessPage(requiredPage)
      }

      // Vérifier une permission spécifique
      if (requiredPermission && hasAccess) {
        hasAccess = permissionsService.hasPermission(requiredPermission)
      }

      // Vérifier le type d'admin
      if (requiredAdminTypes.length > 0 && hasAccess) {
        const adminType = permissionsService.getAdminType()
        hasAccess = requiredAdminTypes.includes(adminType)
      }

      setAuthorized(hasAccess)
    } catch (error) {
      console.error('Erreur vérification accès:', error)
      setAuthorized(false)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
      </div>
    )
  }

  if (authorized === false) {
    return <AccessDeniedPage />
  }

  return children
}
