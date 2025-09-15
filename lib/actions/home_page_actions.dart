import 'package:supabase_flutter/supabase_flutter.dart'; // Ensure this import is present
import 'package:flutter/material.dart';


class HomePageActions {
  // Static supabase client instance for global access
  static final supabase = Supabase.instance.client;

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
    final userProfile = userResponse['profile'];
    final userStatus = userResponse['status'];

    // Step 2: Fetch resident details using 'users_id'
    final response = await supabase
        .from('resident')
        .select('first_name, last_name, phone, barangay_id')
        .eq('user_id', userId) // Use users_id instead of auth_id
        .maybeSingle();

    if (response == null) {
      throw Exception('Resident details not found');
    }

    // Combine resident details with user profile
    response['profile'] = userProfile;
    response['status'] = userStatus;
    return response;
  } catch (e) {
    print('❌ Error fetching user details: $e');
    rethrow; // Propagate the error to be handled in the calling code
  }
}


  // Fetch barangay name by id
  static Future<String> fetchBarangayName(String barangayId) async {
    try {
      final response = await supabase
          .from('barangay')
          .select('name')
          .eq('id', barangayId)
          .single(); // Only one record expected

      // Return the barangay name or default value
      return response['name'] ?? 'N/A';
    } catch (e) {
      print('Error fetching barangay name: $e');
      rethrow; // Propagate the error to be handled in the calling code
    }
  }
// Logout the user
static Future<void> logout(BuildContext context) async {
  try {
    await supabase.auth.signOut();
  } catch (e) {
    print('Error logging out: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logout failed. Please try again.")),
    );
  }
}


  // Get current month (can be called publicly)
  static String getCurrentMonth() {
    final now = DateTime.now();
    final months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[now.month - 1]; // Returns the current month name
  }

  // Helper function to get card titles
  static String getCardTitle(int index) {
    switch (index) {
      case 0:
        return "Report";
      case 1:
        return "Map";
      case 2:
        return "Barangay Updates";
      case 3:
        return "Educational Content";
   
      default:
        return "";
    }
  }

  // Helper function to get icons for each card
  static IconData getIconForCard(int index) {
    switch (index) {
      case 0:
        return Icons.report; // Report icon
      case 1:
        return Icons.map; // Map icon
      case 2:
        return Icons.update; // Updates icon
      case 3:
        return Icons.school; // Educational content icon

      default:
        return Icons.help; // Default icon
    }
  }







}
