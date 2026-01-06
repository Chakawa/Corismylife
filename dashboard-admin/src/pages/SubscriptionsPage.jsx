import React, { useState, useEffect } from 'react'
import { Search, Check, X, Eye, Plus } from 'lucide-react'
import { subscriptionsService } from '../services/api.service'

export default function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('tous')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })

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
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
    } catch (error) {
      console.error('Erreur:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredSubscriptions = subscriptions.filter(sub => {
    const searchLower = searchTerm.toLowerCase()
    return (
      sub.email?.toLowerCase().includes(searchLower) ||
      sub.nom_prenom?.toLowerCase().includes(searchLower) ||
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

  const handleApprove = async (id) => {
    try {
      await subscriptionsService.approve(id)
      fetchSubscriptions()
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  const handleReject = async (id) => {
    try {
      await subscriptionsService.reject(id, 'Rejeté par administrateur')
      fetchSubscriptions()
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
        <button className="flex items-center gap-2 bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition">
          <Plus className="w-5 h-5" />
          Nouvelle souscription
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Total</p>
          <p className="text-2xl font-bold text-coris-blue">{pagination.total}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Approuvées</p>
          <p className="text-2xl font-bold text-coris-green">{subscriptions.filter(s => s.statut?.toLowerCase() === 'approuvé' || s.statut?.toLowerCase() === 'approuve').length}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">En attente</p>
          <p className="text-2xl font-bold text-coris-orange">{subscriptions.filter(s => s.statut?.toLowerCase() === 'en_attente').length}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Rejetées</p>
          <p className="text-2xl font-bold text-coris-red">{subscriptions.filter(s => s.statut?.toLowerCase() === 'rejeté' || s.statut?.toLowerCase() === 'rejete').length}</p>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="bg-white rounded-lg shadow p-4">
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
      <div className="bg-white rounded-lg shadow overflow-hidden">
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
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Date</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filteredSubscriptions.map(sub => (
                <tr key={sub.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{sub.nom_prenom || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{sub.email || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{sub.produit || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{formatDate(sub.date_creation)}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(sub.statut)}`}>
                      {sub.statut || 'N/A'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm space-x-2 flex">
                    <button className="text-coris-blue hover:bg-blue-50 p-2 rounded transition">
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
    </div>
  )
}
