import React, { useState, useEffect } from 'react'
import { Eye, Package } from 'lucide-react'
import { productsService } from '../services/api.service'

export default function ProductsPage() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedProduct, setSelectedProduct] = useState(null)
  const [tarifs, setTarifs] = useState([])
  const [showTarifsModal, setShowTarifsModal] = useState(false)

  useEffect(() => {
    loadProducts()
  }, [])

  const loadProducts = async () => {
    try {
      setLoading(true)
      const response = await productsService.getAll()
      if (response.success) {
        setProducts(response.products)
      }
    } catch (error) {
      console.error('Erreur lors du chargement des produits:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleViewTarifs = async (product) => {
    try {
      setSelectedProduct(product)
      const response = await productsService.getTarifs(product.id)
      if (response.success) {
        setTarifs(response.tarifs)
        setShowTarifsModal(true)
      }
    } catch (error) {
      console.error('Erreur lors du chargement des tarifs:', error)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Produits d'Assurance</h1>
          <p className="text-gray-600 mt-1">Liste complète des produits disponibles dans l'application mobile</p>
        </div>
      </div>

      {/* Grid of Products */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {products.map(product => (
          <div key={product.id} className="bg-white rounded-2xl shadow-md overflow-hidden hover:shadow-lg transition">
            {/* Header */}
            <div className="h-24 bg-gradient-to-r from-coris-blue to-coris-blue-light flex items-center justify-center">
              <div className="text-center">
                <Package className="w-10 h-10 text-white mx-auto mb-2" />
                <h3 className="text-white font-bold text-lg">{product.libelle}</h3>
              </div>
            </div>

            {/* Content */}
            <div className="p-6 space-y-4">
              <div className="text-center">
                <p className="text-sm text-gray-500 mb-1">Code Produit</p>
                <p className="text-xl font-bold text-coris-blue">#{product.id}</p>
              </div>

              {/* Actions */}
              <div className="flex gap-2 pt-4 border-t">
                <button
                  onClick={() => handleViewTarifs(product)}
                  className="flex-1 flex items-center justify-center gap-2 text-coris-blue hover:bg-blue-50 py-2 rounded transition"
                >
                  <Eye className="w-4 h-4" />
                  Voir Tarifs
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Statistics */}
      <div className="grid grid-cols-3 gap-4 mt-8">
        <div className="bg-white rounded-2xl shadow p-6">
          <p className="text-gray-600 text-sm mb-1">Total Produits</p>
          <p className="text-3xl font-bold text-coris-blue">{products.length}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm mb-1">Produits Actifs</p>
          <p className="text-3xl font-bold text-coris-green">{products.length}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm mb-1">Catégories</p>
          <p className="text-3xl font-bold text-coris-orange">7</p>
        </div>
      </div>

      {/* Tarifs Modal */}
      {showTarifsModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-6xl w-full max-h-[90vh] overflow-hidden">
            <div className="bg-gradient-to-r from-coris-blue to-coris-blue-light text-white p-6">
              <h2 className="text-2xl font-bold">Grille Tarifaire - {selectedProduct?.libelle}</h2>
              <p className="text-blue-100 mt-1">{tarifs.length} tarifs disponibles</p>
            </div>

            <div className="p-6 overflow-y-auto max-h-[calc(90vh-200px)]">
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Âge</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Durée</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Périodicité</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Prime</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Capital</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Catégorie</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {tarifs.map((tarif, idx) => (
                      <tr key={idx} className="hover:bg-gray-50">
                        <td className="px-4 py-3 whitespace-nowrap text-sm">{tarif.age} ans</td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm">{tarif.duree_contrat} mois</td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm">{tarif.periodicite}</td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm font-semibold text-coris-blue">
                          {tarif.prime}
                        </td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm font-semibold text-coris-green">
                          {tarif.capital}
                        </td>
                        <td className="px-4 py-3 whitespace-nowrap text-sm">
                          <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs">{tarif.categorie}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="bg-gray-50 p-4 flex justify-end gap-3">
              <button
                onClick={() => setShowTarifsModal(false)}
                className="px-4 py-2 bg-gray-300 hover:bg-gray-400 text-gray-800 rounded-lg transition"
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
