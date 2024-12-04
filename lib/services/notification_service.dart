import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';
import 'extended_database_helper.dart';

class NotificationService extends ChangeNotifier {
  final ExtendedDatabaseHelper _dbHelper;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  NotificationService(this._dbHelper) : _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    _initializeNotifications();
  }

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<void> loadNotifications(String uidno) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getNotifications(uidno);
      _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
      _updateUnreadCount();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.addNotification(notification.toJson());
      _notifications.insert(0, notification);
      _updateUnreadCount();
      _error = null;

      // Show local notification
      await _showLocalNotification(notification);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      // Update in database
      await _dbHelper.updateNotification({
        'id': notificationId,
        'read': 1,
      });

      // Update in memory
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification = AppNotification(
          id: notificationId,
          uidno: _notifications[index].uidno,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          date: _notifications[index].date,
          read: true,
        );
        _notifications[index] = updatedNotification;
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.read).length;
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notification.id ?? 0,
      notification.title,
      notification.message,
      details,
    );
  }

  Future<void> clearAll() async {
    try {
      await _dbHelper.clearNotifications();
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }
} 