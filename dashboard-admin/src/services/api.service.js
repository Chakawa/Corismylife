import api from '../utils/api'

export const authService = {
  login: async (email, password) => {
    const response = await api.post('/auth/login', { email, password })
    if (response.data.success && response.data.token) {
      localStorage.setItem('adminToken', response.data.token)
      return response.data
    }
    throw new Error('Connexion échouée')
  },

  logout: () => {
    localStorage.removeItem('adminToken')
  },

  getCurrentUser: async () => {
    const response = await api.get('/auth/profile')
    return response.data
  }
}

export const dashboardService = {
  getStats: async () => {
    const response = await api.get('/admin/stats')
    return response.data
  },

  getRecentActivities: async (params) => {
    const response = await api.get('/admin/activities', { params })
    return response.data
  }
}

export const usersService = {
  getAll: async (params) => {
    const response = await api.get('/admin/users', { params })
    return response.data
  },

  getById: async (id) => {
    const response = await api.get(`/admin/users/${id}`)
    return response.data
  },

  create: async (userData) => {
    const response = await api.post('/admin/users', userData)
    return response.data
  },

  update: async (id, userData) => {
    const response = await api.put(`/admin/users/${id}`, userData)
    return response.data
  },

  delete: async (id) => {
    const response = await api.delete(`/admin/users/${id}`)
    return response.data
  }
}

export const contractsService = {
  getAll: async (params) => {
    const response = await api.get('/admin/contracts', { params })
    return response.data
  },

  getById: async (id) => {
    const response = await api.get(`/admin/contracts/${id}`)
    return response.data
  },

  create: async (contractData) => {
    const response = await api.post('/admin/contracts', contractData)
    return response.data
  },

  updateStatus: async (id, status) => {
    const response = await api.patch(`/admin/contracts/${id}/status`, { status })
    return response.data
  },

  delete: async (id) => {
    const response = await api.delete(`/admin/contracts/${id}`)
    return response.data
  }
}

export const subscriptionsService = {
  getAll: async (params) => {
    const response = await api.get('/admin/subscriptions', { params })
    return response.data
  },

  getById: async (id) => {
    const response = await api.get(`/admin/subscriptions/${id}`)
    return response.data
  },

  create: async (subscriptionData) => {
    const response = await api.post('/admin/subscriptions', subscriptionData)
    return response.data
  },

  updateStatus: async (id, status) => {
    const response = await api.patch(`/admin/subscriptions/${id}/status`, { status })
    return response.data
  },

  delete: async (id) => {
    const response = await api.delete(`/admin/subscriptions/${id}`)
    return response.data
  },

  approve: async (id) => {
    const response = await api.post(`/admin/subscriptions/${id}/approve`)
    return response.data
  },

  reject: async (id, reason) => {
    const response = await api.post(`/admin/subscriptions/${id}/reject`, { reason })
    return response.data
  }
}

export const commissionsService = {
  getAll: async (params) => {
    const response = await api.get('/admin/commissions', { params })
    return response.data
  },

  getById: async (id) => {
    const response = await api.get(`/admin/commissions/${id}`)
    return response.data
  },

  create: async (commissionData) => {
    const response = await api.post('/admin/commissions', commissionData)
    return response.data
  },

  delete: async (id) => {
    const response = await api.delete(`/admin/commissions/${id}`)
    return response.data
  },

  getStats: async () => {
    const response = await api.get('/admin/commissions/stats')
    return response.data
  }
}

export const notificationsService = {
  getNotifications: async (params) => {
    const response = await api.get('/admin/notifications', { params })
    return response.data
  },

  markAsRead: async (id) => {
    const response = await api.put(`/admin/notifications/${id}/mark-read`)
    return response.data
  },

  delete: async (id) => {
    const response = await api.delete(`/admin/notifications/${id}`)
    return response.data
  },

  create: async (notificationData) => {
    const response = await api.post('/admin/notifications/create', notificationData)
    return response.data
  }
}
