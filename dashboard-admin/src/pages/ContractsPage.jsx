import React, { useState, useEffect } from 'react'
import { Search, Eye, Edit, Trash2, Filter, Plus, X } from 'lucide-react'
import { contractsService } from '../services/api.service'

export default function ContractsPage() {
  const [contracts, setContracts] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('tous')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })
  const [stats, setStats] = useState({ by_status: {} })
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [selectedContract, setSelectedContract] = useState(null)
  const [formData, setFormData] = useState({
    numepoli: '',
    nom_prenom: '',
    codeprod: '',
    dateeffet: '',
    etat: 'en_attente',
    email: '',
    telephone: ''
  })

  useEffect(() => {
    fetchContracts()
  }, [statusFilter, pagination.offset])

  const fetchContracts = async () => {
    try {
      setLoading(true)
      const params = {
        status: statusFilter === 'tous' ? undefined : statusFilter,
        limit: pagination.limit,
        offset: pagination.offset
      }
      const data = await contractsService.getAll(params)
      setContracts(data.contracts || [])
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
      setStats(data.stats || { by_status: {} })
    } catch (error) {
      console.error('Erreur lors du chargement des contrats:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredContracts = contracts.filter(contract => {
    const searchLower = searchTerm.toLowerCase()
    return (
      contract.numepoli?.toLowerCase().includes(searchLower) ||
      contract.nom_prenom?.toLowerCase().includes(searchLower) ||
      contract.codeprod?.toLowerCase().includes(searchLower)
    )
  })

  const getStatusColor = (status) => {
    const statusMap = {
      'actif': 'bg-green-100 text-green-800',
      'suspendu': 'bg-red-100 text-red-800',
      'en_attente': 'bg-yellow-100 text-yellow-800',
      'resilie': 'bg-gray-100 text-gray-800'
    }
    return statusMap[status?.toLowerCase()] || 'bg-gray-100 text-gray-800'
  }

  const getStatusLabel = (status) => {
    const labels = {
      'actif': 'Actif',
      'suspendu': 'Suspendu',
      'en_attente': 'En attente',
      'resilie': 'Résilié'
    }
    return labels[status?.toLowerCase()] || status || 'N/A'
  }

  const formatDate = (date) => {
    if (!date) return 'N/A'
    return new Date(date).toLocaleDateString('fr-FR')
  }

  const handleUpdateStatus = async (id, nextStatus) => {
    try {
      await contractsService.updateStatus(id, nextStatus)
      fetchContracts()
    } catch (error) {
      console.error('Erreur mise à jour statut:', error)
      alert('Erreur lors de la mise à jour du statut')
    }
  }

  const handleViewContract = async (id) => {
    try {
      const data = await contractsService.getById(id)
      setSelectedContract(data.contract)
      setShowViewModal(true)
    } catch (error) {
      console.error('Erreur chargement contrat:', error)
      alert('Erreur lors du chargement du contrat')
    }
  }

  const handleDeleteContract = async () => {
    try {
      await contractsService.delete(selectedContract.id)
      setShowDeleteModal(false)
      setSelectedContract(null)
      fetchContracts()
      alert('Contrat supprimé avec succès')
    } catch (error) {
      console.error('Erreur suppression contrat:', error)
      alert('Erreur lors de la suppression du contrat')
    }
  }

  const handleCreateContract = async (e) => {
    e.preventDefault()
    try {
      await contractsService.create(formData)
      setShowCreateModal(false)
      setFormData({
        numepoli: '',
        nom_prenom: '',
        codeprod: '',
        dateeffet: '',
        etat: 'en_attente',
        email: '',
        telephone: ''
      })
      fetchContracts()
      alert('Contrat créé avec succès')
    } catch (error) {
      console.error('Erreur création contrat:', error)
      alert(error.response?.data?.message || 'Erreur lors de la création du contrat')
    }
  }

  const handleFormChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Contrats</h1>
          <p className="text-gray-600 mt-1">Gérez et supervisez tous les contrats d'assurance</p>
        </div>
        <button 
          onClick={() => setShowCreateModal(true)}
          className="flex items-center gap-2 bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition">
          <Plus className="w-5 h-5" />
          Nouveau contrat
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-5 gap-4">
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Total Contrats</p>
          <p className="text-2xl font-bold text-coris-blue">{pagination.total}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Actifs</p>
          <p className="text-2xl font-bold text-coris-green">{stats.by_status?.actif || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">En attente</p>
          <p className="text-2xl font-bold text-coris-orange">{stats.by_status?.en_attente || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Suspendus</p>
          <p className="text-2xl font-bold text-coris-red">{stats.by_status?.suspendu || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Résiliés</p>
          <p className="text-2xl font-bold text-gray-700">{stats.by_status?.resilie || 0}</p>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="bg-white rounded-lg shadow p-4 space-y-4">
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Rechercher par numéro de police, nom ou produit..."
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
            <option value="actif">Actifs</option>
            <option value="suspendu">Suspendus</option>
            <option value="en_attente">En attente</option>
            <option value="resilie">Résiliés</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-gray-500">Chargement des contrats...</div>
          </div>
        ) : filteredContracts.length === 0 ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-gray-500">Aucun contrat trouvé</div>
          </div>
        ) : (
          <div className="overflow-auto max-h-[70vh]">
            <table className="w-full table-auto">
            <thead className="bg-coris-gray border-b">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">N° Police</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Assuré</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Produit</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Date Effet</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filteredContracts.map(contract => (
                <tr key={contract.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{contract.numepoli}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{contract.nom_prenom || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{contract.codeprod || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{formatDate(contract.dateeffet)}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(contract.etat)}`}>
                      {getStatusLabel(contract.etat)}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm space-x-2 flex">
                      <button 
                        onClick={() => handleViewContract(contract.id)}
                        className="text-coris-blue hover:bg-blue-50 p-2 rounded transition" title="Voir">
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleUpdateStatus(contract.id, 'actif')}
                        className="text-green-600 hover:bg-green-50 p-2 rounded transition" title="Activer">
                        Activer
                      </button>
                      <button
                        onClick={() => handleUpdateStatus(contract.id, 'suspendu')}
                        className="text-orange-600 hover:bg-orange-50 p-2 rounded transition" title="Suspendre">
                        Suspendre
                      </button>
                      <button
                        onClick={() => {
                          setSelectedContract(contract)
                          setShowDeleteModal(true)
                        }}
                        className="text-red-600 hover:bg-red-50 p-2 rounded transition" title="Supprimer">
                        <Trash2 className="w-4 h-4" />
                      </button>
                  </td>
                </tr>
              ))}
            </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        {filteredContracts.length > 0 && (
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

      {/* Modal Création Contrat */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg max-w-md w-full max-h-screen overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Créer un nouveau contrat</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleCreateContract} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">N° Police *</label>
                <input
                  type="text"
                  value={formData.numepoli}
                  onChange={(e) => handleFormChange('numepoli', e.target.value)}
                  placeholder="Numéro de police"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nom Assuré *</label>
                <input
                  type="text"
                  value={formData.nom_prenom}
                  onChange={(e) => handleFormChange('nom_prenom', e.target.value)}
                  placeholder="Nom complet de l'assuré"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Code Produit *</label>
                <input
                  type="text"
                  value={formData.codeprod}
                  onChange={(e) => handleFormChange('codeprod', e.target.value)}
                  placeholder="Code produit d'assurance"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Date d'effet *</label>
                <input
                  type="date"
                  value={formData.dateeffet}
                  onChange={(e) => handleFormChange('dateeffet', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Statut *</label>
                <select
                  value={formData.etat}
                  onChange={(e) => handleFormChange('etat', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                >
                  <option value="en_attente">En attente</option>
                  <option value="actif">Actif</option>
                  <option value="suspendu">Suspendu</option>
                  <option value="resilie">Résilié</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => handleFormChange('email', e.target.value)}
                  placeholder="Email de l'assuré"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
                <input
                  type="tel"
                  value={formData.telephone}
                  onChange={(e) => handleFormChange('telephone', e.target.value)}
                  placeholder="Téléphone de l'assuré"
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
                  Créer le contrat
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Contract Modal */}
      {showViewModal && selectedContract && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Détails du contrat</h2>
              <button
                onClick={() => setShowViewModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">N° Police</label>
                <p className="mt-1 text-sm text-gray-900">{selectedContract.numepoli}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Nom Assuré</label>
                <p className="mt-1 text-sm text-gray-900">{selectedContract.nom_prenom}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Code Produit</label>
                <p className="mt-1 text-sm text-gray-900">{selectedContract.codeprod || '-'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Date d'Effet</label>
                <p className="mt-1 text-sm text-gray-900">
                  {selectedContract.dateeffet ? new Date(selectedContract.dateeffet).toLocaleDateString('fr-FR') : '-'}
                </p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">État</label>
                <p className="mt-1 text-sm">
                  <span className={`inline-block px-2 py-1 rounded text-white text-xs font-semibold ${
                    selectedContract.etat === 'actif' ? 'bg-green-500' :
                    selectedContract.etat === 'suspendu' ? 'bg-orange-500' :
                    selectedContract.etat === 'en_attente' ? 'bg-blue-500' :
                    'bg-red-500'
                  }`}>
                    {selectedContract.etat}
                  </span>
                </p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Email</label>
                <p className="mt-1 text-sm text-gray-900">{selectedContract.email || '-'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Téléphone</label>
                <p className="mt-1 text-sm text-gray-900">{selectedContract.telephone || '-'}</p>
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

      {/* Delete Contract Modal */}
      {showDeleteModal && selectedContract && (
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
                Êtes-vous sûr de vouloir supprimer le contrat <strong>{selectedContract.numepoli}</strong> ?
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
                  onClick={handleDeleteContract}
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
