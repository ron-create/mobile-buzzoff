import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final supabase = Supabase.instance.client;

class ProfilePageAction {
  // Fetch user details from 'resident' table using 'users_id' from 'users'
  static Future<Map<String, dynamic>> fetchUserDetails(String authId) async {
    try {
      // Step 1: Get the user ID and profile from 'users' table using authId
      final userResponse = await supabase
          .from('users')
          .select('id, profile, status')
          .eq('auth_id', authId)
          .maybeSingle();

      if (userResponse == null || userResponse['id'] == null) {
        throw Exception('User not found');
      }

      final userId = userResponse['id'];
      final profilePicture = userResponse['profile'];
      final userStatus = userResponse['status'];

      // Step 2: Fetch resident details using 'user_id'
      final residentResponse = await supabase
          .from('resident')
          .select('first_name, last_name, phone, barangay_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) {
        throw Exception('Resident details not found');
      }

      // Combine user and resident data
      return {
        ...residentResponse,
        'profile_picture': profilePicture,
        'status': userStatus,
      };
    } catch (e) {
      print('❌ Error fetching user details: $e');
      rethrow; // Propagate the error to be handled in the calling code
    }
  }

  // Function to navigate to profile page
  static void navigateToProfile(BuildContext context) {
    context.push('/profile');
  }

  // Function to navigate to privacy policy page
  static void navigateToPrivacyPolicy(BuildContext context) {
    context.push('/privacy-policy');
  }

  // Function to navigate to settings page
  static void navigateToSettings(BuildContext context) {
    context.push('/settings');
  }

  // Function to navigate to help page
  static void navigateToHelp(BuildContext context) {
    context.push('/help');
  }

  // Function to handle logout
  static Future<void> logout(BuildContext context) async {
    await supabase.auth.signOut();
    context.go('/');
  }
}
