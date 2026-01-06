import { useEffect, useState } from 'react'
import { dashboardService } from '../services/api.service'
import { Link } from 'react-router-dom'
import {
  Users,
  FileText,
  TrendingUp,
  DollarSign,
  ArrowUp,
  ArrowDown,
  Activity,
  RefreshCw
} from 'lucide-react'
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts'

const COLORS = ['#002B6B', '#E30613', '#10B981', '#F59E0B', '#8B5CF6']

export default function DashboardPage() {
  const [stats, setStats] = useState(null)
  const [activities, setActivities] = useState([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [periodMonths, setPeriodMonths] = useState(12)

  useEffect(() => {
    loadDashboard()
  }, [])

  const normalizeStats = (data) => {
    const raw = data?.stats ? data.stats : data
    if (!raw) return { usersByRole: {}, contractsByStatus: {}, subscriptionsByStatus: {}, revenus: [], produits: [] }

    const toNumber = (v) => Number(v ?? 0) || 0

    const usersByRole = (raw.users || raw.usersStats || []).reduce((acc, item) => {
      const key = (item.role || '').toLowerCase()
      acc[key] = toNumber(item.count)
      return acc
    }, {})

    const contractsByStatus = (raw.contracts || raw.contrats || []).reduce((acc, item) => {
      const key = (item.etat || item.status || '').toLowerCase()
      acc[key] = toNumber(item.count)
      return acc
    }, {})

    const subscriptionsByStatus = (raw.subscriptions || raw.souscriptions || []).reduce((acc, item) => {
      const key = (item.statut || item.status || '').toLowerCase()
      acc[key] = toNumber(item.count)
      return acc
    }, {})

    const revenus = (raw.revenus || []).map((item) => ({
      mois: item.mois || item.month || null,
      mois_num: item.mois_num ? Number(item.mois_num) : undefined,
      annee: item.annee ? Number(item.annee) : undefined,
      montant: toNumber(item.total ?? item.montant)
    }))

    const totals = raw.totals || {}

    return {
      usersByRole,
      contractsByStatus,
      subscriptionsByStatus,
      revenus,
      produits: raw.produits || [],
      totals
    }
  }

  const loadDashboard = async () => {
    try {
      setLoading(true)
      const [statsData, activitiesData] = await Promise.all([
        dashboardService.getStats(),
        dashboardService.getRecentActivities({ limit: 20, offset: 0 })
      ])

      const normalizedStats = normalizeStats(statsData)
      setStats(normalizedStats)

      const rawActivities = activitiesData.activities || activitiesData || []
      const normalizedActivities = rawActivities.map((a) => ({
        type: 'subscription',
        description: `Souscription ${a.prenom_client || ''} ${a.nom_client || ''}`.trim(),
        details: a.produit ? `Produit: ${a.produit} • Statut: ${a.statut}` : `Statut: ${a.statut || 'N/A'}`,
        date: a.created_at || a.date_creation
      }))
      setActivities(normalizedActivities)
    } catch (error) {
      console.error('Erreur chargement dashboard:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleRefresh = async () => {
    setRefreshing(true)
    await loadDashboard()
    setRefreshing(false)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
      </div>
    )
  }

  // Préparer les données pour les graphiques depuis les stats réels
  const MONTHS_FR_FULL = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre']
  const MONTHS_FR_ABBR = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.']

  // Construit une série de N derniers mois (jusqu'au mois courant),
  // en remplissant les mois manquants par 0
  const buildMonthlySeries = (months = 12) => {
    const map = new Map()
    ;(stats?.revenus || []).forEach((item) => {
      const m = Number(item.mois_num)
      const y = Number(item.annee)
      if (m && y) {
        map.set(`${y}-${m}`, Number(item.montant || 0))
      }
    })

    const series = []
    const end = new Date()
    // Inclus le mois courant et les N-1 précédents
    for (let i = months - 1; i >= 0; i--) {
      const d = new Date(end.getFullYear(), end.getMonth() - i, 1)
      const m = d.getMonth() + 1
      const y = d.getFullYear()
      const key = `${y}-${m}`
      const value = map.has(key) ? map.get(key) : 0
      series.push({
        month: MONTHS_FR_ABBR[m - 1],
        monthFull: `${MONTHS_FR_FULL[m - 1]} ${y}`,
        revenus: value,
        contrats: stats?.contractsByStatus ? Object.values(stats.contractsByStatus).reduce((a, b) => a + b, 0) : 0,
        souscriptions: stats?.subscriptionsByStatus ? Object.values(stats.subscriptionsByStatus).reduce((a, b) => a + b, 0) : 0,
      })
    }
    return series
  }

  const handleExportCSV = () => {
    const data = buildMonthlySeries(periodMonths)
    if (data.length === 0) return
    const headers = ['Mois', 'Année', 'Revenus (FCFA)']
    const rows = data.map(row => {
      const [month, year] = row.monthFull.split(' ')
      const title = month.charAt(0).toUpperCase() + month.slice(1)
      return [title, year, row.revenus.toString()]
    })
    const csv = [headers, ...rows].map(r => r.map(cell => `"${cell}"`).join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `revenus_${periodMonths}m.csv`)
    link.click()
  }

  const monthlyData = buildMonthlySeries(periodMonths)

  const productDistribution = stats?.produits ? stats.produits.map(item => ({
    name: item.produit || item.name,
    value: item.count || item.total || 0
  })) : []

  const statusData = stats?.contractsByStatus
    ? Object.entries(stats.contractsByStatus).map(([k, v]) => ({
        name: k,
        value: v
      }))
    : []

  const totalUsers = stats?.totals?.users ?? (stats?.usersByRole ? Object.values(stats.usersByRole).reduce((a, b) => a + b, 0) : 0)
  const totalContracts = stats?.totals?.contracts ?? (stats?.contractsByStatus ? Object.values(stats.contractsByStatus).reduce((a, b) => a + b, 0) : 0)
  const totalSubscriptions = stats?.totals?.subscriptions ?? (stats?.subscriptionsByStatus ? Object.values(stats.subscriptionsByStatus).reduce((a, b) => a + b, 0) : 0)
  const totalRevenue = stats?.totals?.revenue ?? (stats?.revenus ? stats.revenus.reduce((sum, item) => sum + (item.montant || 0), 0) : 0)

  // Revenu total du mois courant pour la tuile "Revenu total mensuel"
  const currentMonth = new Date().getMonth() + 1
  const currentYear = new Date().getFullYear()
  const monthlyRevenueCurrent = (() => {
    const found = (stats?.revenus || []).find((r) => Number(r.mois_num) === currentMonth && Number(r.annee) === currentYear)
    return found ? Number(found.montant || 0) : 0
  })()

  // Calcul des vrais pourcentages de changement (mois courant vs mois précédent)
  const calculateChangePercent = (current, previous) => {
    if (!previous || previous === 0) return 0
    return Math.round(((current - previous) / previous) * 100)
  }

  const previousMonth = currentMonth === 1 ? 12 : currentMonth - 1
  const previousYear = currentMonth === 1 ? currentYear - 1 : currentYear

  // Changement Utilisateurs (on suppose stable pour l'instant, ou on prend la différence)
  const usersChange = 0 // À améliorer si données mensuelles disponibles

  // Changement Contrats (mois courant vs mois précédent)
  const contractsCurrentMonth = monthlyData.find(d => d.month === MONTHS_FR_ABBR[currentMonth - 1])?.contrats || 0
  const contractsPreviousMonth = (() => {
    if (currentMonth === 1) {
      // Pas d'année précédente dans les derniers 12 mois généralement
      return 0
    }
    return monthlyData.find(d => d.month === MONTHS_FR_ABBR[previousMonth - 1])?.contrats || 0
  })()
  const contractsChange = calculateChangePercent(contractsCurrentMonth, contractsPreviousMonth)

  // Changement Souscriptions
  const subscriptionsCurrentMonth = monthlyData.find(d => d.month === MONTHS_FR_ABBR[currentMonth - 1])?.souscriptions || 0
  const subscriptionsPreviousMonth = (() => {
    if (currentMonth === 1) return 0
    return monthlyData.find(d => d.month === MONTHS_FR_ABBR[previousMonth - 1])?.souscriptions || 0
  })()
  const subscriptionsChange = calculateChangePercent(subscriptionsCurrentMonth, subscriptionsPreviousMonth)

  // Changement Revenus
  const revenuPreviousMonth = (() => {
    const found = (stats?.revenus || []).find((r) => Number(r.mois_num) === previousMonth && Number(r.annee) === previousYear)
    return found ? Number(found.montant || 0) : 0
  })()
  const revenueChange = calculateChangePercent(monthlyRevenueCurrent, revenuPreviousMonth)

  return (
    <div className="space-y-6">
      {/* Page Title avec Refresh */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Tableau de bord</h1>
          <p className="text-gray-600 mt-1">Vue d'ensemble de votre plateforme</p>
        </div>
        <button
          onClick={handleRefresh}
          disabled={refreshing}
          className="flex items-center gap-2 bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition disabled:opacity-50"
        >
          <RefreshCw className={`w-5 h-5 ${refreshing ? 'animate-spin' : ''}`} />
          Actualiser
        </button>
      </div>

      {/* Stats Cards - Vraies données */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Utilisateurs"
          value={totalUsers.toLocaleString()}
          change={usersChange >= 0 ? `+${usersChange}%` : `${usersChange}%`}
          changeType={usersChange >= 0 ? "increase" : "decrease"}
          icon={Users}
          color="blue"
        />
        <StatCard
          title="Contrats Actifs"
          value={totalContracts.toLocaleString()}
          change={contractsChange >= 0 ? `+${contractsChange}%` : `${contractsChange}%`}
          changeType={contractsChange >= 0 ? "increase" : "decrease"}
          icon={FileText}
          color="green"
        />
        <StatCard
          title="Souscriptions"
          value={totalSubscriptions.toLocaleString()}
          change={subscriptionsChange >= 0 ? `+${subscriptionsChange}%` : `${subscriptionsChange}%`}
          changeType={subscriptionsChange >= 0 ? "increase" : "decrease"}
          icon={TrendingUp}
          color="purple"
        />
        <StatCard
          title="Revenu total mensuel"
          value={new Intl.NumberFormat('fr-CI', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(monthlyRevenueCurrent)}
          change={revenueChange >= 0 ? `+${revenueChange}%` : `${revenueChange}%`}
          changeType={revenueChange >= 0 ? "increase" : "decrease"}
          icon={DollarSign}
          color="red"
        />
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        {/* Évolution mensuelle */}
        {monthlyData.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-3">
            <h3 className="text-lg font-semibold text-gray-900 mb-3">
              Évolution Mensuelle
            </h3>
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={monthlyData} margin={{ top: 5, right: 8, left: 50, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" stroke="#6b7280" />
                <YAxis width={90} stroke="#6b7280" tickFormatter={(v) => new Intl.NumberFormat('fr-FR').format(v)} />
                <Tooltip
                  formatter={(value) => new Intl.NumberFormat('fr-FR').format(Number(value || 0))}
                  labelFormatter={(label, payload) => (payload?.[0]?.payload?.monthFull || label || '')}
                />
                <Legend />
                <Area
                  type="monotone"
                  dataKey="contrats"
                  stackId="1"
                  stroke="#002B6B"
                  fill="#002B6B"
                  fillOpacity={0.6}
                  name="Contrats"
                />
                <Area
                  type="monotone"
                  dataKey="souscriptions"
                  stackId="1"
                  stroke="#E30613"
                  fill="#E30613"
                  fillOpacity={0.6}
                  name="Souscriptions"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Distribution par produit */}
        {productDistribution.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-3">
            <h3 className="text-lg font-semibold text-gray-900 mb-3">
              Distribution par Produit
            </h3>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={productDistribution}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={100}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {productDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Charts Row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
        {/* Revenus mensuels */}
        {monthlyData.length > 0 && (
          <div className="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-200 p-3">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-lg font-semibold text-gray-900">
                Revenus Mensuels (FCFA)
              </h3>
              <div className="flex gap-2">
                {[3, 6, 12].map((m) => (
                  <button
                    key={m}
                    onClick={() => setPeriodMonths(m)}
                    className={`px-3 py-1 rounded text-sm font-medium transition ${
                      periodMonths === m
                        ? 'bg-coris-blue text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                  >
                    {m}m
                  </button>
                ))}
                <button
                  onClick={handleExportCSV}
                  className="ml-2 px-3 py-1 rounded text-sm bg-green-100 text-green-700 hover:bg-green-200 transition font-medium"
                >
                  CSV
                </button>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={monthlyData} margin={{ top: 5, right: 8, left: 50, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" stroke="#6b7280" />
                <YAxis width={90} stroke="#6b7280" tickFormatter={(v) => new Intl.NumberFormat('fr-FR').format(v)} domain={[0, 'auto']} />
                <Tooltip
                  formatter={(value) => new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(Number(value || 0))}
                  labelFormatter={(label, payload) => (payload?.[0]?.payload?.monthFull || label || '')}
                />
                <Bar dataKey="revenus" fill="#002B6B" name="Revenus" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Statut des contrats */}
        {statusData.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-3">
            <h3 className="text-lg font-semibold text-gray-900 mb-3">
              Statut des Contrats
            </h3>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={statusData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  fill="#8884d8"
                  paddingAngle={5}
                  dataKey="value"
                  label
                >
                  <Cell fill="#10B981" />
                  <Cell fill="#F59E0B" />
                  <Cell fill="#E30613" />
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Activités récentes */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">Activités Récentes</h3>
          <Link to="/activities" className="text-sm text-coris-blue hover:underline">Voir tout</Link>
        </div>
        <div className="space-y-4">
          {activities.length > 0 ? (
            activities.slice(0, 5).map((activity, i) => (
              <ActivityItem key={i} activity={activity} />
            ))
          ) : (
            <p className="text-gray-500 text-sm">Aucune activité récente</p>
          )}
        </div>
      </div>
    </div>
  )
}

function StatCard({ title, value, change, changeType, icon: Icon, color }) {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
    red: 'bg-red-50 text-red-600',
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-lg ${colorClasses[color]}`}>
          <Icon className="w-6 h-6" />
        </div>
        <div className={`flex items-center gap-1 text-sm font-medium ${
          changeType === 'increase' ? 'text-green-600' : 'text-red-600'
        }`}>
          {changeType === 'increase' ? (
            <ArrowUp className="w-4 h-4" />
          ) : (
            <ArrowDown className="w-4 h-4" />
          )}
          {change}
        </div>
      </div>
      <h3 className="text-gray-600 text-sm font-medium mb-1">{title}</h3>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
    </div>
  )
}

function ActivityItem({ activity }) {
  const getActivityIcon = (type) => {
    switch (type?.toLowerCase()) {
      case 'subscription':
        return '📝'
      case 'contract':
        return '📋'
      case 'commission':
        return '💰'
      default:
        return '📌'
    }
  }

  const formatDate = (date) => {
    if (!date) return 'À l\'instant'
    const now = new Date()
    const actDate = new Date(date)
    const diff = Math.floor((now - actDate) / 1000 / 60)
    if (diff < 1) return 'À l\'instant'
    if (diff < 60) return `Il y a ${diff} min`
    if (diff < 1440) return `Il y a ${Math.floor(diff / 60)}h`
    return `Il y a ${Math.floor(diff / 1440)}j`
  }

  return (
    <div className="flex items-start gap-4 pb-4 border-b border-gray-100 last:border-0">
      <div className="p-2 bg-coris-blue/10 rounded-lg text-2xl">
        {getActivityIcon(activity.type)}
      </div>
      <div className="flex-1">
        <p className="text-sm text-gray-900 font-medium">
          {activity.description || 'Nouvelle activité'}
        </p>
        <p className="text-xs text-gray-500 mt-1">
          {activity.details || ''}
        </p>
      </div>
      <span className="text-xs text-gray-400 whitespace-nowrap">{formatDate(activity.date || activity.date_creation)}</span>
    </div>
  )
}
