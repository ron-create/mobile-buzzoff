import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DengueCaseActions {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchResidentDetails() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    print("Current Auth ID: ${user.id}");

    // Step 1: Fetch the corresponding user_id from users table
    final userResponse = await supabase
        .from('users')
        .select('id') // Selects the user_id (id in users table)
        .eq('auth_id', user.id)
        .maybeSingle();

    if (userResponse == null) {
      print("No user found with auth_id: ${user.id}");
      throw Exception("User not found.");
    }

    final String userId = userResponse['id'];
    print("Retrieved User ID: $userId");

    // Step 2: Fetch resident details using the user_id
    final residentResponse = await supabase
        .from('resident')
        .select('id, user_id, first_name, middle_name, last_name, suffix_name, phone, barangay_id, date_of_birth, sex, address, latitude, longitude')
        .eq('user_id', userId)
        .maybeSingle();

    if (residentResponse == null) {
      print("No resident found with user_id: $userId");
      throw Exception("Resident details not found.");
    }

    print("Resident details fetched: $residentResponse");

    // Compute age from date_of_birth
    DateTime? dob = residentResponse['date_of_birth'] != null
        ? DateTime.parse(residentResponse['date_of_birth'])
        : null;
    int? age;
    if (dob != null) {
      final today = DateTime.now();
      age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
    }

    return {
      ...residentResponse,
      'age': age,
    };
  }

  Future<String?> fetchBarangayName(String barangayId) async {
    final response = await supabase
        .from('barangay')
        .select('name')
        .eq('id', barangayId)
        .maybeSingle();

    return response?['name'];
  }

  Future<bool> checkDailyReportLimit(String residentId) async {
    try {
      // Get today's start and end timestamps
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Format timestamps to match the database format
      final startTimestamp = startOfDay.toUtc().toIso8601String();
      final endTimestamp = endOfDay.toUtc().toIso8601String();

      debugPrint('Checking reports between $startTimestamp and $endTimestamp');

      // Count reports for today using created_at
      final response = await supabase
          .from('dengue_cases')
          .select('created_at')
          .eq('resident_id', residentId)
          .gte('created_at', startTimestamp)
          .lt('created_at', endTimestamp);

      final count = response.length;
      debugPrint('Found $count reports today for resident $residentId');
      
      if (count >= 3) {
        throw Exception("You have reached the maximum limit of 3 reports per day.");
      }
      
      return true;
    } catch (error) {
      debugPrint('Error checking daily report limit: $error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitDengueCase({
    required bool isReportingForSelf,
    String? residentId, // For self-reporting
    // For reporting others
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffixName,
    String? dateOfBirth,
    String? sex,
    String? phone,
    String? barangayId,
    String? homeAddress,
    String? streetName,
    String? selectedBarangayName,
    String? relationship,
    double? latitude,
    double? longitude,
  }) async {
    try {
      String targetResidentId;
      String reporterId;

      // Get current user's user_id for reporter_id
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      final userResponse = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception("User not found.");
      }

      reporterId = userResponse['id'];

      if (isReportingForSelf) {
        // Self-reporting: use existing resident
        if (residentId == null) throw Exception("Resident ID is required for self-reporting");
        targetResidentId = residentId;
        
        // Check daily report limit for self
        await checkDailyReportLimit(residentId);
      } else {
        // Reporting others: create or find resident record
        if (firstName == null || lastName == null || phone == null || barangayId == null) {
          throw Exception("Required fields missing for reporting others");
        }

        // Build full address
        final addressParts = <String>[];
        if (homeAddress?.trim().isNotEmpty == true) {
          addressParts.add(homeAddress!.trim());
        }
        if (streetName?.trim().isNotEmpty == true) {
          addressParts.add(streetName!.trim());
        }
        if (selectedBarangayName != null) {
          addressParts.add(selectedBarangayName);
        }
        addressParts.add('Dasmariñas, Cavite');
        
        final fullAddress = addressParts.join(', ');

        // Check if resident already exists (by phone number and name)
        final existingResident = await supabase
            .from('resident')
            .select('id')
            .eq('phone', phone)
            .eq('first_name', firstName)
            .eq('last_name', lastName)
            .maybeSingle();

        if (existingResident != null) {
          targetResidentId = existingResident['id'];
          debugPrint('Found existing resident: $targetResidentId');
        } else {
          // Create new resident record (without user_id since they don't have an account)
          final newResident = await supabase
              .from('resident')
              .insert({
                'barangay_id': barangayId,
                'first_name': firstName,
                'last_name': lastName,
                'middle_name': middleName ?? '',
                'suffix_name': suffixName ?? '',
                'date_of_birth': dateOfBirth,
                'sex': sex,
                'address': fullAddress,
                'latitude': latitude,
                'longitude': longitude,
                'phone': phone,
              })
              .select('id')
              .single();

          targetResidentId = newResident['id'];
          debugPrint('Created new resident: $targetResidentId');
        }

        // Check daily report limit for the patient
        await checkDailyReportLimit(targetResidentId);
      }

      // Create dengue case record
      final now = DateTime.now().toUtc();
      final dengueCase = await supabase
          .from('dengue_cases')
          .insert({
            'resident_id': targetResidentId,
            'reporter_id': reporterId,
            'reporter_relationship': isReportingForSelf ? 'Self' : (relationship ?? 'Other'),
            'latitude': latitude,
            'longitude': longitude,
            'case_status': 'Suspected',
            'created_at': now.toIso8601String(),
          })
          .select()
          .single();

      return dengueCase;
    } catch (error) {
      debugPrint('Error submitting dengue case: $error');
      rethrow;
    }
  }
}