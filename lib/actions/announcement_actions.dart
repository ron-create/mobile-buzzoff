import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AnnouncementActions {
  static final supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchAnnouncements({
    String? barangayId,
    int limit = 3,
    String? type,
  }) async {
    try {
      if (barangayId == null) {
        throw Exception('Barangay ID is required');
      }

      print('Debug - Fetching announcements for barangay: $barangayId');

      // First get matching officials and health center users
      final officialsResponse = await supabase
          .from('barangay_officials')
          .select('id, first_name, last_name')
          .eq('barangay_id', barangayId);

      print('Debug - Officials response: $officialsResponse');

      final healthCenterResponse = await supabase
          .from('health_center_users')
          .select('id, first_name, last_name')
          .eq('barangay_id', barangayId);

      print('Debug - Health center response: $healthCenterResponse');

      // Get their IDs
      final officialIds = officialsResponse.map((o) => o['id']).toList();
      final healthCenterIds = healthCenterResponse.map((h) => h['id']).toList();

      print('Debug - Official IDs: $officialIds');
      print('Debug - Health center IDs: $healthCenterIds');

      // Now fetch announcements using these IDs
      final response = await supabase
          .from('announcements')
          .select('*')
          .or('official_id.in.(${officialIds.join(',')}),health_center_id.in.(${healthCenterIds.join(',')})')
          .order('created_at', ascending: false)
          .order('type', ascending: false)
          .limit(limit > 0 ? limit : 1000);

      print('Debug - Query response: $response');

      return response.map((announcement) {
        // Find the matching official or health center user
        final official = officialsResponse.firstWhere(
          (o) => o['id'] == announcement['official_id'],
          orElse: () => <String, dynamic>{},
        );
        final healthCenter = healthCenterResponse.firstWhere(
          (h) => h['id'] == announcement['health_center_id'],
          orElse: () => <String, dynamic>{},
        );
        
        // Use the first available source
        final source = official.isNotEmpty ? official : healthCenter;

        return {
          ...announcement,
          'full_name': source.isNotEmpty
            ? '${source['first_name']} ${source['last_name']}'
            : 'Unknown',
          'formatted_date': _formatDate(announcement['created_at']),
        };
      }).toList();
    } catch (e) {
      print('Error fetching announcements: $e');
      rethrow;
    }
  }

  static String _formatDate(String dateStr) {
    // Parse the UTC date string
    final utcDate = DateTime.parse(dateStr);
    // Convert to Philippine time (UTC+8)
    final phDate = utcDate.add(const Duration(hours: 8));
    final now = DateTime.now();
    final difference = now.difference(phDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(phDate);
    }
  }
} 
