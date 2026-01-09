import React, { useState, useEffect } from 'react'
import { Search, Check, X, Eye, Plus, Trash2, FileText, Zap, CreditCard, Banknote } from 'lucide-react'
import { subscriptionsService } from '../services/api.service'

export default function SubscriptionsPage() {
  // ========== ÉTATS DE LA PAGE ==========
  // Liste des souscriptions affichées
  const [subscriptions, setSubscriptions] = useState([])
  // Indicateur de chargement
  const [loading, setLoading] = useState(true)
  // Terme de recherche pour filtrer les souscriptions
  const [searchTerm, setSearchTerm] = useState('')
  // Filtre par statut (tous, proposition, payé, contrat, activé, annulé)
  const [statusFilter, setStatusFilter] = useState('tous')
  // Pagination (limite par page, offset actuel, total d'éléments)
  const [pagination, setPagination] = useState({ limit: 10, offset: 0, total: 0 })
  // Statistiques par statut (nombre de propositions, contrats, etc.)
  const [stats, setStats] = useState({ by_status: {} })
  
  // ========== ÉTATS DES MODALS ==========
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  // Modal de paiement pour encaisser une proposition
  const [showPaymentModal, setShowPaymentModal] = useState(false)
  
  // ========== ÉTATS DE SÉLECTION ==========
  const [selectedSubscription, setSelectedSubscription] = useState(null)
  // Souscription ciblée pour le paiement
  const [paymentTarget, setPaymentTarget] = useState(null)
  
  // ========== ÉTATS DE PAIEMENT ==========
  // Mode de paiement sélectionné (wave, orange_money, virement, espece)
  const [paymentMethod, setPaymentMethod] = useState('wave')
  // Indicateur de traitement du paiement
  const [paymentLoading, setPaymentLoading] = useState(false)
  // Numéro de téléphone pour Wave/Orange Money
  const [paymentPhone, setPaymentPhone] = useState('')
  // Informations bancaires pour virement
  const [paymentBankInfo, setPaymentBankInfo] = useState({
    nom_banque: '',
    numero_compte: '',
    nom_titulaire: ''
  })
  
  // ========== FORMULAIRE DE CRÉATION ==========
  const [formData, setFormData] = useState({
    nom_client: '',
    prenom_client: '',
    email: '',
    telephone: '',
    produit: '',
    montant: '',
    statut: 'proposition'
  })

  useEffect(() => {
    fetchSubscriptions()
  }, [statusFilter, pagination.offset])

  /**
   * FONCTION : mapSubscription
   * Mappe les données brutes de la base vers un format unifié pour l'affichage.
   * Extrait les infos client depuis souscriptiondata.client_info (si commercial)
   * ou directement depuis les champs creator (si client direct).
   * 
   * @param {Object} sub - Souscription brute depuis l'API
   * @returns {Object} Souscription avec champs normalisés (client_nom, client_prenom, etc.)
   */
  function mapSubscription(sub) {
    // Extraire le JSONB souscriptiondata
    const data = sub?.souscriptiondata || {}
    // Infos client si la souscription a été créée par un commercial
    const clientInfo = data.client_info || {}

    // Chercher le montant dans plusieurs champs possibles
    const montant = sub?.montant ?? data.montant ?? data.prime_totale ?? data.montant_total ?? data.prime ?? null

    return {
      ...sub,
      // Priorité : client_info (commercial) > champs directs > creator
      client_nom: clientInfo.nom || sub?.client_nom || sub?.creator_nom || '',
      client_prenom: clientInfo.prenom || sub?.client_prenom || sub?.creator_prenom || '',
      client_email: clientInfo.email || data.email || sub?.creator_email || '',
      client_telephone: clientInfo.telephone || data.telephone || sub?.telephone || '',
      numero_police: sub?.numero_police || data.numero_police || data.police_number || '',
      produit_nom: sub?.produit_nom || data.produit_nom || data.produit || '',
      montant,
      origin: sub?.origin || data.origin,
      created_at: sub?.created_at || sub?.date_creation || data.created_at
    }
  }

  /**
   * FONCTION : fetchSubscriptions
   * Récupère la liste des souscriptions depuis le backend avec filtres et pagination.
   * Met à jour les états : subscriptions, stats, pagination.
   * Appelée au chargement de la page et après chaque modification.
   */
  const fetchSubscriptions = async () => {
    try {
      setLoading(true)
      const params = {
        statut: statusFilter === 'tous' ? undefined : statusFilter,
        limit: pagination.limit,
        offset: pagination.offset
      }
      const data = await subscriptionsService.getAll(params)
      // Mapper chaque souscription pour normaliser les champs
      const mapped = (data.subscriptions || []).map(mapSubscription)
      setSubscriptions(mapped)
      setStats(data.stats || { by_status: {} })
      setPagination(prev => ({ ...prev, total: data.total || 0 }))
    } catch (error) {
      console.error('Erreur:', error)
      alert('Erreur lors du chargement des souscriptions')
    } finally {
      setLoading(false)
    }
  }

  /**
   * FILTRE : filteredSubscriptions
   * Filtre les souscriptions affichées selon le terme de recherche (nom, email, produit).
   */
  const filteredSubscriptions = subscriptions.filter(sub => {
    const searchLower = searchTerm.toLowerCase()
    return (
      sub.creator_email?.toLowerCase().includes(searchLower) ||
      `${sub.creator_prenom || ''} ${sub.creator_nom || ''}`.toLowerCase().includes(searchLower) ||
      `${sub.client_prenom || ''} ${sub.client_nom || ''}`.toLowerCase().includes(searchLower) ||
      sub.client_email?.toLowerCase().includes(searchLower) ||
      sub.produit_nom?.toLowerCase().includes(searchLower)
    )
  })

  /**
   * FONCTION : getStatusColor
   * Retourne les classes Tailwind CSS pour colorer les badges de statut.
   */
  const getStatusColor = (status) => {
    const statusMap = {
      'proposition': 'bg-yellow-100 text-yellow-800',
      'payé': 'bg-blue-100 text-blue-800',
      'contrat': 'bg-green-100 text-green-800',
      'activé': 'bg-emerald-100 text-emerald-800',
      'annulé': 'bg-red-100 text-red-800'
    }
    return statusMap[status?.toLowerCase()] || 'bg-gray-100 text-gray-800'
  }

  /**
   * FONCTION : formatDate
   * Formate une date ISO en format français (JJ/MM/AAAA).
   */
  const formatDate = (date) => {
    if (!date) return 'N/A'
    return new Date(date).toLocaleDateString('fr-FR')
  }

  /**
   * FONCTION : formatCurrency
   * Formate un montant en Francs CFA (XOF).
   */
  const formatCurrency = (amount) => {
    if (!amount) return 'N/A'
    return new Intl.NumberFormat('fr-CI', { style: 'currency', currency: 'XOF' }).format(amount)
  }

  /**
   * FONCTION : handleFormChange
   * Met à jour le formulaire de création de souscription.
   */
  const handleFormChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  /**
   * FONCTION : handleViewSubscription
   * Ouvre le modal de détails d'une souscription.
   * Si les données sont déjà disponibles, les mappe directement.
   * Sinon, récupère les détails depuis l'API.
   */
  const handleViewSubscription = async (subscription) => {
    try {
      if (subscription?.souscriptiondata || subscription?.id) {
        setSelectedSubscription(mapSubscription(subscription))
        setShowViewModal(true)
        return
      }

      const data = await subscriptionsService.getById(subscription)
      setSelectedSubscription(mapSubscription(data.subscription))
      setShowViewModal(true)
    } catch (error) {
      console.error('Erreur chargement souscription:', error)
      alert('Erreur lors du chargement de la souscription')
    }
  }

  /**
   * FONCTION : handleDeleteSubscription
   * Supprime une souscription après confirmation.
   */
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

  /**
   * FONCTION : handleCreateSubscription
   * Crée une nouvelle souscription via le formulaire.
   * Réinitialise le formulaire et rafraîchit la liste après création.
   */
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
        statut: 'proposition'
      })
      fetchSubscriptions()
      alert('Souscription créée avec succès')
    } catch (error) {
      console.error('Erreur création souscription:', error)
      alert('Erreur lors de la création de la souscription')
    }
  }

  /**
   * FONCTION : handleUpdateStatus
   * Met à jour le statut d'une souscription (proposition -> payé -> contrat -> activé).
   * Appelle l'API backend puis rafraîchit la liste.
   * 
   * @param {number} id - ID de la souscription
   * @param {string} status - Nouveau statut (énumération: proposition, payé, contrat, activé, annulé)
   */
  const handleUpdateStatus = async (id, status) => {
    try {
      await subscriptionsService.updateStatus(id, status)
      fetchSubscriptions()
    } catch (error) {
      console.error('Erreur mise à jour statut:', error)
      alert('Erreur lors de la mise à jour du statut')
    }
  }

  // ========== ACTIONS DE CHANGEMENT DE STATUT ==========
  const handleMarkPaid = async (id) => handleUpdateStatus(id, 'payé')
  const handleToContract = async (id) => handleUpdateStatus(id, 'contrat')
  const handleActivate = async (id) => handleUpdateStatus(id, 'activé')
  const handleReject = async (id) => handleUpdateStatus(id, 'annulé')

  /**
   * FONCTION : openPaymentModal
   * Ouvre le modal de paiement pour une souscription donnée.
   * Réinitialise les champs de paiement (méthode = wave, téléphone vide, etc.)
   * 
   * @param {Object} sub - La souscription à encaisser
   */
  const openPaymentModal = (sub) => {
    setPaymentTarget(sub)
    setPaymentMethod('wave')
    setPaymentPhone('')
    setPaymentBankInfo({ nom_banque: '', numero_compte: '', nom_titulaire: '' })
    setShowPaymentModal(true)
  }

  /**
   * FONCTION : confirmPayment
   * Valide le paiement et passe la souscription en contrat.
   * 
   * FLUX :
   * 1. Vérifie les champs requis selon le mode de paiement (téléphone, infos bancaires)
   * 2. Passe le statut en "payé" puis immédiatement en "contrat"
   * 3. Rafraîchit la liste des souscriptions
   * 4. Ferme le modal
   * 
   * NOTE : Pour espèce, pas de validation supplémentaire (paiement direct)
   */
  const confirmPayment = async () => {
    if (!paymentTarget) return

    // Validation selon le mode de paiement
    if ((paymentMethod === 'wave' || paymentMethod === 'orange_money') && !paymentPhone.trim()) {
      alert('Veuillez saisir le numéro de téléphone')
      return
    }
    if (paymentMethod === 'virement') {
      if (!paymentBankInfo.nom_banque || !paymentBankInfo.numero_compte || !paymentBankInfo.nom_titulaire) {
        alert('Veuillez remplir toutes les informations bancaires')
        return
      }
    }

    setPaymentLoading(true)
    try {
      // Passer en "payé" puis "contrat" (stockage dans table contrats via trigger/backend)
      await handleMarkPaid(paymentTarget.id)
      await handleToContract(paymentTarget.id)
      
      // Fermer le modal et rafraîchir
      setShowPaymentModal(false)
      setPaymentTarget(null)
      fetchSubscriptions()
      
      alert(`Paiement validé (${paymentMethod}). Contrat créé avec succès.`)
    } catch (error) {
      console.error('Erreur paiement:', error)
      alert('Échec du paiement ou de la création du contrat')
    } finally {
      setPaymentLoading(false)
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
      {/* Affichage des statistiques : Total souscriptions, Contrats réels (table contrats), Propositions, Annulées */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Total Souscriptions</p>
          <p className="text-2xl font-bold text-coris-blue">{pagination.total}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Contrats (Base)</p>
          <p className="text-2xl font-bold text-coris-green">{stats.total_contrats || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Propositions</p>
          <p className="text-2xl font-bold text-coris-orange">{stats.by_status?.['proposition'] || 0}</p>
        </div>
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Annulées</p>
          <p className="text-2xl font-bold text-coris-red">{stats.by_status?.['annulé'] || stats.by_status?.['rejete'] || 0}</p>
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
            <option value="proposition">Propositions</option>
            <option value="payé">Payées</option>
            <option value="contrat">Contrats</option>
            <option value="activé">Activées</option>
            <option value="annulé">Annulées</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow overflow-hidden overflow-x-auto">
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
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{sub.client_prenom || sub.creator_prenom} {sub.client_nom || sub.creator_nom || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{sub.client_email || sub.creator_email || 'N/A'}</td>
                  <td className="px-6 py-4 text-sm text-gray-700">{sub.produit_nom || 'N/A'}</td>
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
                      onClick={() => handleViewSubscription(sub)}
                      className="text-coris-blue hover:bg-blue-50 p-2 rounded transition">
                      <Eye className="w-4 h-4" />
                    </button>
                    {sub.statut?.toLowerCase() === 'proposition' && (
                      <>
                        <button
                          onClick={() => openPaymentModal(sub)}
                          className="text-coris-green hover:bg-green-50 p-2 rounded transition"
                          title="Encaisser (Wave / Orange Money / Virement)"
                        >
                          <CreditCard className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleReject(sub.id)}
                          className="text-coris-red hover:bg-red-50 p-2 rounded transition"
                          title="Annuler"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </>
                    )}
                    {sub.statut?.toLowerCase() === 'payé' && (
                      <>
                        <button
                          onClick={() => handleToContract(sub.id)}
                          className="text-coris-blue hover:bg-blue-50 p-2 rounded transition"
                          title="Passer en contrat"
                        >
                          <FileText className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleReject(sub.id)}
                          className="text-coris-red hover:bg-red-50 p-2 rounded transition"
                          title="Annuler"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </>
                    )}
                    {sub.statut?.toLowerCase() === 'contrat' && (
                      <button
                        onClick={() => handleActivate(sub.id)}
                        className="text-coris-green hover:bg-green-50 p-2 rounded transition"
                        title="Activer"
                      >
                        <Zap className="w-4 h-4" />
                      </button>
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
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 max-h-[90vh] flex flex-col">
            <div className="flex justify-between items-center p-6 border-b flex-shrink-0">
              <h2 className="text-lg font-semibold text-gray-900">Nouvelle souscription</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleCreateSubscription} className="p-6 space-y-4 overflow-y-auto flex-1">
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
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 max-h-[90vh] flex flex-col">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Détails de la souscription</h2>
              <button
                onClick={() => setShowViewModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-4 overflow-y-auto flex-1">
              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Nom Client</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.client_nom || selectedSubscription.creator_nom || 'N/A'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Prénom Client</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.client_prenom || selectedSubscription.creator_prenom || 'N/A'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Email</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.client_email || selectedSubscription.creator_email || 'N/A'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Téléphone</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.client_telephone || '-'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Origine</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.origin || 'N/A'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Numéro de police</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.numero_police || 'N/A'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Produit</label>
                <p className="mt-1 text-sm text-gray-900">{selectedSubscription.produit_nom || 'N/A'}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Montant</label>
                <p className="mt-1 text-sm text-gray-900">{formatCurrency(selectedSubscription.montant)}</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 uppercase">Statut</label>
                <p className="mt-1 text-sm">
                  <span className={`inline-block px-2 py-1 rounded text-white text-xs font-semibold ${
                    selectedSubscription.statut?.toLowerCase() === 'contrat' || selectedSubscription.statut?.toLowerCase() === 'approuve' ? 'bg-green-500' :
                    selectedSubscription.statut?.toLowerCase() === 'annulé' || selectedSubscription.statut?.toLowerCase() === 'rejete' ? 'bg-red-500' :
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

      {/* Payment Modal */}
      {showPaymentModal && paymentTarget && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 max-h-[90vh] flex flex-col">
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Encaisser et passer en contrat</h2>
              <button
                onClick={() => setShowPaymentModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <p className="text-sm text-gray-700 font-semibold">Souscription #{paymentTarget.id}</p>
                <p className="text-sm text-gray-600">{paymentTarget.client_prenom || paymentTarget.creator_prenom} {paymentTarget.client_nom || paymentTarget.creator_nom}</p>
                <p className="text-sm text-gray-600">Produit : {paymentTarget.produit_nom || 'N/A'}</p>
                <p className="text-sm text-gray-900 font-semibold">Montant : {formatCurrency(paymentTarget.montant)}</p>
              </div>
              <div className="space-y-2">
                <p className="text-xs font-semibold text-gray-500 uppercase">Mode de paiement</p>
                {/* Option Wave */}
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input
                    type="radio"
                    name="payment_method"
                    value="wave"
                    checked={paymentMethod === 'wave'}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                  />
                  <CreditCard className="w-4 h-4 text-coris-blue" /> Wave
                </label>
                {/* Option Orange Money */}
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input
                    type="radio"
                    name="payment_method"
                    value="orange_money"
                    checked={paymentMethod === 'orange_money'}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                  />
                  <CreditCard className="w-4 h-4 text-orange-500" /> Orange Money
                </label>
                {/* Option Virement bancaire */}
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input
                    type="radio"
                    name="payment_method"
                    value="virement"
                    checked={paymentMethod === 'virement'}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                  />
                  <Banknote className="w-4 h-4 text-green-600" /> Virement
                </label>
                {/* Option Espèce */}
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input
                    type="radio"
                    name="payment_method"
                    value="espece"
                    checked={paymentMethod === 'espece'}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                  />
                  <Banknote className="w-4 h-4 text-gray-700" /> Espèce
                </label>
              </div>

              {/* Champs conditionnels selon le mode de paiement */}
              {(paymentMethod === 'wave' || paymentMethod === 'orange_money') && (
                <div>
                  <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">
                    Numéro de téléphone *
                  </label>
                  <input
                    type="tel"
                    value={paymentPhone}
                    onChange={(e) => setPaymentPhone(e.target.value)}
                    placeholder="Ex: +225 07 00 00 00 00"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  />
                </div>
              )}

              {paymentMethod === 'virement' && (
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">
                      Nom de la banque *
                    </label>
                    <input
                      type="text"
                      value={paymentBankInfo.nom_banque}
                      onChange={(e) => setPaymentBankInfo({ ...paymentBankInfo, nom_banque: e.target.value })}
                      placeholder="Ex: SGCI, NSIA, BOA"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">
                      Numéro de compte *
                    </label>
                    <input
                      type="text"
                      value={paymentBankInfo.numero_compte}
                      onChange={(e) => setPaymentBankInfo({ ...paymentBankInfo, numero_compte: e.target.value })}
                      placeholder="Ex: CI00123456789"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">
                      Nom du titulaire *
                    </label>
                    <input
                      type="text"
                      value={paymentBankInfo.nom_titulaire}
                      onChange={(e) => setPaymentBankInfo({ ...paymentBankInfo, nom_titulaire: e.target.value })}
                      placeholder="Nom complet du titulaire"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                    />
                  </div>
                </div>
              )}

              {paymentMethod === 'espece' && (
                <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                  <p className="text-xs text-gray-600">
                    ✅ Le paiement en espèce sera enregistré immédiatement et la souscription sera transformée en contrat.
                  </p>
                </div>
              )}
              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowPaymentModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition"
                  disabled={paymentLoading}
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={confirmPayment}
                  className="flex-1 px-4 py-2 bg-coris-blue text-white rounded-lg hover:bg-coris-blue-light transition disabled:opacity-60"
                  disabled={paymentLoading}
                >
                  {paymentLoading ? 'Encaissement...' : 'Payer et contracter'}
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
