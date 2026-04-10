import React, { useState, useEffect } from 'react'
import { Search, Eye, Filter, Download, FileText, X, FolderDown, ClipboardList } from 'lucide-react'
import { contractsService } from '../services/api.service'
import API_URL from '../config'

export default function ContractsPage() {
  const [contracts, setContracts] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('tous')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })
  const [stats, setStats] = useState({ by_status: {} })
  const [showViewModal, setShowViewModal] = useState(false)
  const [selectedContract, setSelectedContract] = useState(null)

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
      console.log('Contrats chargés:', data)
      setContracts(data.contracts || [])
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
      setStats(data.stats || { by_status: {} })
    } catch (error) {
      console.error('Erreur lors du chargement des contrats:', error)
      alert('Erreur: ' + error.message)
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

  const handleExportExcel = () => {
    alert('Export Excel en cours de développement...')
  }

  const handleExportPDF = () => {
    alert('Export PDF en cours de développement...')
  }

  const PRODUCTS_WITH_QUESTIONNAIRE = ['coris_serenite', 'coris_familis', 'coris_etude']
  const hasQuestionnaire = (produit_nom) => {
    const nom = (produit_nom || '').toLowerCase().trim()
    return PRODUCTS_WITH_QUESTIONNAIRE.some(p => nom.includes(p) || nom === p)
  }

  const handleDownloadPDF = async (contract) => {
    const subId = contract.subscription_id
    if (!subId) { alert('Aucune souscription liée à ce contrat'); return }
    try {
      const token = localStorage.getItem('adminToken')
      const response = await fetch(`${API_URL}/subscriptions/${subId}/pdf`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      if (!response.ok) throw new Error((await response.json()).message || `Erreur ${response.status}`)
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `contrat_${contract.numepoli}.pdf`
      document.body.appendChild(a); a.click()
      window.URL.revokeObjectURL(url); document.body.removeChild(a)
    } catch (error) { alert(`Erreur: ${error.message}`) }
  }

  const handleDownloadDocuments = async (contract) => {
    const subId = contract.subscription_id
    if (!subId) { alert('Aucune souscription liée à ce contrat'); return }
    try {
      const token = localStorage.getItem('adminToken')
      const response = await fetch(`${API_URL}/admin/subscriptions/${subId}/documents/download`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      if (!response.ok) throw new Error((await response.json()).message || `Erreur ${response.status}`)
      const blob = await response.blob()
      if (blob.size === 0) throw new Error('Aucun document disponible')
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `documents_${contract.numepoli}.zip`
      document.body.appendChild(a); a.click()
      window.URL.revokeObjectURL(url); document.body.removeChild(a)
    } catch (error) { alert(`Erreur: ${error.message}`) }
  }

  const handlePrintQuestionnaire = (contract) => {
    const subId = contract.subscription_id
    if (!subId) { alert('Aucune souscription liée à ce contrat'); return }
    const token = localStorage.getItem('adminToken')
    const url = `${API_URL}/admin/subscriptions/${subId}/questionnaire-medical/print`
    const win = window.open('about:blank', '_blank')
    win.document.write('<html><body><p style="font-family:sans-serif;padding:20px">Chargement...</p></body></html>')
    fetch(url, { headers: { Authorization: `Bearer ${token}` } })
      .then(r => { if (!r.ok) return r.json().then(d => { throw new Error(d.message || `Erreur ${r.status}`) }); return r.text() })
      .then(html => { win.document.open(); win.document.write(html); win.document.close() })
      .catch(err => { win.close(); alert(`Erreur: ${err.message}`) })
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Contrats</h1>
          <p className="text-gray-600 mt-1">Consultez et exportez tous les contrats d'assurance</p>
        </div>
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
                        className="text-coris-blue hover:bg-blue-50 p-2 rounded transition" title="Voir détails">
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDownloadPDF(contract)}
                        className="text-green-600 hover:bg-green-50 p-2 rounded transition"
                        title="Télécharger PDF contrat">
                        <Download className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDownloadDocuments(contract)}
                        className="text-purple-600 hover:bg-purple-50 p-2 rounded transition"
                        title="Télécharger pièces d'identité (ZIP)">
                        <FolderDown className="w-4 h-4" />
                      </button>
                      {hasQuestionnaire(contract.produit_nom) && (
                        <button
                          onClick={() => handlePrintQuestionnaire(contract)}
                          className="text-orange-600 hover:bg-orange-50 p-2 rounded transition"
                          title="Questionnaire médical">
                          <ClipboardList className="w-4 h-4" />
                        </button>
                      )}
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
                  onClick={() => handleDownloadPDF(selectedContract)}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition">
                  <Download className="w-4 h-4" /> PDF
                </button>
                <button
                  onClick={() => handleDownloadDocuments(selectedContract)}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition">
                  <FolderDown className="w-4 h-4" /> Pièces
                </button>
                {selectedContract && hasQuestionnaire(selectedContract.produit_nom) && (
                  <button
                    onClick={() => handlePrintQuestionnaire(selectedContract)}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition">
                    <ClipboardList className="w-4 h-4" /> Questionnaire
                  </button>
                )}
                <button
                  onClick={() => setShowViewModal(false)}
                  className="flex-1 px-4 py-2 bg-coris-blue text-white rounded-lg hover:bg-coris-blue-light transition">
                  Fermer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
