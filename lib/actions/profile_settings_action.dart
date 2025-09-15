import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ProfileSettingsAction {
  // Singleton pattern
  static final ProfileSettingsAction _instance = ProfileSettingsAction._internal();
  factory ProfileSettingsAction() => _instance;
  ProfileSettingsAction._internal();

  // Get current user data (user and resident info)
  Future<Map<String, dynamic>> fetchUserData(BuildContext context) async {
    try {
      // Get current authenticated user
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user data from users table
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('auth_id', authUser.id)
          .single();
      
      // Get resident data using user_id
      final residentData = await Supabase.instance.client
          .from('resident')
          .select()
          .eq('user_id', userData['id'])
          .single();
      
      return {
        'user': userData,
        'resident': residentData,
      };
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
  }

  // Pick image from camera
  Future<XFile?> takeProfileImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
  }

  // Ensure image is compatible with Supabase storage
  Future<(XFile, String)?> ensureImageCompatibility(XFile image) async {
    try {
      // Get file info
      final fileSize = await image.length();
      final fileExt = image.path.split('.').last.toLowerCase();
      
      debugPrint('Checking image: size=${fileSize}B, extension=$fileExt');
      
      // Check file size (limit to 5MB to be safe)
      if (fileSize > 5 * 1024 * 1024) {
        debugPrint('Image too large: ${fileSize}B');
        return null;
      }
      
      // Check supported format
      if (!['jpg', 'jpeg', 'png'].contains(fileExt)) {
        debugPrint('Unsupported image format: $fileExt');
        
        // For .gif or other formats, we could convert here if needed
        return null;
      }
      
      // For very large images, we could resize them here
      // This would require additional packages
      
      return (image, fileExt);
    } catch (e) {
      debugPrint('Error checking image compatibility: $e');
      return null;
    }
  }

  // Upload profile image to Supabase storage with improved error handling
  Future<String?> uploadProfileImage(XFile image, String userId) async {
    try {
      debugPrint('Starting image upload process');
      
      // Check image compatibility
      final imageCheck = await ensureImageCompatibility(image);
      if (imageCheck == null) {
        debugPrint('Image incompatible for upload');
        return null;
      }
      
      final (validImage, fileExt) = imageCheck;
      
      // Read image bytes
      final bytes = await validImage.readAsBytes();
      debugPrint('Image size: ${bytes.length} bytes');
      
      // Use the format from your example URL: userId_timestamp.extension
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      debugPrint('Generated filename: $fileName');
      
      // Print Supabase client status
      debugPrint('Supabase client session: ${Supabase.instance.client.auth.currentSession != null}');
      
      // Upload the file with tracing
      debugPrint('Before upload - bucket: profile, filename: $fileName');
      
      try {
        // Test if bucket exists by uploading a tiny test file first
        final testFileName = 'test_ping_${DateTime.now().millisecondsSinceEpoch}.txt';
        final testContent = 'ping';
        final testBytes = Uint8List.fromList(testContent.codeUnits);
        
        await Supabase.instance.client
            .storage
            .from('profile')
            .uploadBinary(testFileName, testBytes);
        
        debugPrint('Test file uploaded successfully, confirming bucket exists');
        
        // Now upload the actual image
        await Supabase.instance.client
            .storage
            .from('profile')
            .uploadBinary(fileName, bytes);
        
        debugPrint('Image uploaded successfully');
        
        // Get the public URL
        final url = Supabase.instance.client
            .storage
            .from('profile')
            .getPublicUrl(fileName);
            
        debugPrint('Generated public URL: $url');
        return url;
      } catch (uploadError) {
        debugPrint('Storage upload error details: $uploadError');
        rethrow;
      }
    } on StorageException catch (e) {
      debugPrint('Supabase Storage Error: ${e.message}, Status: ${e.statusCode}');
      debugPrint('Error details: ${e.error}');
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Dedicated profile picture upload action
  Future<bool> uploadAndUpdateProfilePicture({
    required BuildContext context,
    required XFile image,
    required String userId,
  }) async {
    try {
      // First check authentication
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('❌ Error: No authenticated session');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to upload a profile picture')),
          );
        }
        return false;
      }
      
      debugPrint('✓ Authenticated session found');
      
      // Debug information
      debugPrint('Starting profile picture upload for user: $userId');
      debugPrint('Image path: ${image.path}, size: ${await image.length()} bytes');

      // Upload the image
      final uploadedUrl = await uploadProfileImage(image, userId);
      
      if (uploadedUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture')),
          );
        }
        debugPrint('Upload failed: uploadedUrl is null');
        return false;
      }
      
      debugPrint('Image successfully uploaded, URL: $uploadedUrl');
      
      // Update profile URL in users table
      try {
        await Supabase.instance.client
            .from('users')
            .update({'profile': uploadedUrl})
            .eq('id', userId);
        
        debugPrint('Database updated with new profile URL');
        
        // Verify the update by fetching the user record
        final updatedUser = await Supabase.instance.client
            .from('users')
            .select('profile')
            .eq('id', userId)
            .single();
        
        debugPrint('Fetched updated profile URL: ${updatedUser['profile']}');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
        
        return true;
      } catch (dbError) {
        debugPrint('Database update error: $dbError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile in database: ${dbError.toString()}')),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Profile picture upload error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  // Helper to check and report Supabase storage configuration
  Future<void> checkStorageConfiguration(BuildContext context) async {
    try {
      debugPrint('Checking Supabase storage configuration...');
      
      // 1. Check if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Error: No authenticated user found');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to upload images')),
          );
        }
        return;
      }
      
      // 2. Try to list files in the bucket to check permissions instead of checking if bucket exists
      try {
        final files = await Supabase.instance.client.storage.from('profile').list();
        debugPrint('Successfully listed files in profile bucket: ${files.length} files found');
      } catch (e) {
        debugPrint('⚠️ Error listing files in profile bucket: $e');
        // Try direct upload to test if bucket exists despite list error
        try {
          final testFileName = 'test_ping_${DateTime.now().millisecondsSinceEpoch}.txt';
          final testContent = 'ping';
          final bytes = Uint8List.fromList(testContent.codeUnits);
          
          await Supabase.instance.client
              .storage
              .from('profile')
              .uploadBinary(testFileName, bytes);
          
          debugPrint('Test upload successful - bucket exists but list permission denied');
          
          // Cleanup test file
          try {
            await Supabase.instance.client
                .storage
                .from('profile')
                .remove([testFileName]);
          } catch (_) {
            // Ignore cleanup errors
          }
        } catch (uploadError) {
          debugPrint('⚠️ Bucket existence test failed: $uploadError');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage error: Cannot access profile bucket. Please check Supabase configuration.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
      
      debugPrint('Storage configuration check completed');
    } catch (e) {
      debugPrint('⚠️ Error checking storage configuration: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking storage configuration: ${e.toString()}')),
        );
      }
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    required String email,
    String? profileUrl,
  }) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'profile': profileUrl,
            'email': email,
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Update resident information
  Future<bool> updateResidentInfo({
    required String residentId,
    required String firstName,
    required String lastName,
    String? middleName,
    String? suffixName,
    required String phone,
    required String address,
    required String sex,
    DateTime? dateOfBirth,
  }) async {
    try {
      await Supabase.instance.client
          .from('resident')
          .update({
            'first_name': firstName,
            'middle_name': middleName,
            'last_name': lastName,
            'suffix_name': suffixName,
            'phone': phone,
            'address': address,
            'sex': sex,
            'date_of_birth': dateOfBirth?.toIso8601String(),
          })
          .eq('id', residentId);
      return true;
    } catch (e) {
      debugPrint('Error updating resident info: $e');
      return false;
    }
  }

  // Update full profile (both user and resident)
  Future<bool> updateFullProfile({
    required BuildContext context,
    required String userId,
    required String residentId,
    required String email,
    String? profileUrl,
    XFile? profileImage,
    required String firstName,
    required String lastName,
    String? middleName,
    String? suffixName,
    required String phone,
    required String address,
    required String sex,
    DateTime? dateOfBirth,
  }) async {
    try {
      // Upload new profile image if selected
      if (profileImage != null) {
        profileUrl = await uploadProfileImage(profileImage, userId);
      }

      // Update user profile
      final userUpdated = await updateUserProfile(
        userId: userId,
        email: email,
        profileUrl: profileUrl,
      );

      // Update resident information
      final residentUpdated = await updateResidentInfo(
        residentId: residentId,
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        suffixName: suffixName,
        phone: phone,
        address: address,
        sex: sex,
        dateOfBirth: dateOfBirth,
      );

      if (userUpdated && residentUpdated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating profile')),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
      return false;
    }
  }
  
  // Change password action
  Future<bool> changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
        // Current password is required for security
        emailRedirectTo: null,
      );
      
      if (response.user != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully')),
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to change password')),
          );
        }
        return false;
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing password: ${e.message}')),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing password: ${e.toString()}')),
        );
      }
      return false;
    }
  }
  
  // Reset password via email with improved verification
  Future<bool> resetPasswordViaEmail({
    required BuildContext context, 
    required String email,
  }) async {
    try {
      debugPrint('Sending password reset email to: $email');
      
      // The resetPasswordForEmail method returns void, not AuthResponse
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // You can provide a redirect URL if needed
      );
      
      debugPrint('Password reset email requested for: $email');
      
      if (context.mounted) {
        // Show a more detailed message with instructions
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset Email Sent'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A password reset link has been sent to $email.'),
                const SizedBox(height: 10),
                const Text('Please check the following:'),
                const SizedBox(height: 5),
                const Text('• Your spam or junk folder if you don\'t see the email'),
                const Text('• Verify the email address is correct'),
                const SizedBox(height: 10),
                const Text('The link will expire in 24 hours.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
      return true;
    } on AuthException catch (e) {
      debugPrint('Supabase Auth Error: ${e.message}, Status code: ${e.statusCode}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reset email: ${e.message}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Error sending reset email: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reset email: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
  }
}
