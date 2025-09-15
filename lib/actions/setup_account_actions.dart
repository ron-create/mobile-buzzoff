import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupAccountActions {
  final supabase = Supabase.instance.client;

  // Fetch authenticated user ID
  String? getCurrentUserId() {
    final user = supabase.auth.currentUser;
    return user?.id;
  }


Future<String?> getBarangayName() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    print("❌ No authenticated user");
    return null;
  }

  try {
    // Step 1: Get user_id from users table
    final userData = await supabase
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (userData == null || userData['id'] == null) {
      print("❌ No user_id found for auth_id: ${user.id}");
      return null;
    }

    final userId = userData['id'];
    print("✅ Found user_id: $userId");

    // Step 2: Get barangay_id from resident table
    final residentData = await supabase
        .from('resident')
        .select('barangay_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (residentData == null || residentData['barangay_id'] == null) {
      print("❌ No barangay_id found for user_id: $userId");
      return null;
    }

    final barangayId = residentData['barangay_id'];
    print("✅ Found barangay_id: $barangayId");

    // Step 3: Get barangay name from barangay table
    final barangayData = await supabase
        .from('barangay')
        .select('name')
        .eq('id', barangayId)
        .maybeSingle();

    if (barangayData == null || barangayData['name'] == null) {
      print("❌ No barangay name found for id: $barangayId");
      return null;
    }

    print("✅ Found barangay name: ${barangayData['name']}");
    return barangayData['name'];
  } catch (error) {
    print("❌ Error fetching barangay name: $error");
    return null;
  }
}


Future<String?> updateAccountDetails({
  required String firstName,
  required String lastName,
  String? middleName, // Optional
  String? suffixName, // Optional
  required String dateOfBirth, // ✅ Use birth date instead of age
  required String phoneNumber,
  required double latitude, 
  required double longitude,
  required String address,
  required String sex, // ✅ Add this line
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    return "User not authenticated.";
  }

  try {
    // Step 1: Get user_id from users table using auth_id
    final userData = await supabase
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (userData == null || userData['id'] == null) {
      return "User record not found.";
    }

    final userId = userData['id'];

    // Step 2: Prepare update data
    final updateData = {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'date_of_birth': dateOfBirth, // ✅ Store birth date
      'phone': phoneNumber.trim(),
      'latitude': latitude, 
      'longitude': longitude, 
      'address': address.trim(),
      'sex': sex, // ✅ Add this line
    };

    // Add optional fields if provided
    if (middleName != null && middleName.trim().isNotEmpty) {
      updateData['middle_name'] = middleName.trim();
    }
    if (suffixName != null && suffixName.trim().isNotEmpty) {
      updateData['suffix_name'] = suffixName.trim();
    }

    // Step 3: Update resident details using users_id
    final response = await supabase
        .from('resident')
        .update(updateData)
        .match({'user_id': userId});

    return null; // Success
  } catch (error) {
    return "Error: $error";
  }
}

  Future<String?> uploadProofOfResidency({
    required File imageFile,
    required Map<String, dynamic> userData,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    // Debug: Check authentication
    print("🔍 User authenticated: ${user != null}");
    print("🔍 User ID: ${user?.id}");
    
    try {
      // Upload image to Supabase Storage (no auth check, like web)
      final fileExt = imageFile.path.split('.').last;
      String fileName;
      
      if (user != null) {
        // Use user ID like web code
        fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.${fileExt}';
      } else {
        // Fallback for unauthenticated users
        fileName = '${DateTime.now().millisecondsSinceEpoch}.${fileExt}';
      }
      
      final storagePath = 'residency/$fileName';
      
      print("🔍 Uploading to: $storagePath");
      
      final response = await supabase.storage.from('residency').upload(
        storagePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      
      if (response is! String) {
        print("❌ Upload failed");
        return "Failed to upload image.";
      }
      
      print("✅ Upload successful");
      final publicUrl = supabase.storage.from('residency').getPublicUrl(storagePath);
      
      // If user is authenticated, update resident table
      if (user != null) {
        print("🔍 Getting user data from DB...");
        final userDataDb = await supabase
            .from('users')
            .select('id')
            .eq('auth_id', user.id)
            .maybeSingle();
        
        if (userDataDb != null && userDataDb['id'] != null) {
          final userId = userDataDb['id'];
          print("✅ User ID: $userId");
          
          // Build complete address from userData
          List<String> addressParts = [];
          if (userData['block_lot'] != null && userData['block_lot'].toString().trim().isNotEmpty) {
            addressParts.add(userData['block_lot'].toString().trim());
          }
          if (userData['street_subdivision'] != null && userData['street_subdivision'].toString().trim().isNotEmpty) {
            addressParts.add(userData['street_subdivision'].toString().trim());
          }
          if (userData['address'] != null && userData['address'].toString().trim().isNotEmpty) {
            addressParts.add(userData['address'].toString().trim());
          }
          
          final completeAddress = addressParts.join(", ");
          print("🔍 Complete address: $completeAddress");
          
          // Update resident table with complete data
          print("🔍 Updating resident table...");
          await supabase
              .from('resident')
              .update({
                'proof_of_residency': publicUrl,
                'address': completeAddress,
                'latitude': userData['latitude'] ?? 0.0,
                'longitude': userData['longitude'] ?? 0.0,
                'first_name': userData['firstName'] ?? '',
                'last_name': userData['lastName'] ?? '',
                'middle_name': userData['middleName'] ?? '',
                'suffix_name': userData['suffixName'] ?? '',
                'date_of_birth': userData['birthDate'] ?? '',
                'sex': userData['sex'] ?? '',
                'phone': userData['phoneNumber'] ?? '',
              })
              .match({'user_id': userId});
          
          // Set users.status to 'Pending'
          print("🔍 Setting status to Pending...");
          await supabase
              .from('users')
              .update({'status': 'Pending'})
              .eq('id', userId);
          
          print("✅ All updates successful");
        }
      }
      
      return null; // Success
    } catch (e) {
      print("❌ Error: $e");
      return "Error uploading proof: $e";
    }
  }
}