import { useEffect, useMemo, useState } from 'react'
import { dashboardService } from '../services/api.service'

export default function ActivitiesPage() {
  const [activities, setActivities] = useState([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [limit] = useState(100)
  const [total, setTotal] = useState(0)
  const [query, setQuery] = useState('')
  const [pendingQuery, setPendingQuery] = useState('')

  const loadPage = async (p, q = query) => {
    setLoading(true)
    try {
      const offset = (p - 1) * limit
      const params = q ? { limit, offset, q } : { limit, offset }
      const res = await dashboardService.getRecentActivities(params)
      setActivities(res.activities || [])
      setTotal(res.total || 0)
    } catch (e) {
      console.error('Erreur chargement activités:', e)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadPage(page)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page])

  // Débouncer la recherche pour éviter des appels trop fréquents
  useEffect(() => {
    const t = setTimeout(() => {
      setQuery(pendingQuery)
      setPage(1)
      loadPage(1, pendingQuery)
    }, 400)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pendingQuery])

  const totalPages = Math.max(1, Math.ceil(total / limit))

  const formatDate = (date) => {
    if (!date) return 'À l\'instant'
    const d = new Date(date)
    return d.toLocaleString('fr-FR', { dateStyle: 'medium', timeStyle: 'short' })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Activités récentes</h1>
          <p className="text-gray-600 mt-1">Dernières opérations côté souscriptions (100 par page)</p>
        </div>
        <div className="w-full max-w-md">
          <input
            type="text"
            placeholder="Rechercher produit, contrat, client, statut…"
            className="w-full border rounded-lg px-3 py-2 text-sm"
            value={pendingQuery}
            onChange={(e) => setPendingQuery(e.target.value)}
          />
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
          </div>
        ) : activities.length === 0 ? (
          <p className="text-gray-500">Aucune activité</p>
        ) : (
          <div className="space-y-4">
            {activities.map((a) => (
              <div key={a.id} className="flex items-start gap-4 pb-4 border-b border-gray-100 last:border-0">
                <div className="p-2 bg-coris-blue/10 rounded-lg text-2xl">📝</div>
                <div className="flex-1">
                  <p className="text-sm text-gray-900 font-medium">
                    Souscription {a.prenom_client || ''} {a.nom_client || ''}
                  </p>
                  <p className="text-xs text-gray-500 mt-1">
                    Produit: {a.produit || '—'} • Statut: {a.statut || '—'}
                  </p>
                </div>
                <span className="text-xs text-gray-400 whitespace-nowrap">{formatDate(a.created_at || a.date)}</span>
              </div>
            ))}

            {/* Pagination */}
            <div className="flex items-center justify-between pt-4">
              <button
                className="px-3 py-2 rounded border text-sm disabled:opacity-50"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1}
              >
                Précédent
              </button>
              <div className="text-sm text-gray-600">Page {page} / {totalPages} • {total} activités</div>
              <button
                className="px-3 py-2 rounded border text-sm disabled:opacity-50"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
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
