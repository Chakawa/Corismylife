import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import LoginPage from './pages/LoginPage'
import DashboardLayout from './components/layout/DashboardLayout'
import DashboardPage from './pages/DashboardPage'
import AdminDashboard from './pages/AdminDashboard'
import AccessDeniedPage from './pages/AccessDeniedPage'
import UsersPage from './pages/UsersPage'
import ContractsPage from './pages/ContractsPage'
import SubscriptionsPage from './pages/SubscriptionsPage'
import CommissionsPage from './pages/CommissionsPage'
import ProductsPage from './pages/ProductsPage'
import SettingsPage from './pages/SettingsPage'
import ActivitiesPage from './pages/ActivitiesPage'
import ProtectedRoute from './components/ProtectedRoute'
import permissionsService from './services/permissions.service'

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Vérifier si l'utilisateur est déjà connecté
    const token = localStorage.getItem('adminToken')
    if (token) {
      setIsAuthenticated(true)
      // Charger les permissions
      permissionsService.fetchPermissions()
    }
    setIsLoading(false)
  }, [])

  const handleLogin = () => {
    setIsAuthenticated(true)
    // Charger les permissions après connexion
    permissionsService.fetchPermissions()
  }

  const handleLogout = () => {
    localStorage.removeItem('adminToken')
    permissionsService.clearCache()
    setIsAuthenticated(false)
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-coris-gray">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-coris-blue"></div>
      </div>
    )
  }

  return (
    <Router>
      <Routes>
        <Route
          path="/login"
          element={
            isAuthenticated ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <LoginPage onLogin={handleLogin} />
            )
          }
        />
        <Route
          path="/"
          element={
            isAuthenticated ? (
              <DashboardLayout onLogout={handleLogout} />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="users" element={
            <ProtectedRoute requiredPage="users">
              <UsersPage />
            </ProtectedRoute>
          } />
          <Route path="contracts" element={
            <ProtectedRoute requiredPage="contracts">
              <ContractsPage />
            </ProtectedRoute>
          } />
          <Route path="subscriptions" element={
            <ProtectedRoute requiredPage="contracts">
              <SubscriptionsPage />
            </ProtectedRoute>
          } />
          <Route path="commissions" element={
            <ProtectedRoute requiredPage="contracts">
              <CommissionsPage />
            </ProtectedRoute>
          } />
          <Route path="products" element={
            <ProtectedRoute requiredPage="products">
              <ProductsPage />
            </ProtectedRoute>
          } />
          <Route path="settings" element={
            <ProtectedRoute requiredAdminTypes={['super_admin']}>
              <SettingsPage />
            </ProtectedRoute>
          } />
          <Route path="activities" element={
            <ProtectedRoute requiredPage="stats">
              <ActivitiesPage />
            </ProtectedRoute>
          } />
          <Route path="access-denied" element={<AccessDeniedPage />} />
        </Route>
        <Route path="*" element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <Navigate to="/login" replace />} />
      </Routes>
    </Router>
  )
}

export default App
