import React, { useState, useEffect } from 'react'
import { Search, Eye, FileText, Download } from 'lucide-react'
import { subscriptionsService } from '../services/api.service'

export default function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('tous')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })
  const [stats, setStats] = useState({ by_status: {} })
  const [showViewModal, setShowViewModal] = useState(false)
  const [selectedSubscription, setSelectedSubscription] = useState(null)

  useEffect(() => {
    fetchSubscriptions()
  }, [statusFilter, pagination.offset])

  function mapSubscription(sub) {
    const data = sub?.souscriptiondata || {}
    const clientInfo = data.client_info || {}
    const montant = sub?.montant ?? data.montant ?? data.prime_totale ?? data.montant_total ?? data.prime ?? null

    return {
      ...sub,
      client_nom: clientInfo.nom || sub.creator_nom || 'N/A',
      client_prenom: clientInfo.prenom || sub.creator_prenom || 'N/A',
      client_email: clientInfo.email || sub.creator_email || 'N/A',
      client_telephone: clientInfo.telephone || sub.creator_telephone || 'N/A',
      montant_display: montant
    }
  }

  const fetchSubscriptions = async () => {
    try {
      setLoading(true)
      const params = {
        limit: pagination.limit,
        offset: pagination.offset,
        ...(statusFilter !== 'tous' && { statut: statusFilter })
      }
      const data = await subscriptionsService.getAll(params)
      console.log('Souscriptions chargées:', data)

      const mappedSubs = (data.subscriptions || []).map(mapSubscription)
      setSubscriptions(mappedSubs)
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
      setStats(data.stats || { by_status: {} })
    } catch (error) {
      console.error('Erreur chargement souscriptions:', error)
      alert('Erreur lors du chargement des souscriptions: ' + error.message)
    } finally {
      setLoading(false)
    }
  }

  const handleExportExcel = () => {
    alert('Export Excel en développement')
  }

  const handleExportPDF = () => {
    alert('Export PDF en développement')
  }

  const filteredSubscriptions = subscriptions.filter(sub => {
    const searchLower = searchTerm.toLowerCase()
    return (
      sub.client_nom?.toLowerCase().includes(searchLower) ||
      sub.client_prenom?.toLowerCase().includes(searchLower) ||
      sub.client_email?.toLowerCase().includes(searchLower) ||
      sub.produit_nom?.toLowerCase().includes(searchLower) ||
      sub.numero_souscription?.toLowerCase().includes(searchLower)
    )
  })

  const formatDate = (date) => {
    if (!date) return 'N/A'
    return new Date(date).toLocaleDateString('fr-FR')
  }

  const formatMontant = (montant) => {
    if (!montant && montant !== 0) return 'N/A'
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF' }).format(montant)
  }

  const getStatusBadge = (statut) => {
    const statusMap = {
      'brouillon': 'bg-gray-100 text-gray-800',
      'proposition': 'bg-blue-100 text-blue-800',
      'payé': 'bg-green-100 text-green-800',
      'contrat': 'bg-purple-100 text-purple-800',
      'activé': 'bg-emerald-100 text-emerald-800',
      'annulé': 'bg-red-100 text-red-800',
      'suspendu': 'bg-orange-100 text-orange-800'
    }
    const colorClass = statusMap[statut?.toLowerCase()] || 'bg-gray-100 text-gray-800'
    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full ${colorClass}`}>
        {statut || 'Inconnu'}
      </span>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Souscriptions</h1>
          <p className="text-gray-600 mt-1">Consultation des souscriptions</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={handleExportExcel}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
          >
            <Download className="w-4 h-4" />
            Export Excel
          </button>
          <button
            onClick={handleExportPDF}
            className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
          >
            <FileText className="w-4 h-4" />
            Export PDF
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-sm text-gray-600">Total</div>
          <div className="text-2xl font-bold text-gray-900">{pagination.total}</div>
        </div>
        <div className="bg-blue-50 p-4 rounded-lg shadow">
          <div className="text-sm text-blue-600">Propositions</div>
          <div className="text-2xl font-bold text-blue-900">{stats.by_status?.proposition || 0}</div>
        </div>
        <div className="bg-green-50 p-4 rounded-lg shadow">
          <div className="text-sm text-green-600">Contrats</div>
          <div className="text-2xl font-bold text-green-900">{stats.by_status?.contrat || 0}</div>
        </div>
        <div className="bg-purple-50 p-4 rounded-lg shadow">
          <div className="text-sm text-purple-600">Activés</div>
          <div className="text-2xl font-bold text-purple-900">{stats.by_status?.activé || 0}</div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Rechercher par nom, email, N° souscription..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-coris-blue focus:border-transparent"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-coris-blue focus:border-transparent"
          >
            <option value="tous">Tous les statuts</option>
            <option value="brouillon">Brouillon</option>
            <option value="proposition">Proposition</option>
            <option value="payé">Payé</option>
            <option value="contrat">Contrat</option>
            <option value="activé">Activé</option>
            <option value="annulé">Annulé</option>
            <option value="suspendu">Suspendu</option>
          </select>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div className="bg-white rounded-lg shadow p-8 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement...</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">N° Souscription</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Produit</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Montant</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredSubscriptions.map((sub) => (
                  <tr key={sub.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {sub.numero_souscription || `SUB-${sub.id}`}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {sub.client_prenom} {sub.client_nom}
                      </div>
                      <div className="text-sm text-gray-500">{sub.client_email}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {sub.produit_nom || 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatMontant(sub.montant_display)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(sub.date_souscription || sub.created_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(sub.statut)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button
                        onClick={() => {
                          setSelectedSubscription(sub)
                          setShowViewModal(true)
                        }}
                        className="text-coris-blue hover:bg-blue-50 p-2 rounded transition"
                        title="Voir détails"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {filteredSubscriptions.length > 0 && (
            <div className="bg-gray-50 px-6 py-4 flex items-center justify-between border-t">
              <div className="text-sm text-gray-700">
                Affichage de {pagination.offset + 1} à {Math.min(pagination.offset + pagination.limit, pagination.total)} sur {pagination.total} résultats
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setPagination(prev => ({ ...prev, offset: Math.max(0, prev.offset - prev.limit) }))}
                  disabled={pagination.offset === 0}
                  className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Précédent
                </button>
                <button
                  onClick={() => setPagination(prev => ({ ...prev, offset: prev.offset + prev.limit }))}
                  disabled={pagination.offset + pagination.limit >= pagination.total}
                  className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Suivant
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* View Modal */}
      {showViewModal && selectedSubscription && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Détails de la souscription</h2>
              <button onClick={() => setShowViewModal(false)} className="text-gray-500 hover:text-gray-700">
                ×
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-500">N° Souscription</label>
                  <p className="text-gray-900">{selectedSubscription.numero_souscription || `SUB-${selectedSubscription.id}`}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Statut</label>
                  <div className="mt-1">{getStatusBadge(selectedSubscription.statut)}</div>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Client</label>
                  <p className="text-gray-900">{selectedSubscription.client_prenom} {selectedSubscription.client_nom}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Email</label>
                  <p className="text-gray-900">{selectedSubscription.client_email}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Téléphone</label>
                  <p className="text-gray-900">{selectedSubscription.client_telephone || 'N/A'}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Produit</label>
                  <p className="text-gray-900">{selectedSubscription.produit_nom || 'N/A'}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Montant</label>
                  <p className="text-gray-900">{formatMontant(selectedSubscription.montant_display)}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-500">Date de souscription</label>
                  <p className="text-gray-900">{formatDate(selectedSubscription.date_souscription || selectedSubscription.created_at)}</p>
                </div>
              </div>
            </div>
            <div className="flex justify-end gap-2 p-6 border-t bg-gray-50">
              <button
                onClick={() => setShowViewModal(false)}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
