import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../actions/announcement_actions.dart';
import '../components/announcement_modal.dart';
import '../../actions/home_page_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/responsive.dart';

class AnnouncementsPage extends StatefulWidget {
  final String barangayId;
  
  const AnnouncementsPage({
    super.key,
    required this.barangayId,
  });

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;
  String selectedType = 'All';

  final List<String> types = ['All', 'Emergency', 'Event', 'General'];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      setState(() => isLoading = true);
      final fetchedAnnouncements = await AnnouncementActions.fetchAnnouncements(
        barangayId: widget.barangayId,
        limit: 0,
      );

      // Filter by type
      final filteredAnnouncements = fetchedAnnouncements.where((announcement) {
        if (selectedType == 'All') return true;
        return announcement['type'].toLowerCase() == selectedType.toLowerCase();
      }).toList();

      // Sort announcements by date (newest first)
      filteredAnnouncements.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        announcements = filteredAnnouncements;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching announcements: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load announcements')),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return const Color(0xFFFF6B6B);
      case 'event':
        return const Color(0xFF7A9CB6);
      case 'general':
      default:
        return const Color(0xFF384949);
    }
  }

  void _showAnnouncementModal(Map<String, dynamic> announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnnouncementModal(
        title: announcement['title'],
        body: announcement['body'],
        fullName: announcement['full_name'],
        type: announcement['type'],
        file: announcement['file'],
      ),
    );
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
        title: Text(
          'Barangay Announcements',
          style: TextStyle(
            color: const Color(0xFF384949),
            fontWeight: FontWeight.bold,
            fontSize: Responsive.font(context, 20),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF384949)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          // Professional Filter Section
          Padding(
            padding: EdgeInsets.all(Responsive.padding(context, 20)),
            child: Row(
              children: [
                // Filter Icon
                Container(
                  padding: EdgeInsets.all(Responsive.padding(context, 10)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF384949),
                        const Color(0xFF7A9CB6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF384949).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: Colors.white,
                    size: Responsive.icon(context, 20),
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 16)),
                // Filter Dropdown
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
                          border: InputBorder.none,
                          hintText: 'Filter by type',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: Responsive.font(context, 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        items: types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: type == 'All' 
                                        ? const Color(0xFF384949)
                                        : _getTypeColor(type),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: Responsive.padding(context, 8)),
                                Text(
                                  type,
                                  style: TextStyle(
                                    color: const Color(0xFF384949),
                                    fontWeight: FontWeight.w500,
                                    fontSize: Responsive.font(context, 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                            _fetchAnnouncements();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Announcements List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF384949),
                    ),
                  )
                : announcements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.announcement_outlined,
                              size: Responsive.icon(context, 64),
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey[400],
                            ),
                            SizedBox(height: Responsive.vertical(context, 16)),
                            Text(
                              'No announcements found',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey[600],
                                fontSize: Responsive.font(context, 16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          Responsive.padding(context, 16),
                          0,
                          Responsive.padding(context, 16),
                          Responsive.vertical(context, 80),
                        ),
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: _getTypeColor(announcement['type']).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _showAnnouncementModal(announcement),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.all(Responsive.padding(context, 20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with type and date
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Responsive.padding(context, 12),
                                            vertical: Responsive.vertical(context, 6),
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                _getTypeColor(announcement['type']),
                                                _getTypeColor(announcement['type']).withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getTypeColor(announcement['type']).withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            announcement['type'].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: Responsive.font(context, 12),
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Responsive.padding(context, 10),
                                            vertical: Responsive.vertical(context, 6),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Text(
                                            announcement['formatted_date'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: Responsive.font(context, 12),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: Responsive.vertical(context, 16)),
                                    
                                    // Title
                                    Text(
                                      announcement['title'],
                                      style: TextStyle(
                                        color: const Color(0xFF384949),
                                        fontWeight: FontWeight.bold,
                                        fontSize: Responsive.font(context, 18),
                                        height: 1.3,
                                      ),
                                    ),
                                    
                                    SizedBox(height: Responsive.vertical(context, 12)),
                                    
                                    // Body with see more
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          announcement['body'],
                                          style: TextStyle(
                                            color: const Color(0xFF384949).withOpacity(0.8),
                                            fontSize: Responsive.font(context, 15),
                                            height: 1.5,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (announcement['body'].length > 150)
                                          Padding(
                                            padding: EdgeInsets.only(top: Responsive.vertical(context, 8)),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'See more',
                                                  style: TextStyle(
                                                    color: _getTypeColor(announcement['type']),
                                                    fontSize: Responsive.font(context, 14),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: Responsive.padding(context, 8)),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: _getTypeColor(announcement['type']),
                                                  size: Responsive.icon(context, 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: Responsive.vertical(context, 12)),
                                    
                                    // Author info
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(Responsive.padding(context, 6)),
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(announcement['type']).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: Responsive.icon(context, 16),
                                            color: _getTypeColor(announcement['type']),
                                          ),
                                        ),
                                        SizedBox(width: Responsive.padding(context, 8)),
                                        Text(
                                          announcement['full_name'],
                                          style: TextStyle(
                                            color: const Color(0xFF384949).withOpacity(0.7),
                                            fontSize: Responsive.font(context, 13),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 