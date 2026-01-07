import { useState } from 'react'
import { authService } from '../services/api.service'
import { Lock, Mail, Eye, EyeOff } from 'lucide-react'

export default function LoginPage({ onLogin }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const result = await authService.login(email, password)
      const adminRoles = ['super_admin', 'admin', 'moderation']
      if (!adminRoles.includes(result.user.role)) {
        throw new Error('Accès non autorisé. Seuls les administrateurs peuvent se connecter.')
      }
      onLogin()
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Erreur de connexion')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-coris-blue from-5% via-white via-50% to-coris-blue to-95% flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo Image - Same as mobile */}
        <div className="flex justify-center mb-12">
          <img 
            src="/logo.png" 
            alt="CORIS Logo" 
            className="w-20 h-20 object-contain drop-shadow-lg hover:drop-shadow-2xl transition-all"
          />
        </div>

        {/* Card with styles matching mobile */}
        <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
          {/* Header */}
          <div className="px-8 pt-8 pb-6">
            <h1 className="text-3xl font-bold text-center text-coris-blue mb-3">
              Bienvenue
            </h1>
            <p className="text-center text-gray-600 text-sm">
              Connectez-vous à votre espace CORIS Assurances Vie
            </p>
          </div>

          {/* Form Content */}
          <form onSubmit={handleSubmit} className="px-8 pb-8 space-y-6">
            {/* Email Field - Mobile style */}
            <div>
              <label className="block text-sm font-semibold text-coris-blue mb-3">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-coris-blue pointer-events-none" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-14 pr-4 py-3 border-2 border-gray-200 rounded-2xl focus:outline-none focus:border-coris-red focus:ring-0 text-gray-700 placeholder-gray-400 transition-colors"
                  placeholder="exemple@email.com"
                  required
                />
              </div>
            </div>

            {/* Password Field - Mobile style */}
            <div>
              <label className="block text-sm font-semibold text-coris-blue mb-3">
                Mot de passe
              </label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-coris-blue pointer-events-none" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-14 pr-14 py-3 border-2 border-gray-200 rounded-2xl focus:outline-none focus:border-coris-red focus:ring-0 text-gray-700 placeholder-gray-400 transition-colors"
                  placeholder="••••••••"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 transform -translate-y-1/2 text-coris-blue opacity-70 hover:opacity-100 transition"
                >
                  {showPassword ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
            </div>

            {/* Error Message */}
            {error && (
              <div className="bg-red-50 border-l-4 border-coris-red rounded-lg p-4 flex items-start gap-3">
                <div className="flex-shrink-0 mt-0.5">
                  <svg className="w-5 h-5 text-coris-red" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                </div>
                <p className="text-red-800 text-sm font-medium">{error}</p>
              </div>
            )}

            {/* Submit Button - Mobile style gradient */}
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-coris-blue to-blue-900 hover:shadow-lg text-white font-bold py-3 px-4 rounded-2xl transition duration-300 disabled:opacity-50 flex items-center justify-center gap-2 mt-8 shadow-md"
            >
              {loading ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  <span>Connexion en cours...</span>
                </>
              ) : (
                <span>Se connecter</span>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
