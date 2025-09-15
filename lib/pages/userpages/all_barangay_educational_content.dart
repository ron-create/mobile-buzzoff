import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../actions/educational_content_actions.dart';
import 'educational_content_page.dart';
import '../../utils/responsive.dart';

class BarangayEducationalContentPage extends StatefulWidget {
  const BarangayEducationalContentPage({super.key});

  @override
  State<BarangayEducationalContentPage> createState() => _BarangayEducationalContentPageState();
}

class _BarangayEducationalContentPageState extends State<BarangayEducationalContentPage> {
  final EducationalContentAction _action = EducationalContentAction();
  List<Map<String, dynamic>> _educationalContent = [];
  bool _isLoading = true;
  String _selectedTimePeriod = 'All Time';

  final List<String> _timePeriods = [
    'All Time',
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final content = await _action.fetchBarangayEducationalContent(user.id);
        
        if (mounted) {
          setState(() {
            _educationalContent = _filterContentByTimePeriod(content);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to view content')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading content')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _filterContentByTimePeriod(List<Map<String, dynamic>> content) {
    if (_selectedTimePeriod == 'All Time') return content;

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedTimePeriod) {
      case 'Last 7 Days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case 'Last 3 Months':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      default:
        return content;
    }

    return content.where((item) {
      if (item['created_at'] == null) return false;
      final itemDate = DateTime.parse(item['created_at']);
      return itemDate.isAfter(cutoffDate);
    }).toList();
  }

  void _viewContentDetails(String contentId) async {
    // Record the view first
    await _action.recordContentView(contentId);
    
    // Then navigate to the detail page
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EducationalContentDetailPage(
            contentId: contentId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
        children: [
          // Back Button
          Padding(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
            ),
          ),
          // Time Period Filter (styled similar to Announcements)
          Padding(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.padding(context, 10)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF384949), Color(0xFF7A9CB6)],
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
                  child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: Responsive.icon(context, 20)),
                ),
                SizedBox(width: Responsive.padding(context, 16)),
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
                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimePeriod,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16), vertical: 12),
                          border: InputBorder.none,
                          hintText: 'Select time period',
                          hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                        style: const TextStyle(color: Color(0xFF384949), fontWeight: FontWeight.w600),
                        dropdownColor: Colors.white,
                        items: _timePeriods.map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedTimePeriod = value;
                            _loadContent();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List of cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _educationalContent.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: Responsive.icon(context, 48), color: Colors.grey.shade400),
                            SizedBox(height: Responsive.vertical(context, 16)),
                            Text(
                              'No educational content available',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey.shade600, fontSize: Responsive.font(context, 16)),
                            ),
                            SizedBox(height: Responsive.vertical(context, 8)),
                            Text(
                              'for the selected time period',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey.shade500, fontSize: Responsive.font(context, 14)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context, 16),
                          vertical: 0,
                        ),
                        itemCount: _educationalContent.length,
                        itemBuilder: (context, index) {
                          final item = _educationalContent[index];
                          return GestureDetector(
                            onTap: () => _viewContentDetails(item['id']),
                            child: Container(
                              margin: EdgeInsets.only(bottom: Responsive.vertical(context, 14)),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(Responsive.padding(context, 12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] ?? 'No title',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: Responsive.font(context, 15),
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.arrow_outward_rounded, size: Responsive.icon(context, 16), color: const Color(0xFF5271FF)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['content'] ?? 'No content available',
                                      style: TextStyle(
                                        fontSize: Responsive.font(context, 12),
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.arrow_outward_rounded, size: 14, color: Color(0xFF5271FF)),
                                        const SizedBox(width: 6),
                                        Text(
                                          item['created_at'] != null
                                              ? DateFormat('MMM d, y').format(DateTime.parse(item['created_at']))
                                              : 'No date',
                                          style: TextStyle(
                                            fontSize: Responsive.font(context, 11),
                                            color: const Color(0xFF5271FF),
                                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
} 