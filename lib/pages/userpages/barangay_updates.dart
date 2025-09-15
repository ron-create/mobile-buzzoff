import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../actions/barangay_updates_action.dart';
import '../components/update_details_modal.dart';
import 'package:intl/intl.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';

class BarangayUpdatesPage extends StatefulWidget {
  const BarangayUpdatesPage({super.key});

  @override
  _BarangayUpdatesPageState createState() => _BarangayUpdatesPageState();
}

class _BarangayUpdatesPageState extends State<BarangayUpdatesPage> {
  final BarangayUpdatesAction _updatesAction = BarangayUpdatesAction();
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No date';
    try {
      final date = DateTime.parse(dateStr);
      final formattedDate = DateFormat('MMMM d, y').format(date);
      final formattedTime = DateFormat('h:mm a').format(date);
      return '$formattedDate at $formattedTime';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatus(String? scheduleDateStr) {
    if (scheduleDateStr == null) return 'Unknown';
    
    try {
      final scheduleDate = DateTime.parse(scheduleDateStr);
      final now = DateTime.now();
      
      if (scheduleDate.isBefore(now)) {
        return 'Done';
      } else if (scheduleDate.difference(now).inDays <= 7) {
        return 'Upcoming';
      } else {
        return 'Scheduled';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'Upcoming':
        return Colors.orange;
      case 'Scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      setState(() => _isLoading = true);
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId != null) {
        final activities = await _updatesAction.fetchBarangayActivities(authUserId);
        if (mounted) {
          setState(() {
            _activities = activities;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recordActivityView(String activityId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _updatesAction.recordContentView(userId, activityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

              body: SafeArea(
          child: Column(
            children: [
              // Back Button and Title
              Padding(
                padding: EdgeInsets.only(
                  top: Responsive.vertical(context, 16),
                  left: Responsive.padding(context, 16),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updates',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.padding(context, 16),
                Responsive.vertical(context, 16),
                Responsive.padding(context, 16),
                Responsive.vertical(context, 8),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.padding(context, 12)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Stay updated on your barangay\'s activities and schedules. View upcoming and completed events below.',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 13),
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchActivities,
                      color: Theme.of(context).colorScheme.primary,
                      child: _activities.isEmpty
                          ? Center(
                              child: Text(
                                'No updates available',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey,
                                  fontSize: Responsive.font(context, 16),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                Responsive.padding(context, 16),
                                0,
                                Responsive.padding(context, 16),
                                Responsive.vertical(context, 80),
                              ),
                              itemCount: _activities.length,
                              itemBuilder: (context, index) {
                                final activity = _activities[index];
                                final status = _getStatus(activity['schedule_date']);
                                final statusColor = _getStatusColor(status);
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
                                  child: GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => UpdateDetailsModal(activity: activity),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(Responsive.padding(context, 16)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    activity['title'] ?? 'Untitled Activity',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: Responsive.font(context, 18),
                                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF384949),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: Responsive.padding(context, 12),
                                                    vertical: Responsive.vertical(context, 6),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: Responsive.font(context, 12),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: Responsive.vertical(context, 8)),
                                            Text(
                                              activity['description'] ?? 'No description',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF384949),
                                                fontSize: Responsive.font(context, 15),
                                              ),
                                            ),
                                            SizedBox(height: Responsive.vertical(context, 8)),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: Responsive.icon(context, 16), color: const Color(0xFF5271FF)),
                                                SizedBox(width: Responsive.padding(context, 8)),
                                                Text(
                                                  _formatDate(activity['schedule_date']),
                                                  style: TextStyle(
                                                    color: const Color(0xFF5271FF),
                                                    fontSize: Responsive.font(context, 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
