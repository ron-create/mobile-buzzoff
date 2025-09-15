import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermission {
  static const String _permissionKey = 'notification_permission_asked';

  static Future<bool> hasBeenAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  static Future<void> markAsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, true);
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    await markAsAsked();
    return status.isGranted;
  }

  static Future<bool> isGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
} 