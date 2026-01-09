/**
 * SCRIPT DE CORRECTION : Mettre à jour le frontend pour afficher les deux types d'activités
 */

const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'dashboard-admin', 'src', 'pages', 'ActivitiesPage.jsx');
let content = fs.readFileSync(filePath, 'utf8');

// Remplacer le code d'affichage des activités pour supporter les deux types
const oldMap = `            {activities.map((a) => (
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
            ))}`;

const newMap = `            {activities.map((a) => {
              // Déterminer le type d'activité et l'icône correspondante
              const isAdminAction = a.activity_type === 'admin_action'
              const icon = isAdminAction ? '⚙️' : '📝'
              const bgColor = isAdminAction ? 'bg-amber-100' : 'bg-coris-blue/10'
              
              return (
                <div key={a.id} className="flex items-start gap-4 pb-4 border-b border-gray-100 last:border-0">
                  <div className={\`p-2 \${bgColor} rounded-lg text-2xl\`}>{icon}</div>
                  <div className="flex-1">
                    {isAdminAction ? (
                      // Affichage pour les actions admin
                      <>
                        <p className="text-sm text-gray-900 font-medium">
                          {a.nom_client || 'Action administrateur'}
                        </p>
                        <p className="text-xs text-gray-500 mt-1">
                          Type: {a.produit || '—'} • Statut: {a.statut || '—'}
                        </p>
                      </>
                    ) : (
                      // Affichage pour les souscriptions
                      <>
                        <p className="text-sm text-gray-900 font-medium">
                          Souscription {a.prenom_client || ''} {a.nom_client || ''}
                        </p>
                        <p className="text-xs text-gray-500 mt-1">
                          Produit: {a.produit || '—'} • Statut: {a.statut || '—'}
                        </p>
                      </>
                    )}
                  </div>
                  <span className="text-xs text-gray-400 whitespace-nowrap">{formatDate(a.created_at || a.date)}</span>
                </div>
              )
            })}`;

content = content.replace(oldMap, newMap);
fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ ActivitiesPage - affichage des activités admin intégré');
