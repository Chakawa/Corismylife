import { useState, useEffect } from 'react'
import {
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from 'recharts'
import { Calculator, TrendingUp, DollarSign, Users, Filter, Download, ChevronLeft, ChevronRight } from 'lucide-react'
import * as XLSX from 'xlsx'
import API_URL from '../config'

const COLORS = ['#002B6B', '#E30613', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899']
const API_BASE = API_URL
const PAGE_SIZE = 30

export default function SimulationsPage() {
  const [stats, setStats] = useState(null)
  const [simulations, setSimulations] = useState([])
  const [loading, setLoading] = useState(true)
  const [currentPage, setCurrentPage] = useState(0)
  const [filters, setFilters] = useState({
    produit: '',
    type_simulation: '',
    date_debut: '',
    date_fin: ''
  })

  useEffect(() => {
    loadData()
  }, [])

  useEffect(() => {
    setCurrentPage(0)
  }, [simulations])

  const loadData = async () => {
    setLoading(true)
    try {
      const token = localStorage.getItem('adminToken')
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }

      // Charger les statistiques
      const statsRes = await fetch(`${API_BASE}/simulations/stats`, { headers })
      if (statsRes.ok) {
        const statsData = await statsRes.json()
        setStats(statsData.stats)
      }

      // Charger les simulations
      const simsRes = await fetch(`${API_BASE}/simulations?limit=500`, { headers })
      if (simsRes.ok) {
        const simsData = await simsRes.json()
        setSimulations(simsData.data || [])
      }
    } catch (error) {
      console.error('Erreur chargement simulations:', error)
    } finally {
      setLoading(false)
    }
  }

  const applyFilters = async () => {
    setLoading(true)
    try {
      const token = localStorage.getItem('adminToken')
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }

      const params = new URLSearchParams()
      if (filters.produit) params.append('produit', filters.produit)
      if (filters.type_simulation) params.append('type_simulation', filters.type_simulation)
      if (filters.date_debut) params.append('date_debut', filters.date_debut)
      if (filters.date_fin) params.append('date_fin', filters.date_fin)

      const [statsRes, simsRes] = await Promise.all([
        fetch(`${API_BASE}/simulations/stats?${params}`, { headers }),
        fetch(`${API_BASE}/simulations?${params}&limit=500`, { headers })
      ])

      if (statsRes.ok) {
        const statsData = await statsRes.json()
        setStats(statsData.stats)
      }

      if (simsRes.ok) {
        const simsData = await simsRes.json()
        setSimulations(simsData.data || [])
      }
    } catch (error) {
      console.error('Erreur application filtres:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatMoney = (value) => {
    if (!value) return '0 FCFA'
    return `${Math.round(value).toLocaleString('fr-FR')} FCFA`
  }

  const formatDate = (date) => {
    if (!date) return '-'
    return new Date(date).toLocaleString('fr-FR', {
      day: '2-digit', month: '2-digit', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  }

  const exportToExcel = () => {
    const data = simulations.map((sim) => ({
      'Date & Heure': formatDate(sim.created_at),
      'Produit': sim.produit_nom || '-',
      'Type': sim.type_simulation || '-',
      'Capital (FCFA)': sim.capital ? Math.round(sim.capital) : 0,
      'Prime (FCFA)': sim.prime ? Math.round(sim.prime) : 0,
      'Durée (mois)': sim.duree_mois || '-',
      'Client': sim.user_name || 'Anonyme',
    }))
    const ws = XLSX.utils.json_to_sheet(data)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Simulations')
    let periodLabel = ''
    if (filters.date_debut && filters.date_fin) periodLabel = `_${filters.date_debut}_au_${filters.date_fin}`
    else if (filters.date_debut) periodLabel = `_depuis_${filters.date_debut}`
    else if (filters.date_fin) periodLabel = `_jusqu_${filters.date_fin}`
    XLSX.writeFile(wb, `simulations${periodLabel}.xlsx`)
  }

  const totalPages = Math.ceil(simulations.length / PAGE_SIZE)
  const pagedSimulations = simulations.slice(currentPage * PAGE_SIZE, (currentPage + 1) * PAGE_SIZE)

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* En-tête */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-800">Simulations</h1>
          <p className="text-gray-600 mt-1">Analyse des simulations effectuées par les clients</p>
        </div>
      </div>

      {/* Filtres */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="flex items-center gap-2 mb-4">
          <Filter className="w-5 h-5 text-coris-blue" />
          <h2 className="text-lg font-semibold text-gray-800">Filtres</h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <select
            value={filters.produit}
            onChange={(e) => setFilters({ ...filters, produit: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-coris-blue focus:border-transparent"
          >
            <option value="">Tous les produits</option>
            <option value="CORIS SERENITE">CORIS SERENITE</option>
            <option value="CORIS FAMILIS">CORIS FAMILIS</option>
            <option value="CORIS ETUDE">CORIS ETUDE</option>
            <option value="CORIS RETRAITE">CORIS RETRAITE</option>
            <option value="CORIS SOLIDARITE">CORIS SOLIDARITE</option>
            <option value="FLEX EMPRUNTEUR">FLEX EMPRUNTEUR</option>
          </select>

          <select
            value={filters.type_simulation}
            onChange={(e) => setFilters({ ...filters, type_simulation: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-coris-blue focus:border-transparent"
          >
            <option value="">Tous les types</option>
            <option value="Par Capital">Par Capital</option>
            <option value="Par Prime">Par Prime</option>
          </select>

          <input
            type="date"
            value={filters.date_debut}
            onChange={(e) => setFilters({ ...filters, date_debut: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-coris-blue focus:border-transparent"
            placeholder="Date début"
          />

          <input
            type="date"
            value={filters.date_fin}
            onChange={(e) => setFilters({ ...filters, date_fin: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-coris-blue focus:border-transparent"
            placeholder="Date fin"
          />
        </div>
        <div className="flex gap-2 mt-4">
          <button
            onClick={applyFilters}
            className="px-4 py-2 bg-coris-blue text-white rounded-lg hover:bg-blue-700 transition"
          >
            Appliquer les filtres
          </button>
          <button
            onClick={() => {
              setFilters({ produit: '', type_simulation: '', date_debut: '', date_fin: '' })
              setCurrentPage(0)
              loadData()
            }}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
          >
            Réinitialiser
          </button>
        </div>
      </div>

      {/* Statistiques principales */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Total Simulations</p>
              <p className="text-3xl font-bold text-coris-blue">{stats?.total || 0}</p>
            </div>
            <Calculator className="w-12 h-12 text-coris-blue opacity-20" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Capital Moyen</p>
              <p className="text-2xl font-bold text-green-600">
                {formatMoney(stats?.montants?.capital_moyen)}
              </p>
            </div>
            <TrendingUp className="w-12 h-12 text-green-600 opacity-20" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Prime Moyenne</p>
              <p className="text-2xl font-bold text-orange-600">
                {formatMoney(stats?.montants?.prime_moyenne)}
              </p>
            </div>
            <DollarSign className="w-12 h-12 text-orange-600 opacity-20" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Capital Max</p>
              <p className="text-2xl font-bold text-purple-600">
                {formatMoney(stats?.montants?.capital_max)}
              </p>
            </div>
            <Users className="w-12 h-12 text-purple-600 opacity-20" />
          </div>
        </div>
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Évolution mensuelle */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Évolution Mensuelle</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={stats?.par_mois || []}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="mois" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="count" stroke="#002B6B" name="Simulations" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Répartition par produit */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Répartition par Produit</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={stats?.par_produit || []}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={(entry) => entry.produit_nom}
                outerRadius={80}
                fill="#8884d8"
                dataKey="count"
                nameKey="produit_nom"
              >
                {(stats?.par_produit || []).map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Simulations par type */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Par Type de Simulation</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={stats?.par_type || []}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="type_simulation" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="count" fill="#002B6B" name="Nombre" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Évolution quotidienne (30 derniers jours) */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">30 Derniers Jours</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={stats?.par_jour || []}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="count" fill="#10B981" name="Simulations" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Liste des simulations */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-800">Liste des Simulations</h3>
            <p className="text-sm text-gray-500 mt-1">
              {simulations.length} simulation{simulations.length !== 1 ? 's' : ''} au total
              {(filters.date_debut || filters.date_fin) && (
                <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-700 rounded-full text-xs">
                  Filtrées par période
                </span>
              )}
            </p>
          </div>
          <button
            onClick={exportToExcel}
            disabled={simulations.length === 0}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <Download className="w-4 h-4" />
            Exporter Excel
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Produit</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Capital</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Prime</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Durée</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Client</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {pagedSimulations.map((sim) => (
                <tr key={sim.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {formatDate(sim.created_at)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-coris-blue">
                    {sim.produit_nom}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    <span className={`px-2 py-1 rounded-full text-xs ${
                      sim.type_simulation === 'Par Capital' 
                        ? 'bg-blue-100 text-blue-800' 
                        : 'bg-green-100 text-green-800'
                    }`}>
                      {sim.type_simulation}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {sim.capital ? formatMoney(sim.capital) : '-'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {sim.prime ? formatMoney(sim.prime) : '-'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {sim.duree_mois ? `${sim.duree_mois} mois` : '-'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {sim.user_name || 'Anonyme'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
            <p className="text-sm text-gray-600">
              Page {currentPage + 1} sur {totalPages} &mdash; simulations {currentPage * PAGE_SIZE + 1} à {Math.min((currentPage + 1) * PAGE_SIZE, simulations.length)}
            </p>
            <div className="flex gap-2">
              <button
                onClick={() => setCurrentPage((p) => Math.max(0, p - 1))}
                disabled={currentPage === 0}
                className="flex items-center gap-1 px-3 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="w-4 h-4" /> Précédent
              </button>
              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages - 1, p + 1))}
                disabled={currentPage === totalPages - 1}
                className="flex items-center gap-1 px-3 py-2 border border-gray-300 rounded-lg text-sm hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Suivant <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
