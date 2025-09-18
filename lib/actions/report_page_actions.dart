import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/components/report_selection_modal.dart';
import '../pages/components/report_details_modal.dart';

class ReportPageActions {
  // Function to show the report selection modal
  static void showReportSelectionModal(BuildContext context, Function(String) onSelectReportType) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ReportSelectionModal(onSelectReportType: onSelectReportType);
      },
    );
  }

  // Get both user ID and resident ID
  static Future<Map<String, String?>> getUserAndResidentId() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        debugPrint('No authenticated user.');
        return {'userId': null, 'residentId': null};
      }

      final authId = authUser.id;

      // Get user ID from users table
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('User not found for auth_id: $authId');
        return {'userId': null, 'residentId': null};
      }

      final userId = userResponse['id'];

      // Get resident ID from resident table
      final residentResponse = await Supabase.instance.client
          .from('resident')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) {
        debugPrint('Resident not found for user_id: $userId');
        return {'userId': userId, 'residentId': null};
      }

      return {
        'userId': userId,
        'residentId': residentResponse['id'] as String,
      };
    } catch (error) {
      debugPrint('Error fetching user and resident IDs: $error');
      return {'userId': null, 'residentId': null};
    }
  }

  // Function to fetch the resident ID using user ID (legacy method)
  static Future<String?> getResidentId() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        debugPrint('No authenticated user.');
        return null;
      }

      final authId = authUser.id;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('User not found for auth_id: $authId');
        return null;
      }

      final userId = userResponse['id'];

      final residentResponse = await Supabase.instance.client
          .from('resident')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) {
        debugPrint('Resident not found for user_id: $userId');
        return null;
      }

      return residentResponse['id'] as String;
    } catch (error) {
      debugPrint('Error fetching resident ID: $error');
      return null;
    }
  }

  // Fetch your own dengue cases (where resident_id = your resident_id)
  static Future<List<Map<String, dynamic>>> fetchYourDengueCases(String residentId) async {
    try {
      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            id,
            resident_id,
            reporter_id,
            reporter_relationship,
            handled_by,
            closed_by,
            case_status,
            created_at,
            resident:resident_id(id, first_name, last_name),
            handler:health_center_users!handled_by(id, first_name, last_name),
            closer:health_center_users!closed_by(id, first_name, last_name),
            vehicle_requests!dengue_case_id(
              id,
              status,
              created_at
            )
          ''')
          .eq('resident_id', residentId)
          .filter('closed_by', 'is', null) // Only active cases (not closed)
          .order('created_at', ascending: false);

      debugPrint('Fetching your dengue cases for resident_id: $residentId');
      debugPrint('Response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<Map<String, dynamic>>((report) {
        final vehicleRequests = report['vehicle_requests'] as List?;
        final latestVehicleRequest = vehicleRequests?.isNotEmpty == true 
            ? vehicleRequests!.reduce((a, b) => 
                DateTime.parse(a['created_at']).isAfter(DateTime.parse(b['created_at'])) ? a : b)
            : null;

        return {
          'id': report['id'],
          'resident_id': report['resident_id'],
          'name': report['resident'] != null 
              ? "${report['resident']['first_name']} ${report['resident']['last_name']}"
              : 'Unknown',
          'report_status': report['case_status'],
          'created_at': report['created_at'],
          'reporter_relationship': report['reporter_relationship'],
          'handled_by_name': report['handler'] != null 
              ? "${report['handler']['first_name']} ${report['handler']['last_name']}"
              : null,
          'closed_by_name': report['closer'] != null
              ? "${report['closer']['first_name']} ${report['closer']['last_name']}"
              : null,
          'vehicle_request': latestVehicleRequest,
        };
      }).toList();
    } catch (error) {
      debugPrint('Error fetching your dengue cases: $error');
      return [];
    }
  }

  // Fetch other dengue cases you reported (where reporter_id = your user_id)
  static Future<List<Map<String, dynamic>>> fetchOtherDengueCases(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            id,
            resident_id,
            reporter_id,
            reporter_relationship,
            handled_by,
            closed_by,
            case_status,
            created_at,
            resident:resident_id(id, first_name, last_name),
            handler:health_center_users!handled_by(id, first_name, last_name),
            closer:health_center_users!closed_by(id, first_name, last_name),
            vehicle_requests!dengue_case_id(
              id,
              status,
              created_at
            )
          ''')
          .eq('reporter_id', userId)
          .filter('closed_by', 'is', null) // Only active cases (not closed)
          .order('created_at', ascending: false);

      debugPrint('Fetching other dengue cases for reporter_id: $userId');
      debugPrint('Response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<Map<String, dynamic>>((report) {
        final vehicleRequests = report['vehicle_requests'] as List?;
        final latestVehicleRequest = vehicleRequests?.isNotEmpty == true 
            ? vehicleRequests!.reduce((a, b) => 
                DateTime.parse(a['created_at']).isAfter(DateTime.parse(b['created_at'])) ? a : b)
            : null;

        return {
          'id': report['id'],
          'resident_id': report['resident_id'],
          'name': report['resident'] != null 
              ? "${report['resident']['first_name']} ${report['resident']['last_name']}"
              : 'Unknown',
          'report_status': report['case_status'],
          'created_at': report['created_at'],
          'reporter_relationship': report['reporter_relationship'],
          'handled_by_name': report['handler'] != null 
              ? "${report['handler']['first_name']} ${report['handler']['last_name']}"
              : null,
          'closed_by_name': report['closer'] != null
              ? "${report['closer']['first_name']} ${report['closer']['last_name']}"
              : null,
          'vehicle_request': latestVehicleRequest,
        };
      }).toList();
    } catch (error) {
      debugPrint('Error fetching other dengue cases: $error');
      return [];
    }
  }

  // Legacy method for backward compatibility
  static Future<List<Map<String, dynamic>>> fetchDengueReports(String residentId) async {
    try {
      final residentResponse = await Supabase.instance.client
          .from('resident')
          .select('barangay_id')
          .eq('id', residentId)
          .single();

      final barangayId = residentResponse['barangay_id'];

      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            id,
            resident_id,
            handled_by,
            closed_by,
            case_status,
            created_at,
            resident:resident_id(id, first_name, last_name),
            handler:health_center_users!handled_by(id, first_name, last_name),
            closer:health_center_users!closed_by(id, first_name, last_name),
            vehicle_requests!dengue_case_id(
              id,
              status,
              created_at
            )
          ''')
          .eq('resident_id', residentId)
          .filter('closed_by', 'is', null)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final vehiclesResponse = await Supabase.instance.client
          .from('vehicles')
          .select('id, plate_no, status')
          .eq('barangay_id', barangayId)
          .eq('status', 'Available');

      final availableVehicles = vehiclesResponse as List;

      return response.map<Map<String, dynamic>>((report) {
        final vehicleRequests = report['vehicle_requests'] as List?;
        final latestVehicleRequest = vehicleRequests?.isNotEmpty == true 
            ? vehicleRequests!.reduce((a, b) => 
                DateTime.parse(a['created_at']).isAfter(DateTime.parse(b['created_at'])) ? a : b)
            : null;

        return {
          'id': report['id'],
          'resident_id': report['resident_id'],
          'name': report['resident'] != null 
              ? "${report['resident']['first_name']} ${report['resident']['last_name']}"
              : 'Unknown',
          'report_status': report['case_status'],
          'created_at': report['created_at'],
          'handled_by_name': report['handler'] != null 
              ? "${report['handler']['first_name']} ${report['handler']['last_name']}"
              : null,
          'closed_by_name': report['closer'] != null
              ? "${report['closer']['first_name']} ${report['closer']['last_name']}"
              : null,
          'vehicle_request': latestVehicleRequest,
          'available_vehicles': availableVehicles,
        };
      }).toList();
    } catch (error) {
      debugPrint('Error fetching dengue cases: $error');
      return [];
    }
  }

  // Fetch your own dengue history (where resident_id = your resident_id AND closed_by is not null)
  static Future<List<Map<String, dynamic>>> fetchYourDengueHistory(String residentId) async {
    try {
      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            id,
            resident_id,
            reporter_id,
            reporter_relationship,
            handled_by,
            closed_by,
            case_status,
            created_at,
            resident:resident_id(id, first_name, last_name),
            handler:health_center_users!handled_by(id, first_name, last_name),
            closer:health_center_users!closed_by(id, first_name, last_name)
          ''')
          .eq('resident_id', residentId)
          .not('closed_by', 'is', null)
          .order('created_at', ascending: false);

      debugPrint('Fetching your dengue history for resident_id: $residentId');
      debugPrint('Response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<Map<String, dynamic>>((report) => {
        'id': report['id'],
        'resident_id': report['resident_id'],
        'name': report['resident'] != null 
            ? "${report['resident']['first_name']} ${report['resident']['last_name']}"
            : 'Unknown',
        'report_status': report['case_status'],
        'created_at': report['created_at'],
        'reporter_relationship': report['reporter_relationship'],
        'handled_by_name': report['handler'] != null 
            ? "${report['handler']['first_name']} ${report['handler']['last_name']}"
            : null,
        'closed_by_name': report['closer'] != null
            ? "${report['closer']['first_name']} ${report['closer']['last_name']}"
            : null,
      }).toList();
    } catch (error) {
      debugPrint('Error fetching your dengue history: $error');
      return [];
    }
  }

  // Fetch other dengue history you reported (where reporter_id = your user_id AND closed_by is not null)
  static Future<List<Map<String, dynamic>>> fetchOtherDengueHistory(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            id,
            resident_id,
            reporter_id,
            reporter_relationship,
            handled_by,
            closed_by,
            case_status,
            created_at,
            resident:resident_id(id, first_name, last_name),
            handler:health_center_users!handled_by(id, first_name, last_name),
            closer:health_center_users!closed_by(id, first_name, last_name)
          ''')
          .eq('reporter_id', userId)
          .not('closed_by', 'is', null)
          .order('created_at', ascending: false);

      debugPrint('Fetching other dengue history for reporter_id: $userId');
      debugPrint('Response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<Map<String, dynamic>>((report) => {
        'id': report['id'],
        'resident_id': report['resident_id'],
        'name': report['resident'] != null 
            ? "${report['resident']['first_name']} ${report['resident']['last_name']}"
            : 'Unknown',
        'report_status': report['case_status'],
        'created_at': report['created_at'],
        'reporter_relationship': report['reporter_relationship'],
        'handled_by_name': report['handler'] != null 
            ? "${report['handler']['first_name']} ${report['handler']['last_name']}"
            : null,
        'closed_by_name': report['closer'] != null
            ? "${report['closer']['first_name']} ${report['closer']['last_name']}"
            : null,
      }).toList();
    } catch (error) {
      debugPrint('Error fetching other dengue history: $error');
      return [];
    }
  }

  // Legacy method for backward compatibility
  static Future<List<Map<String, dynamic>>> fetchDengueHistory(String residentId) async {
    try {
      final response = await Supabase.instance.client
          .from('dengue_cases')
          .select('''
            id,
            resident_id,
            handled_by,
            closed_by,
            case_status,
            created_at,
            resident:resident_id(id, first_name, last_name),
            handler:health_center_users!handled_by(id, first_name, last_name),
            closer:health_center_users!closed_by(id, first_name, last_name)
          ''')
          .eq('resident_id', residentId)
          .not('closed_by', 'is', null)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return response.map<Map<String, dynamic>>((report) => {
        'id': report['id'],
        'resident_id': report['resident_id'],
        'name': report['resident'] != null 
            ? "${report['resident']['first_name']} ${report['resident']['last_name']}"
            : 'Unknown',
        'report_status': report['case_status'],
        'created_at': report['created_at'],
        'handled_by_name': report['handler'] != null 
            ? "${report['handler']['first_name']} ${report['handler']['last_name']}"
            : null,
        'closed_by_name': report['closer'] != null
            ? "${report['closer']['first_name']} ${report['closer']['last_name']}"
            : null,
      }).toList();
    } catch (error) {
      debugPrint('Error fetching dengue history: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBreedingSiteReports(String residentId) async {
    try {
      final response = await Supabase.instance.client
          .from('breeding_sites_reports')
          .select('id, latitude, longitude, image, barangay_id, status, description, created_at, barangay(name), updated_at')
          .eq('resident_id', residentId)
          .neq('status', 'Resolved')
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        debugPrint('No breeding site reports found.');
        return [];
      }

      return response.map<Map<String, dynamic>>((report) => {
        'id': report['id'],
        'latitude': report['latitude'],
        'longitude': report['longitude'],
        'image': report['image'],
        'barangay_name': report['barangay']['name'],
        'status': report['status'],
        'description': report['description'],
        'created_at': report['created_at'],
        'updated_at': report['updated_at'],
      }).toList();
    } catch (error) {
      debugPrint('Error fetching breeding site reports: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBreedingSiteHistory(String residentId) async {
    try {
      final response = await Supabase.instance.client
          .from('breeding_sites_reports')
          .select('id, latitude, longitude, image, barangay_id, status, description, created_at, barangay(name), updated_at')
          .eq('resident_id', residentId)
          .eq('status', 'Resolved')
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        debugPrint('No breeding site history found.');
        return [];
      }

      return response.map<Map<String, dynamic>>((report) => {
        'id': report['id'],
        'latitude': report['latitude'],
        'longitude': report['longitude'],
        'image': report['image'],
        'barangay_name': report['barangay']['name'],
        'status': report['status'],
        'description': report['description'],
        'created_at': report['created_at'],
        'updated_at': report['updated_at'],
      }).toList();
    } catch (error) {
      debugPrint('Error fetching breeding site history: $error');
      return [];
    }
  }

  static void showReportDetailsModal(BuildContext context, Map<String, dynamic> report, String reportType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return ReportDetailsModal(report: report, reportType: reportType);
      },
    );
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      // Breeding site statuses
      case 'reported':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      
      // Dengue case statuses
      case 'suspected':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'invalid':
        return Colors.red;
      case 'probable':
        return Colors.purple;
      
      // Vehicle request statuses
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.green;
      
      // Legacy statuses (for backward compatibility)
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

