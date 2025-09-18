import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vehicle_request_modal.dart';
import 'dengue_case_profile_page.dart';
import '../../actions/report_page_actions.dart';

class ReportDetailsModal extends StatefulWidget {
  final Map<String, dynamic> report;
  final String reportType; // 'dengue' or 'breeding_site'

  const ReportDetailsModal({super.key, required this.report, required this.reportType});

  @override
  State<ReportDetailsModal> createState() => _ReportDetailsModalState();
}

class _ReportDetailsModalState extends State<ReportDetailsModal> with TickerProviderStateMixin {
  Map<String, dynamic>? _vehicleRequest;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.reportType == 'dengue') {
      _loadVehicleRequest();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Start animation for breeding site reports
      _animationController.forward();
    }
  }

  Future<void> _loadVehicleRequest() async {
    try {
      final response = await Supabase.instance.client
          .from('vehicle_requests')
          .select('''
            *,
            vehicle:vehicle_id (
              id,
              name,
              plate_no,
              model
            )
          ''')
          .eq('dengue_case_id', widget.report['id'])
          .maybeSingle();

      setState(() {
        _vehicleRequest = response;
        _isLoading = false;
      });
      // Start animation after data is loaded
      _animationController.forward();
    } catch (error) {
      debugPrint('Error loading vehicle request: $error');
      setState(() {
        _isLoading = false;
      });
      // Start animation even if there's an error
      _animationController.forward();
    }
  }

  Future<void> _showVehicleRequestModal() async {
    final result = await showDialog(
      context: context,
      builder: (context) => VehicleRequestModal(
        dengueCaseId: widget.report['id'],
        residentId: widget.report['resident_id'],
      ),
    );

    if (result != null) {
      await _loadVehicleRequest();
    }
  }

  Widget _buildVehicleRequestSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicleRequest == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vehicle Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF384949),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No vehicle request has been made for this case.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildVehicleRequestTicket();
  }

  Widget _buildVehicleRequestTicket() {
    final status = _vehicleRequest!['status']?.toString().toLowerCase() ?? 'pending';
    
    return Column(
      children: [
        // Thank you message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Thank you for requesting a vehicle. Our team will coordinate with you for pickup.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Timeline content
        Column(
          children: [
            // Pending section (always shown)
            _buildTimelineSection(
              icon: Icons.schedule,
              iconColor: status == 'pending' ? ReportPageActions.getStatusColor('pending') : Colors.grey,
              title: 'Requested',
              content: _formatDateTime(_vehicleRequest!['scheduled_time']),
              subtitle: 'You have requested a vehicle',
              isActive: status == 'pending',
            ),
            _buildTicketDivider(),
            
            // Approved/Declined section (always shown)
            _buildTimelineSection(
              icon: status == 'approved' ? Icons.check_circle : status == 'declined' ? Icons.cancel : Icons.hourglass_empty,
              iconColor: status == 'approved' ? ReportPageActions.getStatusColor('approved') : 
                         status == 'declined' ? ReportPageActions.getStatusColor('declined') : Colors.grey,
              title: status == 'approved' ? 'Approved' : status == 'declined' ? 'Declined' : 'Under Review',
              content: '',
              subtitle: status == 'approved' ? 'Your request has been approved. We will call you before picking you up.' :
                       status == 'declined' ? 'Unfortunately, your request has been declined.' :
                       'Your request is under review',
              isActive: status == 'approved' || status == 'declined',
            ),
            _buildTicketDivider(),
            
            // Completed section (always shown)
            _buildTimelineSection(
              icon: Icons.done_all,
              iconColor: status == 'completed' ? ReportPageActions.getStatusColor('completed') : Colors.grey,
              title: 'Completed',
              content: status == 'completed' ? _formatDate(_vehicleRequest!['updated_at']) : '',
              subtitle: status == 'completed' ? 'Your vehicle request has been completed. Thank you!' : 'Your request will be completed soon',
              isActive: status == 'completed',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Vehicle details section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Vehicle', '${_vehicleRequest!['vehicle']['name']} (${_vehicleRequest!['vehicle']['plate_no']})'),
              _buildDetailRow('Destination', _vehicleRequest!['destination']),
              _buildDetailRow('Reason', _vehicleRequest!['reason']),
              _buildDetailRow('Scheduled Time', _formatDateTime(_vehicleRequest!['scheduled_time'])),
              if (_vehicleRequest!['remarks'] != null && _vehicleRequest!['remarks'].isNotEmpty)
                _buildDetailRow('Remarks', _vehicleRequest!['remarks']),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Not scheduled';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, y - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _isLoading 
                  ? Container(
                      height: 200,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading report details...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : child,
              ),
            );
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.reportType == 'dengue' ? 'Dengue Case Report' : 'Reported Breeding Site',
                            textAlign: widget.reportType == 'breeding_site' ? TextAlign.center : TextAlign.start,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    if (widget.reportType == 'dengue') ...[
                      const SizedBox(height: 12),
                      widget.report['handled_by_name'] != null
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DengueCaseProfilePage(
                                        dengueCaseId: widget.report['id'],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person, size: 18),
                                label: const Text('View Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5271FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.person_outline, size: 18),
                                label: const Text("This case hasn't been handled yet"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.grey.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ReportPageActions.getStatusColor(widget.reportType == 'dengue' ? widget.report['report_status'] : widget.report['status']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.reportType == 'dengue' ? widget.report['report_status'] : widget.report['status'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ReportPageActions.getStatusColor(widget.reportType == 'dengue' ? widget.report['report_status'] : widget.report['status']),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Conditional rendering for Dengue Case
                if (widget.reportType == 'dengue') ...[
                  _buildDetailRow('Patient Name', widget.report['name']),
                  if (widget.report['handled_by_name'] != null)
                    _buildDetailRow('Handled By', widget.report['handled_by_name']),
                  if (widget.report['closed_by_name'] != null)
                    _buildDetailRow('Closed By', widget.report['closed_by_name']),
                  _buildDetailRow('Report Date', _formatDate(widget.report['created_at'])),
                  const SizedBox(height: 16),
                  _buildVehicleRequestSection(),
                ],

                // Conditional rendering for Breeding Site
                if (widget.reportType == 'breeding_site') ...[
                  _buildBreedingSiteTicket(),
                ],
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No date';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, y').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }


  Widget _buildBreedingSiteTicket() {
    final status = widget.report['status']?.toString().toLowerCase() ?? 'reported';
    
    return Column(
      children: [
        // Thank you message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Thank you for reporting breeding site. Our team may call you for more information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Timeline content
        Column(
          children: [
            // Reported section (always shown)
            _buildTimelineSection(
              icon: Icons.report_problem,
              iconColor: status == 'reported' ? ReportPageActions.getStatusColor('reported') : Colors.grey,
              title: 'Reported',
              content: _formatDate(widget.report['created_at']),
              subtitle: 'You have reported a breeding site',
              isActive: status == 'reported',
            ),
            _buildTicketDivider(),
            
            // In Progress section (always shown)
            _buildTimelineSection(
              icon: Icons.hourglass_empty,
              iconColor: status == 'in-progress' ? ReportPageActions.getStatusColor('in-progress') : Colors.grey,
              title: 'In Progress',
              content: '',
              subtitle: 'Your reported breeding site is in progress',
              isActive: status == 'in-progress',
            ),
            _buildTicketDivider(),
            
            // Resolved section (always shown)
            _buildTimelineSection(
              icon: Icons.check_circle,
              iconColor: status == 'resolved' ? ReportPageActions.getStatusColor('resolved') : Colors.grey,
              title: 'Resolved',
              content: status == 'resolved' ? _formatDate(widget.report['updated_at']) : '',
              subtitle: status == 'resolved' ? 'Your reported breeding site has been resolved. Thank you for your cooperation!' : 'Your report will be resolved soon',
              isActive: status == 'resolved',
            ),
          ],
        ),
        
        // Image section if available
        if (widget.report['image'] != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.report['image'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Failed to load image'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required String subtitle,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isActive ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20),
            border: isActive ? Border.all(color: iconColor, width: 2) : null,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                ),
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 2,
            height: 30,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'Not specified',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}