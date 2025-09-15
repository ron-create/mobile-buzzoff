import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class DengueCaseProfilePage extends StatefulWidget {
  final String dengueCaseId;

  const DengueCaseProfilePage({super.key, required this.dengueCaseId});

  @override
  State<DengueCaseProfilePage> createState() => _DengueCaseProfilePageState();
}

class _DengueCaseProfilePageState extends State<DengueCaseProfilePage> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCaseData();
  }

  Future<void> _fetchCaseData() async {
    try {
      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            *,
            resident:resident_id (
              first_name,
              last_name,
              sex,
              suffix_name,
              middle_name,
              address,
              date_of_birth
            ),
            handler:handled_by (
              first_name,
              last_name
            )
          ''')
          .eq('id', widget.dengueCaseId)
          .single();

      if (response != null) {
        final dengueCase = response;
        
        // Calculate age
        int? age;
        if (dengueCase['resident']?['date_of_birth'] != null) {
          final birthDate = DateTime.parse(dengueCase['resident']['date_of_birth']);
          final today = DateTime.now();
          age = today.year - birthDate.year;
          if (today.month < birthDate.month || 
              (today.month == birthDate.month && today.day < birthDate.day)) {
            age--;
          }
        }

        setState(() {
          _reportData = {
            ...dengueCase,
            'first_name': dengueCase['resident']?['first_name'],
            'last_name': dengueCase['resident']?['last_name'],
            'sex': dengueCase['resident']?['sex'],
            'suffix_name': dengueCase['resident']?['suffix_name'],
            'middle_name': dengueCase['resident']?['middle_name'],
            'address': dengueCase['resident']?['address'],
            'date_of_birth': dengueCase['resident']?['date_of_birth'],
            'age': age?.toString() ?? 'N/A',
            'handled_by_name': dengueCase['handler'] != null
                ? "${dengueCase['handler']['first_name']} ${dengueCase['handler']['last_name']}"
                : null,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Case not found";
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching case data: $error');
      setState(() {
        _error = "Failed to fetch case data";
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildDetailRow(String label, String? value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFF3A4A5A).withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A4A5A).withOpacity(0.8),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(color: const Color(0xFF3A4A5A).withOpacity(0.3), width: 1),
              ),
            ),
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF3A4A5A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Only build a detail row if the provided value is non-null and non-empty (for strings)
  Widget _buildDetailRowIfPresent(String label, dynamic value, BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    if (value is String && value.trim().isEmpty) return const SizedBox.shrink();
    return _buildDetailRow(label, value.toString(), context);
  }

  Widget _buildSection(String title, List<Widget> children, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A4A5A).withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3A4A5A).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A4A5A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getSectionIcon(title),
                    color: const Color(0xFF3A4A5A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A4A5A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Personal Information':
        return Icons.person;
      case 'Medical Information':
        return Icons.medical_services;
      case 'Laboratory Tests':
        return Icons.science;
      case 'Outcome':
        return Icons.assessment;
      case 'Additional Information':
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Case Profile',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             // Header with case status
                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: const Color(0xFF3A4A5A).withOpacity(0.1), width: 1),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.05),
                               blurRadius: 12,
                               offset: const Offset(0, 6),
                             ),
                           ],
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Container(
                                   padding: const EdgeInsets.all(8),
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF3A4A5A).withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: Icon(
                                     Icons.medical_services,
                                     color: const Color(0xFF3A4A5A),
                                     size: 20,
                                   ),
                                 ),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: Text(
                                     'Dengue Case Report',
                                     style: TextStyle(
                                       fontSize: 20,
                                       fontWeight: FontWeight.bold,
                                       color: const Color(0xFF3A4A5A),
                                       letterSpacing: 0.5,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 12),
                             Text(
                               'Case ID: ${widget.dengueCaseId}',
                               style: TextStyle(
                                 fontSize: 14,
                                 color: const Color(0xFF3A4A5A).withOpacity(0.7),
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 12),
                       // Status badge moved outside header
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(
                             color: _getStatusColor(_reportData!['case_status']).withOpacity(0.3),
                             width: 1,
                           ),
                         ),
                         child: Row(
                           children: [
                             Icon(
                               _getStatusIcon(_reportData!['case_status']),
                               color: _getStatusColor(_reportData!['case_status']),
                               size: 16,
                             ),
                             const SizedBox(width: 8),
                             Text(
                               'Status: ${_reportData!['case_status'] ?? 'Unknown'}',
                               style: TextStyle(
                                 color: _getStatusColor(_reportData!['case_status']),
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               ),
                             ),
                           ],
                         ),
                       ),
                      const SizedBox(height: 24),

                       // Personal Information Section
                      _buildSection('Personal Information', [
                        _buildDetailRowIfPresent('First Name', _reportData!['first_name'], context),
                        _buildDetailRowIfPresent('Middle Name', _reportData!['middle_name'], context),
                        _buildDetailRowIfPresent('Last Name', _reportData!['last_name'], context),
                        _buildDetailRowIfPresent('Suffix', _reportData!['suffix_name'], context),
                        _buildDetailRowIfPresent('Sex', _reportData!['sex'], context),
                        _buildDetailRow('Age', _reportData!['age'], context),
                        _buildDetailRowIfPresent('Address', _reportData!['address'], context),
                        _buildDetailRowIfPresent('Handled By', _reportData!['handled_by_name'], context),
                        _buildDetailRowIfPresent('Case Status', _reportData!['case_status'], context),
                      ], context),

                      // Medical Information Section
                      _buildSection('Medical Information', [
                        _buildDetailRow('Clinical Classification', _reportData!['clinical_classification'], context),
                        _buildDetailRow('Facility Name', _reportData!['facility_name'], context),
                        _buildDetailRow('Date of Consultation', _formatDate(_reportData!['date_consult']), context),
                        _buildDetailRow('Date of Onset of Illness', _formatDate(_reportData!['date_onset']), context),
                        _buildDetailRow('Is Admitted', _reportData!['is_admitted']?.toString() ?? 'N/A', context),
                        _buildDetailRow('Signs & Symptoms', _reportData!['signs_symptoms'], context),
                      ], context),

                      // Laboratory Tests Section
                      _buildSection('Laboratory Tests', [
                        _buildDetailRow('Laboratory Results', _reportData!['lab_result'], context),
                        _buildDetailRow('Diagnosis', _reportData!['diagnosis'], context),
                      ], context),

                      // Outcome Section
                      _buildSection('Outcome', [
                        _buildDetailRow('Outcome', _reportData!['outcome'], context),
                        _buildDetailRow('Date Died', _formatDate(_reportData!['date_died']), context),
                      ], context),

                      // Additional Information Section
                      _buildSection('Additional Information', [
                        _buildDetailRow('School/Workplace', _reportData!['school_workplace'], context),
                        _buildDetailRow('History of Travel', _reportData!['travel_history'], context),
                        _buildDetailRow('Search & Destroy', _reportData!['search_destroy'], context),
                      ], context),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle;
      case 'resolved':
        return Icons.task_alt;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
