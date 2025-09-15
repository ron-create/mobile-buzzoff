import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPageActions {
  final supabase = Supabase.instance.client;

  // Fetch barangays from the database
 Future<List<Map<String, dynamic>>> fetchBarangays() async {
  final response = await supabase
      .from('barangay')
      .select('id, name')
      .order('name', ascending: true); // Order by name in ascending order
  
  return response.map((barangay) => {
    'id': barangay['id'],
    'name': barangay['name'],
  }).toList();
}

// Register a new user
Future<String?> registerUser({
  required String email,
  required String barangayId,
  required String password,
}) async {
  try {
    // Step 1: Create user in Supabase Auth
    final authResponse = await supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );

    if (authResponse.user == null) {
      return "Registration failed. Please try again.";
    }

    final String authId = authResponse.user!.id;

    // Step 2: Insert user into 'users' table
    final userInsertResponse = await supabase.from('users').insert({
      'auth_id': authId,
      'email': email.trim(),
      'role': 'resident', // Default role
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    final String userId = userInsertResponse['id'];

    // Step 3: Insert initial resident data
    await supabase.from('resident').insert({
      'user_id': userId,
      'barangay_id': barangayId,
      'created_at': DateTime.now().toIso8601String(),
    });

    return null; // Success
  } catch (error) {
    return "Error: $error";
  }
}

}
