import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect, useRef } from 'react'
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
import SimulationsPage from './pages/SimulationsPage'
import ProtectedRoute from './components/ProtectedRoute'
import permissionsService from './services/permissions.service'
import { authService } from './services/api.service'

const SESSION_TIMEOUT_MS = 5 * 60 * 1000

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const inactivityTimerRef = useRef(null)
  const logoutInProgressRef = useRef(false)

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

  const performLogout = async (reason = 'manual_logout') => {
    if (logoutInProgressRef.current) return

    logoutInProgressRef.current = true
    try {
      await authService.logout(reason)
    } finally {
      if (inactivityTimerRef.current) {
        clearTimeout(inactivityTimerRef.current)
      }
      permissionsService.clearCache()
      setIsAuthenticated(false)
      logoutInProgressRef.current = false
    }
  }

  const resetInactivityTimer = () => {
    if (!isAuthenticated) return

    if (inactivityTimerRef.current) {
      clearTimeout(inactivityTimerRef.current)
    }

    inactivityTimerRef.current = setTimeout(() => {
      performLogout('system_timeout')
    }, SESSION_TIMEOUT_MS)
  }

  useEffect(() => {
    if (!isAuthenticated) {
      if (inactivityTimerRef.current) {
        clearTimeout(inactivityTimerRef.current)
      }
      return
    }

    const activityEvents = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart', 'click']
    activityEvents.forEach((eventName) => window.addEventListener(eventName, resetInactivityTimer, true))
    resetInactivityTimer()

    return () => {
      activityEvents.forEach((eventName) => window.removeEventListener(eventName, resetInactivityTimer, true))
      if (inactivityTimerRef.current) {
        clearTimeout(inactivityTimerRef.current)
      }
    }
  }, [isAuthenticated])

  const handleLogin = () => {
    setIsAuthenticated(true)
    // Charger les permissions après connexion
    permissionsService.fetchPermissions()
  }

  const handleLogout = () => {
    performLogout('manual_logout')
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
          <Route path="simulations" element={
            <ProtectedRoute requiredPage="stats">
              <SimulationsPage />
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
