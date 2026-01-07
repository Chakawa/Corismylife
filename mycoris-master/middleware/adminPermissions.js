/**
 * Middleware de vérification des permissions administrateur
 * Gère les différents niveaux d'accès selon le rôle
 * Rôles: super_admin, admin, moderation, commercial, client
 */

/**
 * Vérifie si l'utilisateur a les permissions requises
 * @param {Array} allowedRoles - Rôles autorisés ['super_admin', 'admin', 'moderation']
 */
const requireAdminType = (allowedRoles = []) => {
  return (req, res, next) => {
    // Vérifier que l'utilisateur est authentifié
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentification requise'
      });
    }

    // Vérifier que l'utilisateur est admin (un des rôles admin spécifiés)
    const adminRoles = ['super_admin', 'admin', 'moderation'];
    if (!adminRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé aux administrateurs'
      });
    }

    // Si aucun type spécifique requis, autoriser tous les admins
    if (allowedRoles.length === 0) {
      return next();
    }

    // Vérifier le rôle
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Accès réservé aux utilisateurs: ${allowedRoles.join(', ')}`,
        requiredRoles: allowedRoles,
        userRole: req.user.role
      });
    }

    next();
  };
};

/**
 * Raccourcis pour les rôles courants
 */
const requireSuperAdmin = requireAdminType(['super_admin']);
const requireAdminOrAbove = requireAdminType(['super_admin', 'admin']);
const requireAnyAdmin = requireAdminType([]);

/**
 * Récupère les permissions selon le rôle
 */
const getAdminPermissions = (role) => {
  const permissions = {
    super_admin: {
      canManageUsers: true,
      canManageAdmins: true,
      canManageContracts: true,
      canManageProducts: true,
      canManageCommercials: true,
      canViewReports: true,
      canModifySettings: true,
      canDeleteData: true,
      canViewAuditLogs: true,
      dashboardAccess: ['stats', 'users', 'contracts', 'products', 'commercials', 'reports', 'settings']
    },
    admin: {
      canManageUsers: true,
      canManageAdmins: false,
      canManageContracts: true,
      canManageProducts: true,
      canManageCommercials: true,
      canViewReports: true,
      canModifySettings: false,
      canDeleteData: false,
      canViewAuditLogs: false,
      dashboardAccess: ['stats', 'users', 'contracts', 'products', 'commercials', 'reports']
    },
    moderation: {
      canManageUsers: false,
      canManageAdmins: false,
      canManageContracts: false,
      canManageProducts: false,
      canManageCommercials: false,
      canViewReports: true,
      canModifySettings: false,
      canDeleteData: false,
      canViewAuditLogs: false,
      dashboardAccess: ['stats', 'reports']
    }
  };

  return permissions[role] || permissions.admin;
};

module.exports = {
  requireAdminType,
  requireSuperAdmin,
  requireAdminOrAbove,
  requireAnyAdmin,
  getAdminPermissions
};
