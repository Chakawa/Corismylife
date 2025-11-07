import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycorislife/services/notification_service.dart';

/// Page d'affichage des notifications
/// Montre toutes les notifications de l'utilisateur (contrats, propositions, rappels, etc.)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ===================================
  // CONSTANTES DE COULEURS
  // ===================================
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;
  static const Color fondGris = Color(0xFFF0F4F8);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color orangeWarning = Color(0xFFF59E0B);
  static const Color rougeCoris = Color(0xFFE30613);

  // ===================================
  // DONNÉES DE NOTIFICATIONS
  // ===================================
  List<NotificationItem> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Charge les notifications depuis l'API
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final data = await NotificationService.getNotifications();
      final notifList = data['notifications'] as List;

      setState(() {
        notifications =
            notifList.map((notif) => NotificationItem.fromJson(notif)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement notifications: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des notifications'),
            backgroundColor: rougeCoris,
          ),
        );
      }
    }
  }

  // ===================================
  // MÉTHODES
  // ===================================

  /// Marque une notification comme lue
  Future<void> _markAsRead(int notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);

      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index].isRead = true;
        }
      });
    } catch (e) {
      debugPrint('Erreur marquage notification: $e');
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();

      setState(() {
        for (var notification in notifications) {
          notification.isRead = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Toutes les notifications ont été marquées comme lues'),
            backgroundColor: vertSucces,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur marquage notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du marquage des notifications'),
            backgroundColor: rougeCoris,
          ),
        );
      }
    }
  }

  /// Supprime une notification
  void _deleteNotification(int notificationId) {
    setState(() {
      notifications.removeWhere((n) => n.id == notificationId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification supprimée'),
        backgroundColor: grisTexte,
      ),
    );
  }

  /// Compte le nombre de notifications non lues
  int get _unreadCount => notifications.where((n) => !n.isRead).length;

  // ===================================
  // INTERFACE UTILISATEUR
  // ===================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondGris,
      appBar: AppBar(
        title: Text(
          'Notifications${_unreadCount > 0 ? " ($_unreadCount)" : ""}',
          style: const TextStyle(color: blanc, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bleuCoris,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: blanc),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tout marquer lu',
                style: TextStyle(color: blanc, fontSize: 14),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: bleuCoris),
            )
          : notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(notifications[index]);
                  },
                ),
    );
  }

  /// Construit l'état vide (aucune notification)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 100,
            color: grisTexte.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: grisTexte.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de notifications',
            style: TextStyle(
              fontSize: 14,
              color: grisTexte.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de notification
  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: rougeCoris,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: blanc,
          size: 28,
        ),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: blanc,
            borderRadius: BorderRadius.circular(12),
            border: !notification.isRead
                ? Border.all(color: bleuCoris, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône selon le type de notification
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Contenu de la notification
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: bleuCoris,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: grisTexte,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Date
                    Text(
                      _formatDate(notification.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: grisTexte.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicateur non lu
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: bleuCoris,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retourne l'icône selon le type de notification
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.contract:
        return Icons.assignment_turned_in;
      case NotificationType.proposition:
        return Icons.description;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  /// Retourne la couleur selon le type de notification
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.contract:
        return vertSucces;
      case NotificationType.proposition:
        return orangeWarning;
      case NotificationType.payment:
        return bleuCoris;
      case NotificationType.reminder:
        return rougeCoris;
      case NotificationType.info:
        return grisTexte;
    }
  }

  /// Formate la date de la notification
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

// ===================================
// MODÈLES DE DONNÉES
// ===================================

/// Types de notifications
enum NotificationType {
  contract, // Nouveau contrat
  proposition, // Proposition en attente
  payment, // Paiement
  reminder, // Rappel
  info, // Information générale
}

/// Modèle pour une notification
class NotificationItem {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });

  /// Crée un NotificationItem depuis les données JSON de l'API
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      type: _parseNotificationType(json['type']),
      title: json['title'],
      message: json['message'],
      date: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  /// Parse le type de notification depuis une string
  static NotificationType _parseNotificationType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'contract':
        return NotificationType.contract;
      case 'proposition':
        return NotificationType.proposition;
      case 'payment':
        return NotificationType.payment;
      case 'reminder':
        return NotificationType.reminder;
      case 'info':
      default:
        return NotificationType.info;
    }
  }
}
