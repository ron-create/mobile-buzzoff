import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vehicle_request_modal.dart';
import 'dengue_case_profile_page.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: _getStatusColor(_vehicleRequest!['status']),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_vehicleRequest!['status']).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(_vehicleRequest!['status']).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _vehicleRequest!['status'],
                  style: TextStyle(
                    color: _getStatusColor(_vehicleRequest!['status']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Vehicle', '${_vehicleRequest!['vehicle']['name']} (${_vehicleRequest!['vehicle']['plate_no']})'),
          _buildDetailRow('Destination', _vehicleRequest!['destination']),
          _buildDetailRow('Reason', _vehicleRequest!['reason']),
          _buildDetailRow('Scheduled Time', _formatDateTime(_vehicleRequest!['scheduled_time'])),
          if (_vehicleRequest!['remarks'] != null && _vehicleRequest!['remarks'].isNotEmpty)
            _buildDetailRow('Remarks', _vehicleRequest!['remarks']),
        ],
      ),
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.reportType == 'dengue' ? 'Dengue Case Report' : 'Breeding Site Report',
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
                  color: _getStatusColor(widget.reportType == 'dengue' ? widget.report['report_status'] : widget.report['status']).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.reportType == 'dengue' ? widget.report['report_status'] : widget.report['status'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(widget.reportType == 'dengue' ? widget.report['report_status'] : widget.report['status']),
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
                _buildDetailRow('Location', widget.report['barangay_name']),
                _buildDetailRow('Description', widget.report['description']),
                _buildDetailRow('Report Date', _formatDate(widget.report['created_at'])),
                if (widget.report['image'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ClipRRect(
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
                  ),
              ],
            ],
          ),
        ),
        ),
      ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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