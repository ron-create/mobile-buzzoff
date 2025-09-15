import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class LoginPageActions {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      debugPrint('🔵 Starting login process for email: $email');
      
      // Step 1: Find the user in users table using email
      debugPrint('🔵 Step 1: Finding user in users table...');
      final userResponse = await supabase
          .from('users')
          .select('*')
          .eq('email', email.trim()) // Find by email
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ User not found in users table');
        return {"error": "User not found."};
      }
      debugPrint('✅ User found in users table. User ID: ${userResponse['id']}');

      // Check user status
      final userStatus = userResponse['status']?.toString().toLowerCase();
      debugPrint('🔵 User status: $userStatus');
      
      if (userStatus == 'pending') {
        debugPrint('❌ User status is pending');
        return {
          "error": "status_error",
          "status": userStatus,
          "message": _getStatusMessage(userStatus)
        };
      }
      if (userStatus == 'deleted') {
        debugPrint('❌ User status is deleted');
        return {
          "error": "status_error",
          "status": userStatus,
          "message": _getStatusMessage(userStatus)
        };
      }
      // If deactivated, allow login but update status to active after password check
      bool wasDeactivated = false;
      if (userStatus == 'deactivated') {
        wasDeactivated = true;
      }

      final userId = userResponse['id']; // Get user_id (NOT auth_id)

      // Step 2: Login using Supabase Auth
      debugPrint('🔵 Step 2: Attempting Supabase Auth login...');
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user == null) {
        debugPrint('❌ Supabase Auth login failed');
        return {"error": "Invalid email or password."};
      }
      debugPrint('✅ Supabase Auth login successful. Auth ID: ${response.user?.id}');

      // If was deactivated, update status to active
      if (wasDeactivated) {
        debugPrint('🔵 Updating user status from deactivated to active...');
        await supabase.from('users').update({'status': 'Active'}).eq('id', userId);
        debugPrint('✅ User status updated to active.');
      }

      // Step 3: Fetch resident details using user_id
      debugPrint('🔵 Step 3: Fetching resident details...');
      final residentResponse = await supabase
          .from('resident')
          .select('*')
          .eq('user_id', userId) // Use user_id (not auth_id)
          .maybeSingle();

      if (residentResponse == null) {
        debugPrint('❌ Resident details not found');
        return {"error": "Resident details not found."};
      }
      debugPrint('✅ Resident details found. Resident ID: ${residentResponse['id']}');

      // Check if profile setup is complete
      final firstName = residentResponse['first_name'];
      final lastName = residentResponse['last_name'];
      
      debugPrint('🔵 Profile completion check:');
      debugPrint('   - first_name: $firstName');
      debugPrint('   - last_name: $lastName');
      
      if (firstName == null || lastName == null) {
        debugPrint('⚠️ Profile setup incomplete - first_name or last_name is null');
        debugPrint('   → Redirecting to setup account page');
        return {
          "success": true,
          "profile_incomplete": true,
          "user": userResponse,
          "resident": residentResponse,
        };
      }
      debugPrint('✅ Profile setup is complete');
      debugPrint('   → Redirecting to login success page');

      // Step 4: Get and save FCM token
      debugPrint('🔵 Step 4: Getting FCM token...');
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔵 FCM Token: $fcmToken');

      if (fcmToken != null) {
        debugPrint('🔵 Saving FCM token to resident table...');
        try {
          await supabase
              .from('resident')
              .update({'fcm_token': fcmToken})
              .eq('id', residentResponse['id']);
          debugPrint('✅ FCM token saved successfully');
        } catch (e) {
          debugPrint('❌ Error saving FCM token: $e');
        }
      } else {
        debugPrint('⚠️ No FCM token available to save');
      }

      debugPrint('✅ Login process completed successfully');
      return {
        "success": true,
        "profile_incomplete": false,
        "user": userResponse, // Users table data
        "resident": residentResponse, // Resident details
      };
    } catch (error) {
      debugPrint('❌ Error during login process: $error');
      return {"error": "Error: $error"};
    }
  }

  String _getStatusMessage(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Your account is currently pending approval. Please wait for your barangay to accept your registration.';
      case 'deleted':
        return 'Your account has been deleted. Please contact the City Health Office for account restoration.';
      case 'deactivated':
        return 'Your account has been deactivated. Please contact the City Health Office for reactivation.';
      default:
        return 'Your account status is not active. Please contact support for assistance.';
    }
  }
}
