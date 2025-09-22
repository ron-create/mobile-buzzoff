import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../actions/report_page_actions.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  String? residentId;
  String? userId;
  late Future<List<Map<String, dynamic>>> _yourDengueHistoryFuture;
  late Future<List<Map<String, dynamic>>> _otherDengueHistoryFuture;
  late Future<List<Map<String, dynamic>>> _breedingHistoryFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializePage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final userData = await ReportPageActions.getUserAndResidentId();
    residentId = userData['residentId'];
    userId = userData['userId'];

    if (residentId != null && userId != null) {
      setState(() {
        _yourDengueHistoryFuture = ReportPageActions.fetchYourDengueHistory(residentId!);
        _otherDengueHistoryFuture = ReportPageActions.fetchOtherDengueHistory(userId!, residentId: residentId!);
        _breedingHistoryFuture = ReportPageActions.fetchBreedingSiteHistory(residentId!);
      });
    }
  }

  Future<void> _refreshHistory() async {
    if (residentId != null && userId != null) {
      setState(() {
        _yourDengueHistoryFuture = ReportPageActions.fetchYourDengueHistory(residentId!);
        _otherDengueHistoryFuture = ReportPageActions.fetchOtherDengueHistory(userId!, residentId: residentId!);
        _breedingHistoryFuture = ReportPageActions.fetchBreedingSiteHistory(residentId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Report History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
        child: Column(
          children: [

            Expanded(
              child: residentId == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHistoryList(_yourDengueHistoryFuture, true, true),
                        _buildHistoryList(_otherDengueHistoryFuture, true, false),
                        _buildHistoryList(_breedingHistoryFuture, false, true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(Future<List<Map<String, dynamic>>> futureReports, bool isDengue, bool isYourCases) {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDengue ? Icons.medical_services_outlined : Icons.location_on_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isYourCases 
                      ? 'No ${isDengue ? 'dengue case' : 'breeding site'} history available'
                      : 'No other cases history available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> report = snapshot.data![index];
              
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
                        color: Colors.green,
                        width: 6,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: InkWell(
                    onTap: () {
                      String reportType = isDengue ? 'dengue' : 'breeding_site';
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
                                      isDengue 
                                        ? report['name'] ?? 'Unknown' 
                                        : report['barangay_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (isDengue && !isYourCases && report['reporter_relationship'] != null) ...[
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
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isDengue ? 'Closed' : 'Resolved',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report['created_at'] != null
                                ? DateFormat('EEEE, MMMM d, y - hh:mm a').format(DateTime.parse(report['created_at']))
                                : 'No date',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          if (isDengue && report['handled_by_name'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Handled by: ${report['handled_by_name']}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                          if (isDengue && report['closed_by_name'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Closed by: ${report['closed_by_name']}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
} 