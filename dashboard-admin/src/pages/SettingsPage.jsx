import React, { useState } from 'react'
import { Bell, Lock, Eye, Settings, Save, Upload, Download, DollarSign } from 'lucide-react'
import { productsService } from '../services/api.service'

export default function SettingsPage() {
  const [formData, setFormData] = useState({
    companyName: 'CORIS Assurance',
    email: 'admin@coris.ci',
    phone: '+225 27 22 XXX XXX',
    address: 'Plateau, Abidjan',
    city: 'Abidjan',
    country: 'Côte d\'Ivoire',
    notifications: {
      emailNotifications: true,
      smsAlerts: true,
      newSubscriptions: true,
      expiredContracts: true
    },
    security: {
      twoFactorAuth: false,
      loginAttempts: 5,
      sessionTimeout: 30
    }
  })

  const [saved, setSaved] = useState(false)
  const [importing, setImporting] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState('')
  const [showProductSelector, setShowProductSelector] = useState(false)
  const [pendingFile, setPendingFile] = useState(null)
  const [showExportProductSelector, setShowExportProductSelector] = useState(false)
  const [selectedExportProduct, setSelectedExportProduct] = useState('')

  const handleExportTarifs = async () => {
    if (!selectedExportProduct) {
      setShowExportProductSelector(true)
      return
    }

    try {
      const token = localStorage.getItem('adminToken')
      const response = await fetch(`http://localhost:5000/api/admin/tarifs/export?product=${selectedExportProduct}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })
      
      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.message || 'Erreur lors de l\'export')
      }
      
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `tarifs_${selectedExportProduct.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.csv`
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
      
      alert(`Export réussi! Les tarifs de ${selectedExportProduct} ont été téléchargés.`)
      setShowExportProductSelector(false)
      setSelectedExportProduct('')
    } catch (error) {
      console.error('Erreur export:', error)
      alert('Erreur lors de l\'export des tarifs: ' + error.message)
    }
  }

  const handleFileSelect = (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    
    if (!file.name.match(/\.(xlsx|xls)$/)) {
      alert('Veuillez sélectionner un fichier Excel (.xlsx ou .xls)')
      e.target.value = ''
      return
    }
    
    setPendingFile(file)
    setShowProductSelector(true)
    e.target.value = ''
  }

  const handleImportTarifs = async () => {
    if (!selectedProduct || !pendingFile) {
      alert('Veuillez sélectionner un produit')
      return
    }
    
    const formData = new FormData()
    formData.append('file', pendingFile)
    formData.append('product', selectedProduct)
    
    setImporting(true)
    setShowProductSelector(false)
    
    try {
      const response = await fetch('http://localhost:5000/api/admin/tarifs/import', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        },
        body: formData
      })
      
      const result = await response.json()
      
      if (response.ok) {
        alert(`Import réussi! ${result.imported || 0} tarifs importés pour le produit ${selectedProduct}.`)
        setSelectedProduct('')
        setPendingFile(null)
      } else {
        throw new Error(result.message || 'Erreur lors de l\'import')
      }
    } catch (error) {
      console.error('Erreur import:', error)
      alert('Erreur lors de l\'import des tarifs: ' + error.message)
    } finally {
      setImporting(false)
    }
  }

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }))
  }

  const handleSave = () => {
    setSaved(true)
    setTimeout(() => setSaved(false), 3000)
  }

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Paramètres Système</h1>
        <p className="text-gray-600 mt-1">Gérez les paramètres généraux de l'application</p>
      </div>

      {/* Notification */}
      {saved && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center gap-3">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <p className="text-green-800 font-medium">Paramètres sauvegardés avec succès</p>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-2 border-b border-gray-200">
        <button className="px-4 py-2 font-semibold text-coris-blue border-b-2 border-coris-blue">
          Général
        </button>
        <button className="px-4 py-2 font-medium text-gray-600 hover:text-gray-900">
          Notifications
        </button>
        <button className="px-4 py-2 font-medium text-gray-600 hover:text-gray-900">
          Sécurité
        </button>
      </div>

      {/* General Settings */}
      <div className="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
          <Settings className="w-5 h-5" />
          Informations Générales
        </h2>

        <div className="grid grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Nom de l'Entreprise</label>
            <input
              type="text"
              name="companyName"
              value={formData.companyName}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Email Principal</label>
            <input
              type="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Téléphone</label>
            <input
              type="tel"
              name="phone"
              value={formData.phone}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Adresse</label>
            <input
              type="text"
              name="address"
              value={formData.address}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Ville</label>
            <input
              type="text"
              name="city"
              value={formData.city}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Pays</label>
            <input
              type="text"
              name="country"
              value={formData.country}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
            />
          </div>
        </div>
      </div>

      {/* Notifications */}
      <div className="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
          <Bell className="w-5 h-5" />
          Paramètres de Notifications
        </h2>

        <div className="space-y-4">
          <label className="flex items-center gap-3 cursor-pointer hover:bg-gray-50 p-3 rounded">
            <input
              type="checkbox"
              name="emailNotifications"
              checked={formData.notifications.emailNotifications}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                notifications: { ...prev.notifications, emailNotifications: e.target.checked }
              }))}
              className="w-5 h-5 accent-coris-blue"
            />
            <div>
              <p className="font-medium text-gray-900">Notifications par Email</p>
              <p className="text-sm text-gray-600">Recevoir les alertes importantes par email</p>
            </div>
          </label>

          <label className="flex items-center gap-3 cursor-pointer hover:bg-gray-50 p-3 rounded">
            <input
              type="checkbox"
              name="smsAlerts"
              checked={formData.notifications.smsAlerts}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                notifications: { ...prev.notifications, smsAlerts: e.target.checked }
              }))}
              className="w-5 h-5 accent-coris-blue"
            />
            <div>
              <p className="font-medium text-gray-900">Alertes SMS</p>
              <p className="text-sm text-gray-600">Recevoir les alertes critiques par SMS</p>
            </div>
          </label>

          <label className="flex items-center gap-3 cursor-pointer hover:bg-gray-50 p-3 rounded">
            <input
              type="checkbox"
              name="newSubscriptions"
              checked={formData.notifications.newSubscriptions}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                notifications: { ...prev.notifications, newSubscriptions: e.target.checked }
              }))}
              className="w-5 h-5 accent-coris-blue"
            />
            <div>
              <p className="font-medium text-gray-900">Nouvelles Souscriptions</p>
              <p className="text-sm text-gray-600">Être notifié des nouvelles souscriptions en attente</p>
            </div>
          </label>

          <label className="flex items-center gap-3 cursor-pointer hover:bg-gray-50 p-3 rounded">
            <input
              type="checkbox"
              name="expiredContracts"
              checked={formData.notifications.expiredContracts}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                notifications: { ...prev.notifications, expiredContracts: e.target.checked }
              }))}
              className="w-5 h-5 accent-coris-blue"
            />
            <div>
              <p className="font-medium text-gray-900">Contrats Expirés</p>
              <p className="text-sm text-gray-600">Être notifié des contrats arrivant à expiration</p>
            </div>
          </label>
        </div>
      </div>

      {/* Security Settings */}
      <div className="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
          <Lock className="w-5 h-5" />
          Paramètres de Sécurité
        </h2>

        <div className="space-y-6">
          <label className="flex items-center gap-3 cursor-pointer hover:bg-gray-50 p-3 rounded">
            <input
              type="checkbox"
              name="twoFactorAuth"
              checked={formData.security.twoFactorAuth}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                security: { ...prev.security, twoFactorAuth: e.target.checked }
              }))}
              className="w-5 h-5 accent-coris-blue"
            />
            <div>
              <p className="font-medium text-gray-900">Authentification à Deux Facteurs</p>
              <p className="text-sm text-gray-600">Sécuriser l'accès avec 2FA</p>
            </div>
          </label>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Nombre de tentatives de connexion autorisées
            </label>
            <input
              type="number"
              name="loginAttempts"
              value={formData.security.loginAttempts}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                security: { ...prev.security, loginAttempts: parseInt(e.target.value) }
              }))}
              className="w-full md:w-64 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
              min="3"
              max="10"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Délai d'expiration de session (minutes)
            </label>
            <input
              type="number"
              name="sessionTimeout"
              value={formData.security.sessionTimeout}
              onChange={(e) => setFormData(prev => ({
                ...prev,
                security: { ...prev.security, sessionTimeout: parseInt(e.target.value) }
              }))}
              className="w-full md:w-64 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue"
              min="15"
              max="240"
            />
          </div>
        </div>
      </div>

      {/* Gestion des Tarifs */}
      <div className="bg-white rounded-lg shadow p-6 space-y-6">
        <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
          <DollarSign className="w-5 h-5" />
          Gestion des Tarifs Produits
        </h2>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <p className="text-sm text-blue-800 mb-3">
            <strong>Important :</strong> Utilisez les fichiers Excel pour importer ou exporter les grilles tarifaires de vos produits d'assurance.
          </p>
          <ul className="text-sm text-blue-700 list-disc list-inside space-y-1">
            <li>Format attendu : Produit, Âge, Durée, Périodicité, Prime, Capital, Catégorie</li>
            <li>L'import mettra à jour les tarifs existants dans la base de données</li>
            <li>L'export génère un fichier Excel avec tous les tarifs actuels</li>
          </ul>
        </div>

        <div className="grid grid-cols-2 gap-6">
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-coris-blue transition">
            <div className="text-center">
              <Download className="w-12 h-12 text-coris-blue mx-auto mb-3" />
              <h3 className="font-semibold text-gray-900 mb-2">Exporter les Tarifs</h3>
              <p className="text-sm text-gray-600 mb-4">
                Téléchargez tous les tarifs actuels au format Excel
              </p>
              <button 
                onClick={handleExportTarifs}
                className="flex items-center gap-2 bg-coris-green text-white px-4 py-2 rounded-lg hover:bg-green-600 transition mx-auto"
              >
                <Download className="w-4 h-4" />
                Télécharger Excel
              </button>
            </div>
          </div>

          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-coris-blue transition">
            <div className="text-center">
              <Upload className="w-12 h-12 text-coris-orange mx-auto mb-3" />
              <h3 className="font-semibold text-gray-900 mb-2">Importer les Tarifs</h3>
              <p className="text-sm text-gray-600 mb-4">
                Mettez à jour les tarifs depuis un fichier Excel
              </p>
              <label className="flex items-center gap-2 bg-coris-orange text-white px-4 py-2 rounded-lg hover:bg-orange-600 transition mx-auto cursor-pointer w-fit">
                <Upload className="w-4 h-4" />
                Sélectionner Excel
                <input 
                  type="file" 
                  accept=".xlsx,.xls" 
                  className="hidden"
                  onChange={handleFileSelect}
                  disabled={importing}
                />
              </label>
              {importing && (
                <p className="text-sm text-gray-600 mt-2">Import en cours...</p>
              )}
            </div>
          </div>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <p className="text-sm text-yellow-800">
            <strong>⚠️ Attention :</strong> Assurez-vous de vérifier les données avant d'importer. Les tarifs incorrects peuvent affecter les calculs de prime dans l'application mobile.
          </p>
        </div>
      </div>

      {/* Modal de sélection de produit */}
      {showProductSelector && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Sélectionnez le produit</h3>
            <p className="text-sm text-gray-600 mb-4">
              Pour quel produit souhaitez-vous importer les tarifs ?
            </p>
            <select
              value={selectedProduct}
              onChange={(e) => setSelectedProduct(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue mb-4"
            >
              <option value="">-- Choisir un produit --</option>
              <option value="CORIS SERENITE">CORIS SERENITE</option>
              <option value="CORIS ETUDE">CORIS ETUDE</option>
              <option value="CORIS RETRAITE">CORIS RETRAITE</option>
              <option value="CORIS FAMILIS">CORIS FAMILIS</option>
              <option value="CORIS SOLIDARITE">CORIS SOLIDARITE</option>
              <option value="FLEX EMPRUNTEUR">FLEX EMPRUNTEUR</option>
              <option value="CORIS EPARGNE BONUS">CORIS EPARGNE BONUS</option>
              <option value="CORIS ASSURE PRESTIGE">CORIS ASSURE PRESTIGE</option>
              <option value="MON BON PLAN CORIS">MON BON PLAN CORIS</option>
            </select>
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => {
                  setShowProductSelector(false)
                  setSelectedProduct('')
                  setPendingFile(null)
                }}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Annuler
              </button>
              <button
                onClick={handleImportTarifs}
                disabled={!selectedProduct}
                className="px-4 py-2 bg-coris-blue text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Importer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de sélection de produit pour export */}
      {showExportProductSelector && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Sélectionnez le produit à exporter</h3>
            <p className="text-sm text-gray-600 mb-4">
              Choisissez le produit dont vous souhaitez exporter les tarifs
            </p>
            <select
              value={selectedExportProduct}
              onChange={(e) => setSelectedExportProduct(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-coris-blue mb-4"
            >
              <option value="">-- Choisir un produit --</option>
              <option value="CORIS SERENITE">CORIS SERENITE</option>
              <option value="CORIS ETUDE">CORIS ETUDE</option>
              <option value="CORIS RETRAITE">CORIS RETRAITE</option>
              <option value="CORIS FAMILIS">CORIS FAMILIS</option>
              <option value="CORIS SOLIDARITE">CORIS SOLIDARITE</option>
              <option value="FLEX EMPRUNTEUR">FLEX EMPRUNTEUR</option>
              <option value="CORIS EPARGNE BONUS">CORIS EPARGNE BONUS</option>
              <option value="CORIS ASSURE PRESTIGE">CORIS ASSURE PRESTIGE</option>
              <option value="MON BON PLAN CORIS">MON BON PLAN CORIS</option>
            </select>
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => {
                  setShowExportProductSelector(false)
                  setSelectedExportProduct('')
                }}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Annuler
              </button>
              <button
                onClick={handleExportTarifs}
                disabled={!selectedExportProduct}
                className="px-4 py-2 bg-coris-green text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Exporter
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Save Button */}
      <div className="flex gap-3">
        <button
          onClick={handleSave}
          className="flex items-center gap-2 bg-coris-blue text-white px-6 py-3 rounded-lg hover:bg-coris-blue-light transition font-medium"
        >
          <Save className="w-5 h-5" />
          Enregistrer les modifications
        </button>
        <button className="flex items-center gap-2 border border-gray-300 text-gray-700 px-6 py-3 rounded-lg hover:bg-gray-50 transition font-medium">
          Annuler
        </button>
      </div>
    </div>
  )
}
