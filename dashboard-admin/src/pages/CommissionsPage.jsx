import React, { useState, useEffect } from 'react'
import { Search, Eye, TrendingUp, Users, Plus, Trash2, X } from 'lucide-react'
import { commissionsService } from '../services/api.service'

export default function CommissionsPage() {
  const [commissions, setCommissions] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [selectedCommission, setSelectedCommission] = useState(null)
  const [formData, setFormData] = useState({
    code_apporteur: '',
    montant_commission: '',
    date_calcul: new Date().toISOString().split('T')[0]
  })

  useEffect(() => {
    fetchCommissions()
    fetchStats()
  }, [pagination.offset])

  const fetchCommissions = async () => {
    try {
      setLoading(true)
      const params = {
        limit: pagination.limit,
        offset: pagination.offset
      }
      const data = await commissionsService.getAll(params)
      setCommissions(data.commissions || [])
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
    } catch (error) {
      console.error('Erreur:', error)
      alert('Erreur lors du chargement des commissions')
    } finally {
      setLoading(false)
    }
  }

  const fetchStats = async () => {
    try {
      const data = await commissionsService.getStats()
      setStats(data.stats || {})
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  const filteredCommissions = commissions.filter(comm => {
    const searchLower = searchTerm.toLowerCase()
    return (
      comm.code_apporteur?.toLowerCase().includes(searchLower) ||
      comm.nom?.toLowerCase().includes(searchLower) ||
      comm.prenom?.toLowerCase().includes(searchLower)
    )
  })

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

  const handleViewCommission = async (id) => {
    try {
      const data = await commissionsService.getById(id)
      setSelectedCommission(data.commission)
      setShowViewModal(true)
    } catch (error) {
      console.error('Erreur chargement commission:', error)
      alert('Erreur lors du chargement de la commission')
    }
  }

  const handleDeleteCommission = async () => {
    try {
      await commissionsService.delete(selectedCommission.id)
      setShowDeleteModal(false)
      setSelectedCommission(null)
      fetchCommissions()
      fetchStats()
      alert('Commission supprimée avec succès')
    } catch (error) {
      console.error('Erreur suppression commission:', error)
      alert('Erreur lors de la suppression de la commission')
    }
  }

  const handleCreateCommission = async (e) => {
    e.preventDefault()
    try {
      await commissionsService.create(formData)
      setShowCreateModal(false)
      setFormData({
        code_apporteur: '',
        montant_commission: '',
        date_calcul: new Date().toISOString().split('T')[0]
      })
      fetchCommissions()
      fetchStats()
      alert('Commission créée avec succès')
    } catch (error) {
      console.error('Erreur création commission:', error)
      alert('Erreur lors de la création de la commission')
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Commissions</h1>
          <p className="text-gray-600 mt-1">Suivez les commissions des commerciaux</p>
        </div>
        <button 
          onClick={() => setShowCreateModal(true)}
          className="flex items-center gap-2 bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition">
          <Plus className="w-5 h-5" />
          Nouvelle commission
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Total Commissions</p>
              <p className="text-2xl font-bold text-coris-blue">{stats?.total_commissions || 0}</p>
            </div>
            <TrendingUp className="w-8 h-8 text-coris-blue opacity-20" />
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Montant Total</p>
              <p className="text-xl font-bold text-coris-green">{formatCurrency(stats?.total_montant)}</p>
            </div>
            <TrendingUp className="w-8 h-8 text-coris-green opacity-20" />
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Commerciaux</p>
              <p className="text-2xl font-bold text-coris-orange">{stats?.total_commerciaux || 0}</p>
            </div>
            <Users className="w-8 h-8 text-coris-orange opacity-20" />
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Moyenne par Commission</p>
              <p className="text-xl font-bold text-coris-red">
                {formatCurrency(
                  stats?.total_commissions && stats?.total_montant
                    ? stats.total_montant / stats.total_commissions
                    : 0
                )}
              </p>
            </div>
            <TrendingUp className="w-8 h-8 text-coris-red opacity-20" />
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="bg-white rounded-2xl shadow p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Rechercher par code commercial ou nom..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-gray-500">Chargement des commissions...</div>
          </div>
        ) : filteredCommissions.length === 0 ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-gray-500">Aucune commission trouvée</div>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-coris-gray border-b">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Code Commercial</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Nom</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Montant</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Date</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filteredCommissions.map(comm => (
                <tr key={comm.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{comm.code_apporteur}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">
                    {comm.prenom && comm.nom ? `${comm.prenom} ${comm.nom}` : 'N/A'}
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold text-coris-green">{formatCurrency(comm.montant_commission)}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{formatDate(comm.date_calcul)}</td>
                  <td className="px-6 py-4 text-sm space-x-2 flex">
                    <button 
                      onClick={() => handleViewCommission(comm.id)}
                      className="text-coris-blue hover:bg-blue-50 p-2 rounded transition">
                      <Eye className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => {
                        setSelectedCommission(comm)
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
        {filteredCommissions.length > 0 && (
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

      {/* Create Commission Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Nouvelle commission</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleCreateCommission} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Code Apporteur *</label>
                <input
                  type="text"
                  value={formData.code_apporteur}
                  onChange={(e) => handleFormChange('code_apporteur', e.target.value)}
                  placeholder="Code du commercial"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Montant Commission *</label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.montant_commission}
                  onChange={(e) => handleFormChange('montant_commission', e.target.value)}
                  placeholder="Montant de la commission"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Date de Calcul</label>
                <input
                  type="date"
                  value={formData.date_calcul}
                  onChange={(e) => handleFormChange('date_calcul', e.target.value)}
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
                  Créer la commission
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Commission Modal */}
      {showViewModal && selectedCommission && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Détails de la commission</h2>
              <button
                onClick={() => setShowViewModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Code Apporteur</label>
                <p className="mt-1 text-sm text-gray-900">{selectedCommission.code_apporteur}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Nom Commercial</label>
                <p className="mt-1 text-sm text-gray-900">
                  {selectedCommission.prenom && selectedCommission.nom 
                    ? `${selectedCommission.prenom} ${selectedCommission.nom}` 
                    : 'N/A'}
                </p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Email</label>
                <p className="mt-1 text-sm text-gray-900">{selectedCommission.email || '-'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Montant Commission</label>
                <p className="mt-1 text-sm font-semibold text-coris-green">
                  {formatCurrency(selectedCommission.montant_commission)}
                </p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Date de Calcul</label>
                <p className="mt-1 text-sm text-gray-900">
                  {formatDate(selectedCommission.date_calcul)}
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

      {/* Delete Commission Modal */}
      {showDeleteModal && selectedCommission && (
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
                Êtes-vous sûr de vouloir supprimer la commission de <strong>{selectedCommission.code_apporteur}</strong> ?
              </p>
              <p className="text-gray-600 text-sm mb-2">
                Montant: <strong>{formatCurrency(selectedCommission.montant_commission)}</strong>
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
                  onClick={handleDeleteCommission}
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
