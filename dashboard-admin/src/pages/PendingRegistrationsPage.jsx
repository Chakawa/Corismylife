import { useState, useEffect } from 'react'
import { pendingRegistrationsService } from '../services/api.service'
import {
  Search, Eye, UserPlus, Trash2, X, Phone, Mail, MapPin,
  Calendar, Briefcase, Building2, Clock, RefreshCw, AlertCircle,
  CheckCircle, UserCheck
} from 'lucide-react'

export default function PendingRegistrationsPage() {
  const [registrations, setRegistrations] = useState([])
  const [loading, setLoading] = useState(true)
  const [apiError, setApiError] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedUser, setSelectedUser] = useState(null)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showActivateModal, setShowActivateModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [actionLoading, setActionLoading] = useState(false)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    loadRegistrations()
  }, [])

  const showToast = (message, type = 'success') => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 4000)
  }

  const loadRegistrations = async () => {
    setLoading(true)
    setApiError(null)
    try {
      const data = await pendingRegistrationsService.getAll()
      setRegistrations(data.data || [])
    } catch (error) {
      console.error('Erreur chargement inscriptions en attente:', error)
      const status = error.response?.status
      const msg = error.response?.data?.message || error.message || 'Erreur inconnue'
      if (status === 404) {
        setApiError('Route API introuvable (404). Le serveur n\'a peut-être pas été redémarré après le dernier déploiement. Exécutez : git pull && pm2 restart all')
      } else if (status === 500) {
        setApiError(`Erreur serveur (500) : ${msg}. La table pending_registrations existe peut-être pas encore. Exécutez la migration SQL.`)
      } else {
        setApiError(`Erreur : ${msg}`)
      }
      setRegistrations([])
    } finally {
      setLoading(false)
    }
  }

  const handleView = (user) => {
    setSelectedUser(user)
    setShowViewModal(true)
  }

  const handleActivateClick = (user) => {
    setSelectedUser(user)
    setShowActivateModal(true)
  }

  const handleDeleteClick = (user) => {
    setSelectedUser(user)
    setShowDeleteModal(true)
  }

  const handleActivate = async () => {
    if (!selectedUser) return
    setActionLoading(true)
    try {
      await pendingRegistrationsService.activate(selectedUser.id)
      setShowActivateModal(false)
      setShowViewModal(false)
      showToast(`Compte de ${getFullName(selectedUser)} créé avec succès`, 'success')
      loadRegistrations()
    } catch (error) {
      showToast(error.response?.data?.message || error.message || 'Erreur lors de l\'activation', 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!selectedUser) return
    setActionLoading(true)
    try {
      await pendingRegistrationsService.delete(selectedUser.id)
      setShowDeleteModal(false)
      setShowViewModal(false)
      showToast('Inscription supprimée', 'info')
      loadRegistrations()
    } catch (error) {
      showToast(error.response?.data?.message || error.message || 'Erreur lors de la suppression', 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const getFullName = (user) => {
    const nom = `${user.prenom || ''} ${user.nom || ''}`.trim()
    return nom || user.telephone || 'Inconnu'
  }

  const formatDate = (iso) => {
    if (!iso) return '—'
    return new Date(iso).toLocaleString('fr-FR', {
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  }

  const filtered = registrations.filter(u =>
    getFullName(u).toLowerCase().includes(searchTerm.toLowerCase()) ||
    (u.telephone || '').includes(searchTerm) ||
    (u.email || '').toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-6">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-3 px-5 py-3 rounded-xl shadow-lg text-white transition-all ${
          toast.type === 'success' ? 'bg-green-600' :
          toast.type === 'error' ? 'bg-red-600' : 'bg-blue-600'
        }`}>
          {toast.type === 'success' ? <CheckCircle className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
          <span className="text-sm font-medium">{toast.message}</span>
          <button onClick={() => setToast(null)}><X className="w-4 h-4" /></button>
        </div>
      )}

      {/* Bannière d'erreur API */}
      {apiError && (
        <div className="flex items-start gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-red-800">
          <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0 text-red-600" />
          <div className="flex-1 text-sm">
            <p className="font-semibold mb-1">Erreur de chargement</p>
            <p className="font-mono text-xs bg-red-100 p-2 rounded">{apiError}</p>
          </div>
          <button onClick={() => setApiError(null)} className="text-red-400 hover:text-red-600"><X className="w-4 h-4" /></button>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Inscriptions en attente</h1>
          <p className="text-gray-600 mt-1">
            Utilisateurs n'ayant pas finalisé leur inscription (SMS non reçu ou OTP non saisi)
          </p>
        </div>
        <button
          onClick={loadRegistrations}
          className="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Actualiser
        </button>
      </div>

      {/* Stat card */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">En attente</p>
              <p className="text-3xl font-bold text-orange-600 mt-1">{registrations.length}</p>
              <p className="text-xs text-gray-400 mt-1">inscription(s) non finalisée(s)</p>
            </div>
            <div className="p-3 bg-orange-50 rounded-lg">
              <Clock className="w-8 h-8 text-orange-500" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">Aujourd'hui</p>
              <p className="text-3xl font-bold text-blue-600 mt-1">
                {registrations.filter(r => {
                  const d = new Date(r.updated_at)
                  const now = new Date()
                  return d.toDateString() === now.toDateString()
                }).length}
              </p>
              <p className="text-xs text-gray-400 mt-1">tentative(s) du jour</p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <Calendar className="w-8 h-8 text-blue-500" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">Résultats filtrés</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{filtered.length}</p>
              <p className="text-xs text-gray-400 mt-1">selon la recherche</p>
            </div>
            <div className="p-3 bg-gray-50 rounded-lg">
              <Search className="w-8 h-8 text-gray-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Barre de recherche */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Rechercher par nom, téléphone ou email..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
          />
        </div>
      </div>

      {/* Tableau */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
          </div>
        ) : (
          <div className="overflow-auto max-h-[65vh]">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50 sticky top-0 z-10">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Utilisateur
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden md:table-cell">
                    Contact
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden lg:table-cell">
                    Profession / Secteur
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Dernière tentative
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider sticky right-0 bg-gray-50">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filtered.map((user) => (
                  <tr key={user.id} className="hover:bg-orange-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 flex-shrink-0 rounded-full bg-orange-100 flex items-center justify-center text-orange-700 text-sm font-semibold">
                          {(user.prenom?.[0] || user.telephone?.[0] || '?').toUpperCase()}
                        </div>
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {getFullName(user)}
                          </div>
                          <div className="flex items-center gap-1 mt-0.5">
                            <span className="px-1.5 py-0.5 text-xs bg-orange-100 text-orange-700 rounded font-medium">
                              En attente
                            </span>
                            {user.pays && (
                              <span className="text-xs text-gray-400">{user.pays}</span>
                            )}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <div className="space-y-0.5">
                        <div className="flex items-center gap-1.5 text-sm text-gray-700">
                          <Phone className="w-3.5 h-3.5 text-gray-400" />
                          {user.telephone || '—'}
                        </div>
                        {user.email && (
                          <div className="flex items-center gap-1.5 text-xs text-gray-500">
                            <Mail className="w-3 h-3 text-gray-400" />
                            <span className="truncate max-w-[180px]">{user.email}</span>
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      <div className="space-y-0.5">
                        {user.profession && (
                          <div className="flex items-center gap-1.5 text-sm text-gray-700">
                            <Briefcase className="w-3.5 h-3.5 text-gray-400" />
                            {user.profession}
                          </div>
                        )}
                        {user.secteur_activite && (
                          <div className="flex items-center gap-1.5 text-xs text-gray-500">
                            <Building2 className="w-3 h-3 text-gray-400" />
                            {user.secteur_activite}
                          </div>
                        )}
                        {!user.profession && !user.secteur_activite && (
                          <span className="text-xs text-gray-400">—</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5 text-sm text-gray-600">
                        <Clock className="w-3.5 h-3.5 text-gray-400" />
                        {formatDate(user.updated_at)}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right sticky right-0 bg-white z-10">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          onClick={() => handleView(user)}
                          className="text-blue-600 hover:text-blue-900 p-1.5 hover:bg-blue-50 rounded transition"
                          title="Voir les détails"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleActivateClick(user)}
                          className="text-green-600 hover:text-green-900 p-1.5 hover:bg-green-50 rounded transition"
                          title="Activer le compte"
                        >
                          <UserPlus className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteClick(user)}
                          className="text-red-600 hover:text-red-900 p-1.5 hover:bg-red-50 rounded transition"
                          title="Supprimer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filtered.length === 0 && (
              <div className="text-center py-16">
                {registrations.length === 0 ? (
                  <div className="flex flex-col items-center gap-3">
                    <CheckCircle className="w-14 h-14 text-green-400" />
                    <p className="text-gray-500 font-medium">Aucune inscription en attente</p>
                    <p className="text-gray-400 text-sm">Tous les utilisateurs ont finalisé leur inscription</p>
                  </div>
                ) : (
                  <p className="text-gray-400 text-sm">Aucun résultat pour "{searchTerm}"</p>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* ── Modal : Voir les détails ─────────────────────────────────────── */}
      {showViewModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Fiche d'inscription</h2>
              <button onClick={() => setShowViewModal(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-5">
              {/* Avatar + nom */}
              <div className="flex items-center gap-4">
                <div className="h-14 w-14 rounded-full bg-orange-100 flex items-center justify-center text-orange-700 text-xl font-bold">
                  {(selectedUser.prenom?.[0] || selectedUser.telephone?.[0] || '?').toUpperCase()}
                </div>
                <div>
                  <p className="text-lg font-bold text-gray-900">{getFullName(selectedUser)}</p>
                  <span className="px-2 py-0.5 text-xs bg-orange-100 text-orange-700 rounded-full font-medium">
                    Inscription en attente
                  </span>
                </div>
              </div>

              {/* Infos personnelles */}
              <div className="grid grid-cols-2 gap-4">
                <InfoField label="Civilité" value={selectedUser.civilite} />
                <InfoField label="Prénom" value={selectedUser.prenom} />
                <InfoField label="Nom" value={selectedUser.nom} />
                <InfoField label="Date de naissance" value={selectedUser.date_naissance} />
                <InfoField label="Lieu de naissance" value={selectedUser.lieu_naissance} />
                <InfoField label="Pays" value={selectedUser.pays} />
              </div>

              <div className="border-t pt-4 space-y-3">
                <InfoFieldFull icon={<Phone className="w-4 h-4" />} label="Téléphone" value={selectedUser.telephone} />
                <InfoFieldFull icon={<Mail className="w-4 h-4" />} label="Email" value={selectedUser.email} />
                <InfoFieldFull icon={<MapPin className="w-4 h-4" />} label="Adresse" value={selectedUser.adresse} />
                <InfoFieldFull icon={<Briefcase className="w-4 h-4" />} label="Profession" value={selectedUser.profession} />
                <InfoFieldFull icon={<Building2 className="w-4 h-4" />} label="Secteur d'activité" value={selectedUser.secteur_activite} />
                <InfoFieldFull icon={<Clock className="w-4 h-4" />} label="Dernière tentative" value={formatDate(selectedUser.updated_at)} />
              </div>
            </div>

            {/* Actions */}
            <div className="flex gap-3 p-6 border-t border-gray-200">
              <button
                onClick={() => { setShowViewModal(false); handleActivateClick(selectedUser) }}
                className="flex-1 flex items-center justify-center gap-2 bg-green-600 text-white px-4 py-2.5 rounded-lg hover:bg-green-700 transition font-medium"
              >
                <UserPlus className="w-4 h-4" />
                Activer le compte
              </button>
              <button
                onClick={() => { setShowViewModal(false); handleDeleteClick(selectedUser) }}
                className="flex items-center justify-center gap-2 border border-red-300 text-red-600 px-4 py-2.5 rounded-lg hover:bg-red-50 transition font-medium"
              >
                <Trash2 className="w-4 h-4" />
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Modal : Confirmer l'activation ──────────────────────────────── */}
      {showActivateModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg w-full max-w-md">
            <div className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-3 bg-green-100 rounded-full">
                  <UserCheck className="w-6 h-6 text-green-600" />
                </div>
                <h2 className="text-xl font-bold text-gray-900">Activer le compte</h2>
              </div>
              <p className="text-gray-600 mb-2">
                Vous allez créer un compte actif pour :
              </p>
              <div className="bg-gray-50 rounded-lg p-3 mb-4">
                <p className="font-semibold text-gray-900">{getFullName(selectedUser)}</p>
                <p className="text-sm text-gray-600">{selectedUser.telephone}</p>
                {selectedUser.email && <p className="text-sm text-gray-500">{selectedUser.email}</p>}
              </div>
              <p className="text-sm text-gray-500">
                Le client pourra se connecter avec son numéro de téléphone. Un mot de passe temporaire lui sera assigné.
              </p>
            </div>
            <div className="flex gap-3 px-6 pb-6">
              <button
                onClick={() => setShowActivateModal(false)}
                disabled={actionLoading}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition font-medium"
              >
                Annuler
              </button>
              <button
                onClick={handleActivate}
                disabled={actionLoading}
                className="flex-1 flex items-center justify-center gap-2 bg-green-600 text-white px-4 py-2.5 rounded-lg hover:bg-green-700 transition font-medium disabled:opacity-60"
              >
                {actionLoading ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                ) : (
                  <UserCheck className="w-4 h-4" />
                )}
                Confirmer l'activation
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Modal : Confirmer la suppression ────────────────────────────── */}
      {showDeleteModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg w-full max-w-md">
            <div className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-3 bg-red-100 rounded-full">
                  <Trash2 className="w-6 h-6 text-red-600" />
                </div>
                <h2 className="text-xl font-bold text-gray-900">Supprimer l'inscription</h2>
              </div>
              <p className="text-gray-600 mb-2">
                Vous allez supprimer définitivement l'inscription de :
              </p>
              <div className="bg-gray-50 rounded-lg p-3 mb-4">
                <p className="font-semibold text-gray-900">{getFullName(selectedUser)}</p>
                <p className="text-sm text-gray-600">{selectedUser.telephone}</p>
              </div>
              <p className="text-sm text-red-500 font-medium">
                ⚠ Cette action est irréversible.
              </p>
            </div>
            <div className="flex gap-3 px-6 pb-6">
              <button
                onClick={() => setShowDeleteModal(false)}
                disabled={actionLoading}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition font-medium"
              >
                Annuler
              </button>
              <button
                onClick={handleDelete}
                disabled={actionLoading}
                className="flex-1 flex items-center justify-center gap-2 bg-red-600 text-white px-4 py-2.5 rounded-lg hover:bg-red-700 transition font-medium disabled:opacity-60"
              >
                {actionLoading ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                ) : (
                  <Trash2 className="w-4 h-4" />
                )}
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// ── Composants utilitaires ──────────────────────────────────────────────────

function InfoField({ label, value }) {
  if (!value) return null
  return (
    <div>
      <p className="text-xs text-gray-400 font-medium">{label}</p>
      <p className="text-sm text-gray-800 font-medium mt-0.5">{value}</p>
    </div>
  )
}

function InfoFieldFull({ icon, label, value }) {
  if (!value) return null
  return (
    <div className="flex items-start gap-3">
      <span className="text-gray-400 mt-0.5">{icon}</span>
      <div>
        <p className="text-xs text-gray-400">{label}</p>
        <p className="text-sm text-gray-800 font-medium">{value}</p>
      </div>
    </div>
  )
}
