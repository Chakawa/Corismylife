import React, { useState, useEffect } from 'react'
import { Search, Check, X, Eye, Plus, Trash2 } from 'lucide-react'
import { subscriptionsService } from '../services/api.service'

export default function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('tous')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })
  const [stats, setStats] = useState({ by_status: {} })
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [selectedSubscription, setSelectedSubscription] = useState(null)
  const [formData, setFormData] = useState({
    nom_client: '',
    prenom_client: '',
    email: '',
    telephone: '',
    produit: '',
    montant: '',
    statut: 'en_attente'
  })

  useEffect(() => {
    fetchSubscriptions()
  }, [statusFilter, pagination.offset])

  const fetchSubscriptions = async () => {
    try {
      setLoading(true)
      const params = {
        statut: statusFilter === 'tous' ? undefined : statusFilter,
        limit: pagination.limit,
        offset: pagination.offset
      }
      const data = await subscriptionsService.getAll(params)
      setSubscriptions(data.subscriptions || [])
      setStats(data.stats || { by_status: {} })
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
    } catch (error) {
      console.error('Erreur:', error)
      alert('Erreur lors du chargement des souscriptions')
    } finally {
      setLoading(false)
    }
  }

  const filteredSubscriptions = subscriptions.filter(sub => {
    const searchLower = searchTerm.toLowerCase()
    return (
      sub.email?.toLowerCase().includes(searchLower) ||
      sub.nom_client?.toLowerCase().includes(searchLower) ||
      sub.prenom_client?.toLowerCase().includes(searchLower) ||
      sub.produit?.toLowerCase().includes(searchLower)
    )
  })

  const getStatusColor = (status) => {
    const statusMap = {
      'approuvé': 'bg-green-100 text-green-800',
      'rejeté': 'bg-red-100 text-red-800',
      'en_attente': 'bg-yellow-100 text-yellow-800',
      'approuve': 'bg-green-100 text-green-800',
      'rejete': 'bg-red-100 text-red-800'
    }
    return statusMap[status?.toLowerCase()] || 'bg-gray-100 text-gray-800'
  }

  const formatDate = (date) => {
    if (!date) return 'N/A'
    return new Date(date).toLocaleDateString('fr-FR')
  }

  const formatCurrency = (amount) => {
    if (!amount) return 'N/A'
    return new Intl.NumberFormat('fr-CI', { style: 'currency', currency: 'XOF' }).format(amount)
  }

  const handleFormChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  const handleViewSubscription = async (id) => {
    try {
      const data = await subscriptionsService.getById(id)
      setSelectedSubscription(data.subscription)
      setShowViewModal(true)
    } catch (error) {
      console.error('Erreur chargement souscription:', error)
      alert('Erreur lors du chargement de la souscription')
    }
  }

  const handleDeleteSubscription = async () => {
    try {
      await subscriptionsService.delete(selectedSubscription.id)
      setShowDeleteModal(false)
      setSelectedSubscription(null)
      fetchSubscriptions()
      alert('Souscription supprimée avec succès')
    } catch (error) {
      console.error('Erreur suppression souscription:', error)
      alert('Erreur lors de la suppression de la souscription')
    }
  }

  const handleCreateSubscription = async (e) => {
    e.preventDefault()
    try {
      await subscriptionsService.create(formData)
      setShowCreateModal(false)
      setFormData({
        nom_client: '',
        prenom_client: '',
        email: '',
        telephone: '',
        produit: '',
        montant: '',
        statut: 'en_attente'
      })
      fetchSubscriptions()
      alert('Souscription créée avec succès')
    } catch (error) {
      console.error('Erreur création souscription:', error)
      alert('Erreur lors de la création de la souscription')
    }
  }

  const handleUpdateStatus = async (id, status) => {
    try {
      await subscriptionsService.updateStatus(id, status)
      fetchSubscriptions()
    } catch (error) {
      console.error('Erreur mise à jour statut:', error)
      alert('Erreur lors de la mise à jour du statut')
    }
  }

  const handleApprove = async (id) => {
    try {
      await handleUpdateStatus(id, 'approuvé')
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  const handleReject = async (id) => {
    try {
      await handleUpdateStatus(id, 'rejeté')
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Souscriptions</h1>
          <p className="text-gray-600 mt-1">Approuvez ou rejetez les nouvelles souscriptions</p>
        </div>
        <button 
          onClick={() => setShowCreateModal(true)}
          className="flex items-center gap-2 bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition">
          <Plus className="w-5 h-5" />
          Nouvelle souscription
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Total</p>
          <p className="text-2xl font-bold text-coris-blue">{pagination.total}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Approuvées</p>
          <p className="text-2xl font-bold text-coris-green">{stats.by_status?.['approuvé'] || stats.by_status?.['approuve'] || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">En attente</p>
          <p className="text-2xl font-bold text-coris-orange">{stats.by_status?.['en_attente'] || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Rejetées</p>
          <p className="text-2xl font-bold text-coris-red">{stats.by_status?.['rejeté'] || stats.by_status?.['rejete'] || 0}</p>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="bg-white rounded-2xl shadow p-4">
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Rechercher par email, nom ou produit..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value)
              setPagination(prev => ({ ...prev, offset: 0 }))
            }}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
          >
            <option value="tous">Tous les statuts</option>
            <option value="en_attente">En attente</option>
            <option value="approuvé">Approuvées</option>
            <option value="rejeté">Rejetées</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-gray-500">Chargement des souscriptions...</div>
          </div>
        ) : filteredSubscriptions.length === 0 ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-gray-500">Aucune souscription trouvée</div>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-coris-gray border-b">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Souscripteur</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Email</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Produit</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Montant</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Origine</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Date</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filteredSubscriptions.map(sub => (
                <tr key={sub.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{sub.nom_client} {sub.prenom_client || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{sub.email || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{sub.produit || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{formatCurrency(sub.montant)}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">
                    <span className="inline-block px-2 py-1 rounded text-xs bg-blue-100 text-blue-800">
                      {sub.origin || 'N/A'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700">{formatDate(sub.created_at)}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(sub.statut)}`}>
                      {sub.statut || 'N/A'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm space-x-2 flex">
                    <button 
                      onClick={() => handleViewSubscription(sub.id)}
                      className="text-coris-blue hover:bg-blue-50 p-2 rounded transition">
                      <Eye className="w-4 h-4" />
                    </button>
                    {sub.statut?.toLowerCase() === 'en_attente' && (
                      <>
                        <button
                          onClick={() => handleApprove(sub.id)}
                          className="text-coris-green hover:bg-green-50 p-2 rounded transition"
                          title="Approuver"
                        >
                          <Check className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleReject(sub.id)}
                          className="text-coris-red hover:bg-red-50 p-2 rounded transition"
                          title="Rejeter"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </>
                    )}
                    <button
                      onClick={() => {
                        setSelectedSubscription(sub)
                        setShowDeleteModal(true)
                      }}
                      className="text-red-600 hover:bg-red-50 p-2 rounded transition"
                      title="Supprimer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {/* Pagination */}
        {filteredSubscriptions.length > 0 && (
          <div className="bg-gray-50 px-6 py-4 flex items-center justify-between border-t">
            <p className="text-sm text-gray-600">
              Affichage de {pagination.offset + 1} à {Math.min(pagination.offset + pagination.limit, pagination.total)} sur {pagination.total}
            </p>
            <div className="flex gap-2">
              <button
                disabled={pagination.offset === 0}
                onClick={() => setPagination(prev => ({ ...prev, offset: Math.max(0, prev.offset - prev.limit) }))}
                className="px-3 py-1 border border-gray-300 rounded hover:bg-gray-100 disabled:opacity-50"
              >
                Précédent
              </button>
              <button
                disabled={pagination.offset + pagination.limit >= pagination.total}
                onClick={() => setPagination(prev => ({ ...prev, offset: prev.offset + prev.limit }))}
                className="px-3 py-1 border border-gray-300 rounded hover:bg-gray-100 disabled:opacity-50"
              >
                Suivant
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Create Subscription Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Nouvelle souscription</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleCreateSubscription} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nom Client *</label>
                <input
                  type="text"
                  value={formData.nom_client}
                  onChange={(e) => handleFormChange('nom_client', e.target.value)}
                  placeholder="Nom du client"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Prénom Client *</label>
                <input
                  type="text"
                  value={formData.prenom_client}
                  onChange={(e) => handleFormChange('prenom_client', e.target.value)}
                  placeholder="Prénom du client"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => handleFormChange('email', e.target.value)}
                  placeholder="Email du client"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
                <input
                  type="tel"
                  value={formData.telephone}
                  onChange={(e) => handleFormChange('telephone', e.target.value)}
                  placeholder="Téléphone du client"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Produit *</label>
                <input
                  type="text"
                  value={formData.produit}
                  onChange={(e) => handleFormChange('produit', e.target.value)}
                  placeholder="Produit souscrit"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Montant</label>
                <input
                  type="number"
                  value={formData.montant}
                  onChange={(e) => handleFormChange('montant', e.target.value)}
                  placeholder="Montant de la souscription"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-coris-blue text-white rounded-lg hover:bg-coris-blue-light transition"
                >
                  Créer la souscription
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Subscription Modal */}
      {showViewModal && selectedSubscription && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Détails de la souscription</h2>
              <button
                onClick={() => setShowViewModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Nom Client</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.nom_client}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Prénom Client</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.prenom_client}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Email</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.email}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Téléphone</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.telephone || '-'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Produit</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.produit}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Montant</label>
                <p className="mt-1 text-sm text-gray-900">{formatCurrency(selectedSubscription.montant)}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Statut</label>
                <p className="mt-1 text-sm">
                  <span className={`inline-block px-2 py-1 rounded text-white text-xs font-semibold ${
                    selectedSubscription.statut?.toLowerCase() === 'approuvé' || selectedSubscription.statut?.toLowerCase() === 'approuve' ? 'bg-green-500' :
                    selectedSubscription.statut?.toLowerCase() === 'rejeté' || selectedSubscription.statut?.toLowerCase() === 'rejete' ? 'bg-red-500' :
                    'bg-yellow-500'
                  }`}>
                    {selectedSubscription.statut}
                  </span>
                </p>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  onClick={() => setShowViewModal(false)}
                  className="flex-1 px-4 py-2 bg-coris-blue text-white rounded-lg hover:bg-coris-blue-light transition"
                >
                  Fermer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Subscription Modal */}
      {showDeleteModal && selectedSubscription && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Confirmer la suppression</h2>
              <button
                onClick={() => setShowDeleteModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6">
              <p className="text-gray-700 mb-2">
                Êtes-vous sûr de vouloir supprimer la souscription de <strong>{selectedSubscription.nom_client} {selectedSubscription.prenom_client}</strong> ?
              </p>
              <p className="text-gray-600 text-sm mb-6">
                Cette action est irréversible.
              </p>

              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setShowDeleteModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={handleDeleteSubscription}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
                >
                  Supprimer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
