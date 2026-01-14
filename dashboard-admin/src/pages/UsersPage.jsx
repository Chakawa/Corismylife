import { useState, useEffect } from 'react'
import { usersService } from '../services/api.service'
import { Search, Filter, Plus, Edit, Trash2, Eye, UserCheck, UserX, X } from 'lucide-react'

export default function UsersPage() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterRole, setFilterRole] = useState('all')
  const [currentPage, setCurrentPage] = useState(1)
  const pageSize = 10
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [showSuspendModal, setShowSuspendModal] = useState(false)
  const [selectedUser, setSelectedUser] = useState(null)
  const [editFormData, setEditFormData] = useState({})
  const [suspendReason, setSuspendReason] = useState('')
  const [suspendedCount, setSuspendedCount] = useState(0)
  const [formData, setFormData] = useState({
    civilite: 'M',
    prenom: '',
    nom: '',
    email: '',
    telephone: '',
    date_naissance: '',
    lieu_naissance: '',
    adresse: '',
    pays: '',
    role: 'client',
    code_apporteur: '',
    password: ''
  })

  useEffect(() => {
    loadUsers()
    loadSuspendedCount()
  }, [filterRole])

  useEffect(() => {
    setCurrentPage(1)
  }, [searchTerm, filterRole])

  const loadUsers = async () => {
    setLoading(true)
    try {
      const data = await usersService.getAll({ role: filterRole !== 'all' ? filterRole : undefined })
      setUsers(data.users || [])
    } catch (error) {
      console.error('Erreur chargement utilisateurs:', error)
      setUsers([])
    } finally {
      setLoading(false)
    }
  }

  const loadSuspendedCount = async () => {
    try {
      const data = await usersService.getSuspendedCount()
      setSuspendedCount(data.count || 0)
    } catch (error) {
      console.error('Erreur chargement comptes suspendus:', error)
    }
  }

  const handleCreateUser = async (e) => {
    e.preventDefault()
    try {
      const response = await usersService.create(formData)
      setShowCreateModal(false)
      setFormData({
        civilite: 'M',
        prenom: '',
        nom: '',
        email: '',
        telephone: '',
        date_naissance: '',
        lieu_naissance: '',
        adresse: '',
        pays: '',
        role: 'client',
        code_apporteur: '',
        password: ''
      })
      loadUsers()
      alert(response.message || 'Utilisateur créé avec succès')
    } catch (error) {
      console.error('Erreur création utilisateur:', error)
      const errorMessage = error.response?.data?.message || error.message || 'Erreur lors de la création de l\'utilisateur'
      alert(errorMessage)
    }
  }

  const handleFormChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  const handleViewUser = (user) => {
    setSelectedUser(user)
    setShowViewModal(true)
  }

  const handleEditUser = (user) => {
    setSelectedUser(user)
    setEditFormData(user)
    setShowEditModal(true)
  }

  const handleSaveEdit = async () => {
    try {
      await usersService.update(selectedUser.id, editFormData)
      loadUsers()
      setShowEditModal(false)
      alert('Utilisateur modifié avec succès')
    } catch (error) {
      console.error('Erreur modification:', error)
      alert('Erreur lors de la modification')
    }
  }

  const handleDeleteUser = async (userId) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur? Cette action est irréversible.')) {
      try {
        const response = await usersService.delete(userId)
        loadUsers()
        alert(response.message || 'Utilisateur supprimé avec succès')
      } catch (error) {
        console.error('Erreur suppression:', error)
        const errorMessage = error.response?.data?.message || error.message || 'Erreur lors de la suppression'
        alert(errorMessage)
      }
    }
  }

  const handleSuspendUser = (user) => {
    setSelectedUser(user)
    setSuspendReason('')
    setShowSuspendModal(true)
  }

  const handleConfirmSuspend = async () => {
    try {
      const response = await usersService.suspend(selectedUser.id, suspendReason)
      if (response.success) {
        setShowSuspendModal(false)
        alert('Compte suspendu avec succès')
        loadUsers()
        loadSuspendedCount()
      } else {
        throw new Error(response.message || 'Erreur lors de la suspension')
      }
    } catch (error) {
      console.error('Erreur suspension:', error)
      alert(error.message || 'Erreur lors de la suspension du compte')
    }
  }

  const handleUnsuspendUser = async (userId) => {
    if (window.confirm('Voulez-vous réactiver ce compte?')) {
      try {
        await usersService.unsuspend(userId)
        loadUsers()
        loadSuspendedCount()
        alert('Compte réactivé avec succès')
      } catch (error) {
        console.error('Erreur réactivation:', error)
        alert('Erreur lors de la réactivation')
      }
    }
  }

  const handleEditFormChange = (field, value) => {
    setEditFormData(prev => ({ ...prev, [field]: value }))
  }

  const filteredUsers = users.filter(user =>
    user.nom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.prenom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.telephone?.includes(searchTerm)
  )

  const displayedUsers = filteredUsers.slice(0, pageSize * currentPage)
  const hasMoreUsers = displayedUsers.length < filteredUsers.length

  // Calcul des statistiques
  const totalClients = users.filter(u => u.role === 'client').length
  const totalCommerciaux = users.filter(u => u.role === 'commercial').length
  const totalAdmins = users.filter(u => ['super_admin', 'admin', 'moderation'].includes(u.role)).length

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Utilisateurs</h1>
          <p className="text-gray-600 mt-1">Gérez tous les utilisateurs de la plateforme</p>
        </div>
        <button 
          onClick={() => setShowCreateModal(true)}
          className="bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition-colors flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Nouvel utilisateur
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-4">
        <div className="flex items-center gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Rechercher un utilisateur..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
            />
          </div>
          <select
            value={filterRole}
            onChange={(e) => setFilterRole(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
          >
            <option value="all">Tous les rôles</option>
            <option value="client">Clients</option>
            <option value="commercial">Commerciaux</option>
            <option value="admin">Administrateurs</option>
          </select>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">Total Clients</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{totalClients}</p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <UserCheck className="w-8 h-8 text-blue-600" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">Commerciaux Actifs</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{totalCommerciaux}</p>
            </div>
            <div className="p-3 bg-green-50 rounded-lg">
              <UserCheck className="w-8 h-8 text-green-600" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">Administrateurs</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{totalAdmins}</p>
            </div>
            <div className="p-3 bg-purple-50 rounded-lg">
              <UserCheck className="w-8 h-8 text-purple-600" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm font-medium">Comptes Suspendus</p>
              <p className="text-3xl font-bold text-gray-900 mt-1">{suspendedCount}</p>
            </div>
            <div className="p-3 bg-red-50 rounded-lg">
              <UserX className="w-8 h-8 text-red-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden max-w-full">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
          </div>
        ) : (
          <div className="overflow-auto max-h-[70vh] w-full">
            <table className="min-w-full w-full table-auto divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Utilisateur
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden lg:table-cell">
                    Contact
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Rôle
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Statut / Connexion
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Déconnexion
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden md:table-cell">
                    Inscription
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider sticky right-0 bg-white z-10">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {displayedUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center">
                        <div className="h-9 w-9 flex-shrink-0">
                          <div className="h-9 w-9 rounded-full bg-coris-blue flex items-center justify-center text-white text-sm font-semibold">
                            {user.prenom?.[0]}{user.nom?.[0]}
                          </div>
                        </div>
                        <div className="ml-3 min-w-0">
                          <div className="text-sm font-medium text-gray-900 truncate">
                            {user.civilite} {user.prenom} {user.nom}
                          </div>
                          <div className="text-xs text-gray-500 lg:hidden truncate">
                            {user.email}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      <div className="text-sm text-gray-900 truncate max-w-xs">{user.email}</div>
                      {user.telephone && <div className="text-xs text-gray-500">{user.telephone}</div>}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 inline-flex text-xs leading-4 font-semibold rounded-full whitespace-nowrap ${
                        user.role === 'super_admin' ? 'bg-red-100 text-red-800' :
                        user.role === 'admin' ? 'bg-purple-100 text-purple-800' :
                        user.role === 'moderation' ? 'bg-orange-100 text-orange-800' :
                        user.role === 'commercial' ? 'bg-blue-100 text-blue-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {user.role === 'super_admin' ? 'Super Admin' :
                         user.role === 'admin' ? 'Admin' :
                         user.role === 'moderation' ? 'Modération' :
                         user.role === 'commercial' ? 'Commercial' :
                         'Client'}
                      </span>
                      {user.est_suspendu && (
                        <span className="ml-2 px-2 py-1 inline-flex text-xs leading-4 font-semibold rounded-full bg-red-100 text-red-800">
                          Suspendu
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <div className="flex items-center gap-2">
                        {(() => {
                          const isConnected = user.derniere_connexion && (!user.derniere_deconnexion || new Date(user.derniere_connexion) > new Date(user.derniere_deconnexion));
                          return (
                            <>
                              <div className={`h-3 w-3 rounded-full ${isConnected ? 'bg-green-500 animate-pulse' : 'bg-gray-300'}`} 
                                   title={isConnected ? "Connecté" : "Déconnecté"}></div>
                              <div className="flex flex-col">
                                <span className={`text-xs font-medium ${isConnected ? 'text-green-600' : 'text-gray-500'}`}>
                                  {isConnected ? '🟢 En ligne' : '⚫ Hors ligne'}
                                </span>
                                <span className="text-xs text-gray-500">
                                  {user.derniere_connexion ? new Date(user.derniere_connexion).toLocaleString('fr-FR', { 
                                    day: '2-digit', 
                                    month: '2-digit',
                                    hour: '2-digit', 
                                    minute: '2-digit' 
                                  }) : 'Jamais'}
                                </span>
                              </div>
                            </>
                          );
                        })()}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500">
                      {user.derniere_deconnexion ? (
                        <span className="text-xs">
                          {new Date(user.derniere_deconnexion).toLocaleString('fr-FR', { 
                            day: '2-digit', 
                            month: '2-digit',
                            hour: '2-digit', 
                            minute: '2-digit' 
                          })}
                        </span>
                      ) : '-'}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500 hidden md:table-cell">
                      {new Date(user.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })}
                    </td>
                    <td className="px-4 py-3 text-right sticky right-0 bg-white z-10">
                      <div className="flex items-center justify-end gap-1">
                        <button 
                          onClick={() => handleViewUser(user)}
                          className="text-blue-600 hover:text-blue-900 p-1.5 hover:bg-blue-50 rounded transition"
                          title="Voir">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => handleEditUser(user)}
                          className="text-green-600 hover:text-green-900 p-1.5 hover:bg-green-50 rounded transition"
                          title="Modifier">
                          <Edit className="w-4 h-4" />
                        </button>
                        {user.est_suspendu ? (
                          <button 
                            onClick={() => handleUnsuspendUser(user.id)}
                            className="text-orange-600 hover:text-orange-900 p-1.5 hover:bg-orange-50 rounded transition"
                            title="Réactiver">
                            <UserCheck className="w-4 h-4" />
                          </button>
                        ) : (
                          <button 
                            onClick={() => handleSuspendUser(user)}
                            className="text-yellow-600 hover:text-yellow-900 p-1.5 hover:bg-yellow-50 rounded transition"
                            title="Suspendre">
                            <UserX className="w-4 h-4" />
                          </button>
                        )}
                        <button 
                          onClick={() => handleDeleteUser(user.id)}
                          className="text-red-600 hover:text-red-900 p-1.5 hover:bg-red-50 rounded transition"
                          title="Supprimer">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredUsers.length === 0 && (
              <div className="text-center py-12">
                <p className="text-gray-500 text-sm">Aucun utilisateur trouvé</p>
              </div>
            )}
            {filteredUsers.length > 0 && (
              <div className="px-4 py-3 flex flex-wrap items-center justify-between gap-3 border-t border-gray-100 bg-gray-50">
                <p className="text-sm text-gray-600">
                  Affichage de {displayedUsers.length} sur {filteredUsers.length} utilisateurs filtrés
                </p>
                <div className="flex items-center gap-2">
                  {currentPage > 1 && (
                    <button
                      onClick={() => setCurrentPage(1)}
                      className="px-3 py-1 text-sm border border-gray-300 rounded-lg hover:bg-gray-100 transition"
                    >
                      Réinitialiser
                    </button>
                  )}
                  {hasMoreUsers && (
                    <>
                      <button
                        onClick={() => setCurrentPage(prev => prev + 1)}
                        className="px-4 py-2 text-sm bg-coris-blue text-white rounded-lg hover:bg-coris-blue-light transition"
                      >
                        Voir plus
                      </button>
                      <button
                        onClick={() => setCurrentPage(Math.ceil(filteredUsers.length / pageSize))}
                        className="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-100 transition"
                      >
                        Voir tout
                      </button>
                    </>
                  )}
                  {!hasMoreUsers && filteredUsers.length > pageSize && (
                    <button
                      onClick={() => setCurrentPage(1)}
                      className="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-100 transition"
                    >
                      Revenir en haut
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Modal Création Utilisateur */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg max-w-md w-full max-h-screen overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Créer un nouvel utilisateur</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleCreateUser} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Civilité</label>
                  <select
                    value={formData.civilite}
                    onChange={(e) => handleFormChange('civilite', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  >
                    <option value="M">M.</option>
                    <option value="Mme">Mme</option>
                    <option value="Mlle">Mlle</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Rôle *</label>
                  <select
                    value={formData.role}
                    onChange={(e) => handleFormChange('role', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                    required
                  >
                    <option value="client">Client</option>
                    <option value="commercial">Commercial</option>
                    <option value="super_admin">Super Administrateur</option>
                    <option value="admin">Administrateur Standard</option>
                    <option value="moderation">Modérateur</option>
                  </select>
                  <p className="text-xs text-gray-500 mt-1">
                    Le rôle définit les permissions et pages accessibles
                  </p>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Prénom *</label>
                <input
                  type="text"
                  value={formData.prenom}
                  onChange={(e) => handleFormChange('prenom', e.target.value)}
                  placeholder="Prénom"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nom *</label>
                <input
                  type="text"
                  value={formData.nom}
                  onChange={(e) => handleFormChange('nom', e.target.value)}
                  placeholder="Nom"
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
                  placeholder="Email"
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
                  placeholder="Téléphone"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Date de naissance</label>
                <input
                  type="date"
                  value={formData.date_naissance}
                  onChange={(e) => handleFormChange('date_naissance', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Lieu de naissance</label>
                <input
                  type="text"
                  value={formData.lieu_naissance}
                  onChange={(e) => handleFormChange('lieu_naissance', e.target.value)}
                  placeholder="Lieu de naissance"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Adresse</label>
                <input
                  type="text"
                  value={formData.adresse}
                  onChange={(e) => handleFormChange('adresse', e.target.value)}
                  placeholder="Adresse complète"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Pays</label>
                <input
                  type="text"
                  value={formData.pays}
                  onChange={(e) => handleFormChange('pays', e.target.value)}
                  placeholder="Pays"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Mot de passe *</label>
                <input
                  type="password"
                  value={formData.password}
                  onChange={(e) => handleFormChange('password', e.target.value)}
                  placeholder="Mot de passe"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  required
                />
              </div>

              {formData.role === 'commercial' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Code Apporteur</label>
                  <input
                    type="text"
                    value={formData.code_apporteur}
                    onChange={(e) => handleFormChange('code_apporteur', e.target.value)}
                    placeholder="Code apporteur"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                  />
                </div>
              )}

              <div className="flex gap-3 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-coris-blue text-white rounded-lg font-medium hover:bg-coris-blue-light transition"
                >
                  Créer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Voir Utilisateur */}
      {showViewModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg max-w-md w-full max-h-screen overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Détails utilisateur</h2>
              <button onClick={() => setShowViewModal(false)} className="text-gray-500 hover:text-gray-700">
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <p className="text-sm text-gray-600">Nom complet</p>
                <p className="font-medium">{selectedUser.civilite} {selectedUser.prenom} {selectedUser.nom}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="font-medium">{selectedUser.email}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Téléphone</p>
                <p className="font-medium">{selectedUser.telephone || '—'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Date de naissance</p>
                <p className="font-medium">{selectedUser.date_naissance ? new Date(selectedUser.date_naissance).toLocaleDateString('fr-FR') : '—'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Adresse</p>
                <p className="font-medium">{selectedUser.adresse || '—'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Rôle</p>
                <p className="font-medium">{selectedUser.role === 'admin' ? 'Administrateur' : selectedUser.role === 'commercial' ? 'Commercial' : 'Client'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Créé le</p>
                <p className="font-medium">{new Date(selectedUser.created_at).toLocaleDateString('fr-FR')}</p>
              </div>
              <button
                onClick={() => setShowViewModal(false)}
                className="w-full px-4 py-2 bg-coris-blue text-white rounded-lg font-medium hover:bg-coris-blue-light transition mt-4"
              >
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Modifier Utilisateur */}
      {showEditModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-lg max-w-md w-full max-h-screen overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Modifier utilisateur</h2>
              <button onClick={() => setShowEditModal(false)} className="text-gray-500 hover:text-gray-700">
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Prénom</label>
                <input
                  type="text"
                  value={editFormData.prenom || ''}
                  onChange={(e) => handleEditFormChange('prenom', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nom</label>
                <input
                  type="text"
                  value={editFormData.nom || ''}
                  onChange={(e) => handleEditFormChange('nom', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={editFormData.email || ''}
                  onChange={(e) => handleEditFormChange('email', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
                <input
                  type="tel"
                  value={editFormData.telephone || ''}
                  onChange={(e) => handleEditFormChange('telephone', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Adresse</label>
                <input
                  type="text"
                  value={editFormData.adresse || ''}
                  onChange={(e) => handleEditFormChange('adresse', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>
              <div className="flex gap-3 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => setShowEditModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition"
                >
                  Annuler
                </button>
                <button
                  onClick={handleSaveEdit}
                  className="flex-1 px-4 py-2 bg-coris-blue text-white rounded-lg font-medium hover:bg-coris-blue-light transition"
                >
                  Enregistrer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Suspend User Modal */}
      {showSuspendModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900">Suspendre le compte</h3>
              <button onClick={() => setShowSuspendModal(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-4">
              <p className="text-sm text-gray-600">
                Vous êtes sur le point de suspendre le compte de <strong>{selectedUser?.prenom} {selectedUser?.nom}</strong>.
                L'utilisateur ne pourra plus se connecter.
              </p>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Raison de la suspension <span className="text-gray-400">(optionnel)</span>
                </label>
                <textarea
                  value={suspendReason}
                  onChange={(e) => setSuspendReason(e.target.value)}
                  placeholder="Indiquez la raison de la suspension..."
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-coris-blue"
                />
              </div>
              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowSuspendModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition"
                >
                  Annuler
                </button>
                <button
                  onClick={handleConfirmSuspend}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition"
                >
                  Suspendre
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
