import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../utils/responsive.dart';
import '../components/dengue_case_profile_page.dart';
import 'package:flutter/services.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() => _isLoading = true);
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get user_id from users table
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userResponse == null) return;

      final userId = userResponse['id'];

      // Get resident_id
      final residentResponse = await Supabase.instance.client
          .from('resident')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) return;

      final residentId = residentResponse['id'];

      // Fetch notifications
      final notifications = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('resident_id', residentId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(notifications);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  void _handleNotificationClick(Map<String, dynamic> notification) async {
    final notificationType = (notification['type'] ?? notification['notification_type'] ?? '').toString().toLowerCase();
    final notificationId = notification['id'];
    final activityId = notification['activityId'];
    final title = (notification['title'] ?? '').toString().toLowerCase();

    debugPrint('🔵 Handling notification click:');
    debugPrint('🔵 Type: $notificationType');
    debugPrint('🔵 ActivityId: $activityId');
    debugPrint('🔵 Title: $title');

    // Mark as read first
    await _markAsRead(notificationId);

    if (!mounted) return;

    // Navigation logic based on type
    if (notificationType == 'prevention_activity' || title.contains('prevention activity')) {
      debugPrint('🔵 Navigating to Barangay Updates');
      context.push('/barangay-updates');
    } else if (notificationType == 'announcement' || title.contains('announcement')) {
      debugPrint('🔵 Navigating to Announcements');
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Get user_id from users table
          final userResponse = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('auth_id', user.id)
              .maybeSingle();
          if (userResponse != null) {
            final userId = userResponse['id'];
            // Get resident_id and barangay_id from resident table
            final residentResponse = await Supabase.instance.client
                .from('resident')
                .select('id, barangay_id')
                .eq('user_id', userId)
                .maybeSingle();
            if (residentResponse != null && residentResponse['barangay_id'] != null) {
              final barangayId = residentResponse['barangay_id'];
              debugPrint('🔵 Barangay ID: $barangayId');
              context.push('/announcements', extra: barangayId);
            } else {
              debugPrint('❌ No barangay ID found in resident table');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error getting barangay ID: $e');
      }
    } else if (notificationType == 'dengue_case' || title.contains('dengue case')) {
      debugPrint('🔵 Navigating to Dengue Case Profile Page');
      final dengueCaseId = notification['source_id'] ?? notification['dengue_case_id'] ?? notification['id'];
      if (dengueCaseId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DengueCaseProfilePage(dengueCaseId: dengueCaseId),
          ),
        );
      } else {
        debugPrint('❌ No dengue_case_id found in notification');
      }
    } else if (notificationType == 'breeding_site' || title.contains('breeding site') || notificationType == 'vehicle' || title.contains('vehicle')) {
      debugPrint('🔵 Navigating to Report Page');
      context.push('/report-page');
    } else {
      debugPrint('🔵 No navigation for this notification type');
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Color _getAnnouncementColor(String? type) {
    // Handle both FCM and database formats
    final announcementType = type?.toLowerCase();
    switch (announcementType) {
      case 'event':
        return Colors.blue;
      case 'general':
        return Colors.green;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAnnouncementTitle(Map<String, dynamic> notification) {
    // Prefer notification['title'] if available
    if (notification['title'] != null && notification['title'].toString().trim().isNotEmpty) {
      return notification['title'].toString();
    }
    // Fallbacks
    final type = notification['type'] ?? notification['notification_type'];
    final activityId = notification['activityId'];
    final title = notification['title']?.toString().toLowerCase() ?? '';
    if (type == 'prevention_activity' || activityId != null || title.contains('prevention activity')) {
      return 'Barangay Update';
    }
    if (type == 'announcement' || title.contains('announcement')) {
      return 'Announcement';
    }
    if (type == 'dengue_case' || title.contains('dengue case')) {
      return 'Dengue Case';
    }
    if (type == 'breeding_site' || title.contains('breeding site')) {
      return 'Breeding Site';
    }
    if (type == 'vehicle' || title.contains('vehicle')) {
      return 'Vehicle Request';
    }
    return 'Notification';
  }

  // Group notifications by time periods
  Map<String, List<Map<String, dynamic>>> _groupNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final recent = <Map<String, dynamic>>[];
    final earlier = <Map<String, dynamic>>[];
    final previous = <Map<String, dynamic>>[];

    for (final notification in _notifications) {
      try {
        final createdAt = DateTime.parse(notification['created_at']);
        final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

        if (notificationDate == today) {
          recent.add(notification);
        } else if (notificationDate == yesterday) {
          earlier.add(notification);
        } else if (notificationDate.isAfter(weekAgo)) {
          previous.add(notification);
        } else {
          previous.add(notification);
        }
      } catch (e) {
        // If date parsing fails, add to previous
        previous.add(notification);
      }
    }

    return {
      'recent': recent,
      'earlier': earlier,
      'previous': previous,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style in build method to ensure it's applied
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: Theme.of(context).colorScheme.primary,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey,
          ),
          SizedBox(height: Responsive.vertical(context, 16)),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey,
              fontSize: Responsive.font(context, 18),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: Responsive.vertical(context, 8)),
          Text(
            'You\'ll see notifications here when there are updates',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey,
              fontSize: Responsive.font(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final groupedNotifications = _groupNotifications();
    
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Responsive.padding(context, 16),
        Responsive.vertical(context, 16),
        Responsive.padding(context, 16),
        Responsive.vertical(context, 80),
      ),
      children: [
        _buildNotificationSection(
          'Recent',
          groupedNotifications['recent']!,
          'No recent notifications',
          Icons.schedule,
        ),
        if (groupedNotifications['earlier']!.isNotEmpty || groupedNotifications['previous']!.isNotEmpty)
          SizedBox(height: Responsive.vertical(context, 24)),
        _buildNotificationSection(
          'Earlier',
          groupedNotifications['earlier']!,
          'No earlier notifications',
          Icons.history,
        ),
        if (groupedNotifications['previous']!.isNotEmpty)
          SizedBox(height: Responsive.vertical(context, 24)),
        _buildNotificationSection(
          'Previous',
          groupedNotifications['previous']!,
          'No previous notifications',
          Icons.archive,
        ),
      ],
    );
  }

  Widget _buildNotificationSection(String title, List<Map<String, dynamic>> notifications, String emptyMessage, IconData emptyIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.font(context, 18),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
          ),
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        if (notifications.isEmpty)
          _buildEmptySection(emptyMessage, emptyIcon)
        else
          ...notifications.map((notification) => _buildNotificationCard(notification)),
      ],
    );
  }

  Widget _buildEmptySection(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFF5271FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5271FF),
              size: Responsive.icon(context, 20),
            ),
          ),
          SizedBox(width: Responsive.padding(context, 12)),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final announcementType = notification['announcementType'] ?? notification['announcement_type'];
    final announcementColor = _getAnnouncementColor(announcementType);

    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.vertical(context, 12)),
      child: GestureDetector(
        onTap: () => _handleNotificationClick(notification),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead 
                ? Theme.of(context).dividerColor.withOpacity(0.2)
                : announcementColor.withOpacity(0.3),
              width: isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: Responsive.icon(context, 40),
                  height: Responsive.icon(context, 40),
                  decoration: BoxDecoration(
                    color: announcementColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRead ? Icons.notifications_none : Icons.notifications,
                    color: announcementColor,
                    size: Responsive.icon(context, 24),
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getAnnouncementTitle(notification),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            _getTimeAgo(notification['created_at']),
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.vertical(context, 4)),
                      Text(
                        notification['body'] ?? notification['message'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 