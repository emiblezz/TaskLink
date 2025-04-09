import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink/models/notification_model.dart';
import 'package:tasklink/services/supabase_service.dart';

class NotificationService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Initialize and listen for notifications


  // Fetch notifications for a user
  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabaseService.supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      if (response != null) {
        _notifications = (response as List)
            .map<NotificationModel>((json) => NotificationModel.fromJson(json))
            .toList();

        _unreadCount = _notifications.where((n) => n.status == 'Unread').length;
      } else {
        _notifications = [];
        _unreadCount = 0;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String notificationType,
    required String message,
  }) async {
    try {
      await _supabaseService.supabase.from('notifications').insert({
        'user_id': userId,
        'notification_type': notificationType,
        'notification_message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Unread',
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _supabaseService.supabase
          .from('notifications')
          .update({'status': 'Read'})
          .eq('notification_id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && _notifications[index].status == 'Unread') {
        _notifications[index] = _notifications[index].copyWith(status: 'Read');
        _unreadCount = max(0, _unreadCount - 1);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabaseService.supabase
          .from('notifications')
          .update({'status': 'Read'})
          .eq('user_id', userId)
          .eq('status', 'Unread');

      for (int i = 0; i < _notifications.length; i++) {
        if (_notifications[i].status == 'Unread') {
          _notifications[i] = _notifications[i].copyWith(status: 'Read');
        }
      }

      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Helper function for max value
  int max(int a, int b) {
    return a > b ? a : b;
  }
}

extension on SupabaseClient {
  on(RealtimeListenTypes postgresChanges, Null Function(dynamic payload) param1, {required String filter}) {}
}
