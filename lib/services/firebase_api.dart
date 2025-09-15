import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initNotifications() async {
    debugPrint('🔵 Starting Firebase Messaging initialization...');
    
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('🔵 FCM Token: $fcmToken');

    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle notification clicks when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔵 Got initial message: ${message.data}');
        _handleNotificationClick(message.data);
      }
    });

    // Handle notification clicks when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔵 Message opened from background: ${message.data}');
      _handleNotificationClick(message.data);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔵 Got foreground message: ${message.data}');
      // You can show a local notification here if needed
    });
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get user_id from users table
      final userResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userResponse == null) return;

      final userId = userResponse['id'];

      // Get resident_id and current fcm_token
      final residentResponse = await _supabase
          .from('resident')
          .select('id, fcm_token')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) return;

      final residentId = residentResponse['id'];
      final currentToken = residentResponse['fcm_token'];

      // Only update if token is different or doesn't exist
      if (currentToken != token) {
        await _supabase
            .from('resident')
            .update({'fcm_token': token})
            .eq('id', residentId);

        debugPrint('✅ FCM token saved to database');
      } else {
        debugPrint('ℹ️ FCM token already exists and is up to date');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    try {
      final notificationType = data['notification_type'];
      final notificationId = data['notification_id'];

      if (notificationId != null) {
        // Mark notification as read
        _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notificationId);
      }

      // Navigate based on notification type
      if (navigatorKey.currentContext != null) {
        switch (notificationType) {
          case 'prevention_activity':
            GoRouter.of(navigatorKey.currentContext!).go('/barangay-updates');
            break;
          case 'announcement':
            GoRouter.of(navigatorKey.currentContext!).go('/announcements');
            break;
          default:
            // If no specific type, just go to notifications page
            GoRouter.of(navigatorKey.currentContext!).go('/notifications');
            break;
        }
      } else {
        debugPrint('❌ No context available for navigation');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification click: $e');
    }
  }
} 