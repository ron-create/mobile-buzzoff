import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../actions/barangay_updates_action.dart';
import 'package:intl/intl.dart';

class UpdateDetailsModal extends StatefulWidget {
  final Map<String, dynamic> activity;

  const UpdateDetailsModal({super.key, required this.activity});

  @override
  _UpdateDetailsModalState createState() => _UpdateDetailsModalState();
}

class _UpdateDetailsModalState extends State<UpdateDetailsModal> {
  final BarangayUpdatesAction _updatesAction = BarangayUpdatesAction();
  bool _viewRecorded = false;
  DateTime? _modalOpenTime;

  @override
  void initState() {
    super.initState();
    _modalOpenTime = DateTime.now();
    _recordContentView();
  }

  Future<void> _recordContentView() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && !_viewRecorded) {
      final success = await _updatesAction.recordContentView(userId, widget.activity['id']);
      if (success) {
        setState(() {
          _viewRecorded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Check if modal was open for at least 30 seconds before recording view
    if (_modalOpenTime != null) {
      final duration = DateTime.now().difference(_modalOpenTime!);
      if (duration.inSeconds >= 30 && !_viewRecorded) {
        _recordContentView();
      }
    }
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Date not specified';
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
  Widget build(BuildContext context) {
    final status = _getStatus(widget.activity['schedule_date']);
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Title and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.activity['title'] ?? 'Untitled Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Color(0xFF384949),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Description
                Text(
                  widget.activity['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Color(0xFF384949),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: const Color(0xFF5271FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.activity['location'] ?? 'Location not specified',
                        style: TextStyle(
                          color: const Color(0xFF5271FF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: const Color(0xFF5271FF)),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(widget.activity['schedule_date']),
                      style: TextStyle(
                        color: const Color(0xFF5271FF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A89A7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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