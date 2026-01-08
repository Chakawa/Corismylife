import { useEffect, useState } from 'react'
import permissionsService from '../services/permissions.service'
import { Lock, AlertTriangle } from 'lucide-react'

export default function AccessDeniedPage() {
  const [requiredAccess, setRequiredAccess] = useState('')

  useEffect(() => {
    const adminType = permissionsService.getAdminType()
    setRequiredAccess(adminType)
  }, [])

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-red-50 to-orange-50 p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-lg p-8 text-center">
        <div className="flex justify-center mb-4">
          <div className="p-4 bg-red-100 rounded-full">
            <AlertTriangle className="w-8 h-8 text-red-600" />
          </div>
        </div>
        
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Accès Refusé</h1>
        
        <p className="text-gray-600 mb-6">
          Vous n'avez pas les permissions nécessaires pour accéder à cette page.
        </p>

        <div className="bg-gray-50 rounded-lg p-4 mb-6">
          <p className="text-sm text-gray-700">
            <span className="font-semibold">Votre type:</span> {requiredAccess}
          </p>
        </div>

        <p className="text-sm text-gray-500 mb-6">
          Contactez un administrateur si vous pensez que c'est une erreur.
        </p>

        <a 
          href="/dashboard"
          className="inline-block px-6 py-2 bg-coris-blue text-white rounded-lg hover:bg-coris-blue-dark transition"
        >
          Retour au Tableau de Bord
        </a>
      </div>
    </div>
  )
}
