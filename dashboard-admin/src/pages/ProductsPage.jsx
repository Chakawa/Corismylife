import React from 'react'
import { Plus, Edit, Trash2, Eye } from 'lucide-react'

export default function ProductsPage() {
  const products = [
    { id: 1, name: 'CORIS SÉRÉNITÉ', description: 'Assurance décès', premium: 25000 },
    { id: 2, name: 'ÉPARGNE BONUS', description: 'Épargne + assurance', premium: 50000 },
    { id: 3, name: 'CORIS ÉTUDE', description: 'Assurance études', premium: 15000 },
    { id: 4, name: 'CORIS FAMILIS', description: 'Assurance famille', premium: 35000 },
    { id: 5, name: 'CORIS VIE FLEX', description: 'Assurance vie flexible', premium: 45000 },
  ]

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Gestion des Produits</h1>
          <p className="text-gray-600 mt-1">Gérez les produits d'assurance et leurs tarifs</p>
        </div>
        <button className="flex items-center gap-2 bg-coris-blue text-white px-4 py-2 rounded-lg hover:bg-coris-blue-light transition">
          <Plus className="w-5 h-5" />
          Nouveau produit
        </button>
      </div>

      {/* Grid of Products */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {products.map(product => (
          <div key={product.id} className="bg-white rounded-2xl shadow-md overflow-hidden hover:shadow-lg transition">
            {/* Header */}
            <div className="h-24 bg-gradient-to-r from-coris-blue to-coris-blue-light flex items-center justify-center">
              <div className="text-center">
                <h3 className="text-white font-bold text-lg">{product.name}</h3>
              </div>
            </div>

            {/* Content */}
            <div className="p-6 space-y-4">
              <p className="text-gray-600">{product.description}</p>
              <div className="border-t pt-4">
                <p className="text-sm text-gray-500 mb-1">Prime de base</p>
                <p className="text-2xl font-bold text-coris-green">
                  {new Intl.NumberFormat('fr-CI', { style: 'currency', currency: 'XOF' }).format(product.premium)}
                </p>
              </div>

              {/* Actions */}
              <div className="flex gap-2 pt-4 border-t">
                <button className="flex-1 flex items-center justify-center gap-2 text-coris-blue hover:bg-blue-50 py-2 rounded transition">
                  <Eye className="w-4 h-4" />
                  Voir
                </button>
                <button className="flex-1 flex items-center justify-center gap-2 text-coris-blue hover:bg-blue-50 py-2 rounded transition">
                  <Edit className="w-4 h-4" />
                  Éditer
                </button>
                <button className="flex-1 flex items-center justify-center gap-2 text-coris-red hover:bg-red-50 py-2 rounded transition">
                  <Trash2 className="w-4 h-4" />
                  Supprimer
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Statistics */}
      <div className="grid grid-cols-4 gap-4 mt-8">
        <div className="bg-white rounded-2xl shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Total Produits</p>
          <p className="text-2xl font-bold text-coris-blue">{products.length}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Prime Moyenne</p>
          <p className="text-2xl font-bold text-coris-green">
            {new Intl.NumberFormat('fr-CI', {
              style: 'currency',
              currency: 'XOF',
              maximumFractionDigits: 0
            }).format(products.reduce((sum, p) => sum + p.premium, 0) / products.length)}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Prime Max</p>
          <p className="text-2xl font-bold text-coris-orange">
            {new Intl.NumberFormat('fr-CI', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(Math.max(...products.map(p => p.premium)))}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow p-4">
          <p className="text-gray-600 text-sm mb-1">Prime Min</p>
          <p className="text-2xl font-bold text-coris-red">
            {new Intl.NumberFormat('fr-CI', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(Math.min(...products.map(p => p.premium)))}
          </p>
        </div>
      </div>
    </div>
  )
}
