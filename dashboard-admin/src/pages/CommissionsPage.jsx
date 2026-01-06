import React, { useState, useEffect } from 'react'
import { Search, Eye, TrendingUp, Users } from 'lucide-react'
import { commissionsService } from '../services/api.service'

export default function CommissionsPage() {
  const [commissions, setCommissions] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })

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
      comm.user?.nom?.toLowerCase().includes(searchLower) ||
      comm.user?.prenom?.toLowerCase().includes(searchLower)
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

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Gestion des Commissions</h1>
        <p className="text-gray-600 mt-1">Suivez les commissions des commerciaux</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Total Commissions</p>
              <p className="text-2xl font-bold text-coris-blue">{stats?.total_commissions || 0}</p>
            </div>
            <TrendingUp className="w-8 h-8 text-coris-blue opacity-20" />
          </div>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Montant Total</p>
              <p className="text-xl font-bold text-coris-green">{formatCurrency(stats?.total_montant)}</p>
            </div>
            <TrendingUp className="w-8 h-8 text-coris-green opacity-20" />
          </div>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm mb-1">Commerciaux</p>
              <p className="text-2xl font-bold text-coris-orange">{stats?.total_commerciaux || 0}</p>
            </div>
            <Users className="w-8 h-8 text-coris-orange opacity-20" />
          </div>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
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
      <div className="bg-white rounded-lg shadow p-4">
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
      <div className="bg-white rounded-lg shadow overflow-hidden">
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
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Statut</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filteredCommissions.map(comm => (
                <tr key={comm.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{comm.code_apporteur}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">
                    {comm.user ? `${comm.user.prenom} ${comm.user.nom}` : 'N/A'}
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold text-coris-green">{formatCurrency(comm.montant)}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{formatDate(comm.date_creation)}</td>
                  <td className="px-6 py-4">
                    <span className="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800">
                      Validée
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm">
                    <button className="text-coris-blue hover:bg-blue-50 p-2 rounded transition">
                      <Eye className="w-4 h-4" />
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
    </div>
  )
}
