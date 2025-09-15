import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class BarangayUpdatesAction {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch prevention activities for the user's barangay
  Future<List<Map<String, dynamic>>> fetchBarangayActivities(String authUserId) async {
    try {
      // 1. Get internal user ID from your 'users' table
      final userRecord = await _supabase
          .from('users')
          .select('id')
          .eq('auth_id', authUserId)
          .maybeSingle();

      if (userRecord == null) {
        debugPrint('❌ No user found matching auth ID: $authUserId');
        return [];
      }

      final userId = userRecord['id'];

      // 2. Get barangay_id from 'resident' table using internal user ID
      final residentRecord = await _supabase
          .from('resident')
          .select('barangay_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentRecord == null) {
        debugPrint('❌ No resident record for user ID: $userId');
        return [];
      }

      final barangayId = residentRecord['barangay_id'];
      debugPrint('✅ User Barangay ID: $barangayId');

      // 3. Fetch prevention activities via join to barangay_officials with matching barangay_id
      final activitiesResponse = await _supabase
          .from('prevention_activities')
          .select('*, barangay_officials!inner(barangay_id)')
          .eq('barangay_officials.barangay_id', barangayId)
          .order('schedule_date', ascending: false);

      debugPrint('📦 Total Activities Fetched: ${activitiesResponse.length}');

      return List<Map<String, dynamic>>.from(activitiesResponse);
    } catch (e) {
      debugPrint('❗ Error fetching barangay activities: $e');
      return [];
    }
  }

  // Record content view for an activity
  Future<bool> recordContentView(String userId, String activityId) async {
    try {
      // Check if the content has already been viewed
      final existingViewResponse = await _supabase
          .from('content_views')
          .select()
          .eq('user_id', userId)
          .eq('content_id', activityId)
          .eq('content_type', 'Activity')
          .single()
          .then((_) => true)
          .catchError((_) => false);

      // If already viewed, return false
      if (existingViewResponse) {
        return false;
      }

      // Record the new view
      await _supabase.from('content_views').insert({
        'user_id': userId,
        'content_id': activityId,
        'content_type': 'Activity',
        'viewed_at': DateTime.now().toIso8601String()
      });

      return true;
    } catch (e) {
      debugPrint('Error recording content view: $e');
      return false;
    }
  }
}
