import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../actions/report_page_actions.dart';
import 'package:intl/intl.dart';
import '../components/history_page.dart';
import '../../utils/responsive.dart';
import '../components/report_selection_modal.dart';
import '../components/fading_line.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  String? residentId;
  String? userId;
  late Future<List<Map<String, dynamic>>> _yourDengueCasesFuture;
  late Future<List<Map<String, dynamic>>> _otherDengueCasesFuture;
  late Future<List<Map<String, dynamic>>> _breedingReportsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _initializePage();
  }

  void _initializePage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final userData = await ReportPageActions.getUserAndResidentId();
    residentId = userData['residentId'];
    userId = userData['userId'];

    if (residentId != null && userId != null) {
      setState(() {
        _yourDengueCasesFuture = ReportPageActions.fetchYourDengueCases(residentId!);
        _otherDengueCasesFuture = ReportPageActions.fetchOtherDengueCases(userId!);
        _breedingReportsFuture = ReportPageActions.fetchBreedingSiteReports(residentId!);
      });
    } else {
      debugPrint("Resident ID or User ID is null.");
    }
  }

  Future<void> _refreshReports() async {
    if (residentId != null && userId != null) {
      setState(() {
        _yourDengueCasesFuture = ReportPageActions.fetchYourDengueCases(residentId!);
        _otherDengueCasesFuture = ReportPageActions.fetchOtherDengueCases(userId!);
        _breedingReportsFuture = ReportPageActions.fetchBreedingSiteReports(residentId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Your Reports', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            tooltip: 'View History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 4.0,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Your Cases'),
            Tab(text: 'Other Cases You Reported'),
            Tab(text: 'Breeding Sites'),
          ],
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [

            Expanded(
                            child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + (Responsive.screenWidth(context) < 600 ? 8 : 24),
                      left: Responsive.screenWidth(context) < 600 ? 8 : 32,
                      right: Responsive.screenWidth(context) < 600 ? 8 : 32,
                      top: Responsive.screenWidth(context) < 600 ? 8 : 24,
                    ),
                    child: residentId == null
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildReportList(_yourDengueCasesFuture, isDengue: true, isYourCases: true),
                                    _buildReportList(_otherDengueCasesFuture, isDengue: true, isYourCases: false),
                                    _buildReportList(_breedingReportsFuture, isDengue: false, isYourCases: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FittedBox(
        fit: BoxFit.scaleDown,
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ReportSelectionModal(
                onSelectReportType: (String reportType) {
                  if (reportType == 'Dengue Case') {
                    context.push('/dengue-case');
                  } else if (reportType == 'Breeding Site') {
                    context.push('/breeding-site');
                  }
                },
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.add_circle_outline, size: 28),
          label: Text(
            'Create Report',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.screenWidth(context) < 600 ? 16 : 20,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          tooltip: 'Create a new report',
        ),
      ),
    );
  }

Widget _buildReportList(Future<List<Map<String, dynamic>>> futureReports, {required bool isDengue, required bool isYourCases}) {
  return RefreshIndicator(
    onRefresh: _refreshReports,
    child: FutureBuilder<List<Map<String, dynamic>>>( 
      future: futureReports,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reports available'));
        }
        final reports = snapshot.data!;
        
        // For "Other Cases" tab, filter out cases where you are the resident
        final filteredReports = isDengue && !isYourCases && residentId != null
            ? reports.where((report) => report['resident_id'] != residentId).toList()
            : reports;
            
        if (filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDengue ? Icons.medical_services : Icons.bug_report,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  isYourCases 
                    ? 'No ${isDengue ? 'dengue cases' : 'breeding site reports'} found'
                    : 'No other cases reported yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: filteredReports.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> report = filteredReports[index];
            final bool isDengueCase = isDengue;

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _getStatusColor(
                        isDengueCase ? report['report_status'] ?? 'Unknown' : report['status'] ?? 'Unknown'
                      ),
                      width: 6,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232E3F) : Colors.white,
                ),
                child: InkWell(
                  onTap: () {
                    String reportType = isDengueCase ? 'dengue' : 'breeding_site';
                    ReportPageActions.showReportDetailsModal(context, report, reportType);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDengueCase 
                                ? report['name'] ?? 'Unknown' 
                                : report['barangay_name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (isDengueCase && !isYourCases && report['reporter_relationship'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Relationship: ${report['reporter_relationship']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Text(
                              report['created_at'] != null
                                  ? DateFormat('EEEE, MMMM d, y').format(DateTime.parse(report['created_at']))
                                  : 'No date',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              isDengueCase ? report['report_status'] ?? 'Unknown' : report['status'] ?? 'Unknown'
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isDengueCase 
                              ? report['report_status'] ?? 'Unknown' 
                              : report['status'] ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(
                                isDengueCase ? report['report_status'] ?? 'Unknown' : report['status'] ?? 'Unknown'
                                ),
                              ),
                            ),
                          ),
                        ),
                          ],
                        ),
                        if (isDengueCase && report['vehicle_request'] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: report['vehicle_request']['status'] == 'Pending' 
                                ? Colors.orange.shade50 
                                : report['vehicle_request']['status'] == 'Approved'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: report['vehicle_request']['status'] == 'Pending'
                                  ? Colors.orange.shade200
                                  : report['vehicle_request']['status'] == 'Approved'
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  report['vehicle_request']['status'] == 'Pending'
                                    ? Icons.pending_actions
                                    : report['vehicle_request']['status'] == 'Approved'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: report['vehicle_request']['status'] == 'Pending'
                                    ? Colors.orange
                                    : report['vehicle_request']['status'] == 'Approved'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vehicle: ${report['vehicle_request']['status']}',
                                  style: TextStyle(
                                    color: report['vehicle_request']['status'] == 'Pending'
                                      ? Colors.orange.shade900
                                      : report['vehicle_request']['status'] == 'Approved'
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isDengueCase) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No vehicle requested',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

// Helper function to get status color
Color _getStatusColor(String status) {
  if (status.toLowerCase() == 'resolved') {
    return Colors.green;
  }
  return ReportPageActions.getStatusColor(status);
}

}
