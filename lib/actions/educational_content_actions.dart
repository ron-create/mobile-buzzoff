import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EducationalContentAction {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _newsApiKey = 'c22dea4bd06b40a881f1cc2452280f6f';

  // Fetch educational content for user's barangay
  Future<List<Map<String, dynamic>>> fetchBarangayEducationalContent(String authUserId) async {
    try {
      // 1. Get internal user ID
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

      // 2. Get barangay_id from resident table
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

      // 3. Fetch educational content via join with barangay officials
      final contentResponse = await _supabase
          .from('educational_contents')
          .select('''
            *,
            barangay_officials!inner(
              barangay_id,
              first_name,
              last_name,
              users!inner(
                profile
              )
            )
          ''')
          .eq('barangay_officials.barangay_id', barangayId)
          .order('created_at', ascending: false);

      debugPrint('📦 Total Educational Content Fetched: ${contentResponse.length}');
      return List<Map<String, dynamic>>.from(contentResponse);
    } catch (e) {
      debugPrint('❗ Error fetching educational content: $e');
      return [];
    }
  }

  // Fetch all educational content
  Future<List<Map<String, dynamic>>> fetchAllEducationalContent() async {
    try {
      final response = await _supabase
          .from('educational_contents')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❗ Error fetching all educational content: $e');
      return [];
    }
  }

  // Fetch related news articles about dengue
  Future<List<Map<String, dynamic>>> fetchRelatedArticles() async {
    try {
      // Calculate date 1 month ago
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final formattedDate = oneMonthAgo.toIso8601String().split('T')[0];

      final response = await http.get(
        Uri.parse(
          'https://newsapi.org/v2/everything?' 'q=(dengue OR "dengue fever") AND (prevention OR "health tips" OR "mosquito control" OR "dengue vaccine" OR "dengue symptoms" OR "dengue treatment")&' +
          'from=$formattedDate&' +
          'language=en&' +
          'sortBy=publishedAt&' +
          'pageSize=10&' +
          'apiKey=c22dea4bd06b40a881f1cc2452280f6f'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = List<Map<String, dynamic>>.from(data['articles']);
        return articles;
      }
      return [];
    } catch (e) {
      debugPrint('❗ Error fetching related articles: $e');
      return [];
    }
  }

  // Fetch single educational content
  Future<Map<String, dynamic>?> fetchSingleEducationalContent(String contentId) async {
    try {
      final response = await _supabase
          .from('educational_contents')
          .select('*')
          .eq('id', contentId)
          .single();
      return response;
    } catch (e) {
      debugPrint('❗ Error fetching single educational content: $e');
      return null;
    }
  }

  // Record content view
  Future<bool> recordContentView(String contentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get internal user ID
      final userRecord = await _supabase
          .from('users')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userRecord == null) return false;

      // Check if content has already been viewed
      final existingViewResponse = await _supabase
          .from('content_views')
          .select()
          .eq('user_id', userRecord['id'])
          .eq('content_id', contentId)
          .eq('content_type', 'Educational')
          .maybeSingle();

      if (existingViewResponse != null) {
        return false;
      }

      // Record new view
      await _supabase.from('content_views').insert({
        'user_id': userRecord['id'],
        'content_id': contentId,
        'content_type': 'Educational',
        'viewed_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❗ Error recording content view: $e');
      return false;
    }
  }

  // Get single educational content
  Future<Map<String, dynamic>?> getEducationalContent(String contentId) async {
    try {
      final response = await _supabase
          .from('educational_contents')
          .select()
          .eq('id', contentId)
          .single();

      return response;
    } catch (e) {
      debugPrint('❗ Error fetching educational content: $e');
      return null;
    }
  }

  // Get unviewed content count
  Future<int> getUnviewedContentCount(String authUserId) async {
    try {
      // Get internal user ID
      final userRecord = await _supabase
          .from('users')
          .select('id')
          .eq('auth_id', authUserId)
          .maybeSingle();

      if (userRecord == null) return 0;

      // Get all educational content for user's barangay
      final content = await fetchBarangayEducationalContent(authUserId);
      if (content.isEmpty) return 0;

      // Get all viewed content IDs for this user
      final viewedContent = await _supabase
          .from('content_views')
          .select('content_id')
          .eq('user_id', userRecord['id'])
          .eq('content_type', 'Educational');

      final viewedIds = viewedContent.map((v) => v['content_id'] as String).toSet();
      
      // Count unviewed content
      return content.where((item) => !viewedIds.contains(item['id'])).length;
    } catch (e) {
      debugPrint('❗ Error getting unviewed content count: $e');
      return 0;
    }
  }

  // Fetch YouTube videos related to dengue prevention and health tips
  Future<List<Map<String, dynamic>>> fetchYoutubeVideos() async {
    const apiKey = 'AIzaSyDqcI6D73Zz6rCqQM-UYNnejPn1bRS1uV8';
    const query = 'dengue prevention health tips';
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = List<Map<String, dynamic>>.from(data['items']);
        return items;
      }
      return [];
    } catch (e) {
      debugPrint('❗ Error fetching YouTube videos: $e');
      return [];
    }
  }
}
