import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class BreedingSiteActions {
  static final supabase = Supabase.instance.client;

  // 📸 Pick an image from the camera
  static Future<File?> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 🔄 Upload media (image or video) to Supabase Storage
  static Future<String?> uploadMedia(File media) async {
    try {
      final isVideo = media.path.endsWith('.mp4') || media.path.endsWith('.mov');
      final extension = isVideo ? (media.path.endsWith('.mp4') ? '.mp4' : '.mov') : '.jpg';
      final mediaName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final mediaPath = 'breeding_sites/$mediaName';

      // Convert to Uint8List for upload
      final Uint8List fileBytes = await media.readAsBytes();

      // Upload to Supabase Storage
      await supabase.storage.from('breeding_sites_images').uploadBinary(
        mediaPath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: isVideo ? 'video/mp4' : 'image/jpeg',
        ),
      );

      // Get Public URL
      return supabase.storage.from('breeding_sites_images').getPublicUrl(mediaPath);
    } catch (e) {
      print("❌ Media Upload Error: $e");
      return null;
    }
  }

  // 📤 Submit Breeding Site Report
  static Future<void> submitReport(
    BuildContext context,
    LatLng? selectedLocation,
    String? selectedBarangay,
    List<File> selectedMedia,
    TextEditingController descriptionController,
    Function() clearFields,
  ) async {
    if (selectedLocation == null || selectedBarangay == null || selectedMedia.isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields before submitting."),
          backgroundColor: Color(0xFF5271FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5271FF)),
            ),
          );
        },
      );

      // Get the authenticated user's auth_id
      final authId = supabase.auth.currentUser?.id;
      if (authId == null) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication required. Please log in again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        return;
      }

      // Find the user_id using the auth_id
      final userResponse = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();

      if (userResponse == null) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User profile not found. Please contact support."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        return;
      }

      final userId = userResponse['id'];

      // Find the resident_id using the user_id
      final residentResponse = await supabase
          .from('resident')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Resident profile not found. Please contact support."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        return;
      }

      final residentId = residentResponse['id'];

      // Find barangay_id from the barangay name
      final barangayData = await supabase
          .from('barangay')
          .select('id')
          .eq('name', selectedBarangay)
          .maybeSingle();

      if (barangayData == null) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Barangay not found. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        return;
      }

      final barangayId = barangayData['id'];

      // Upload media and store URLs
      List<String> mediaUrls = [];
      for (var media in selectedMedia) {
        final mediaUrl = await uploadMedia(media);
        if (mediaUrl != null) {
          mediaUrls.add(mediaUrl);
        }
      }

      if (mediaUrls.isEmpty) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload media. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        return;
      }

      // Insert Report Data
      final reportResponse = await supabase.from('breeding_sites_reports').insert({
        'longitude': selectedLocation.longitude,
        'latitude': selectedLocation.latitude,
        'image': mediaUrls.first,
        'resident_id': residentId,
        'barangay_id': barangayId,
        'status': 'Reported',
        'description': descriptionController.text,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').maybeSingle();

      if (reportResponse == null) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit report. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
        return;
      }

      final breedingSiteId = reportResponse['id'];

      // Store all media in breeding_sites_images
      for (var mediaUrl in mediaUrls) {
        await supabase.from('breeding_sites_images').insert({
          'breeding_site_id': breedingSiteId,
          'image_url': mediaUrl,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
      }

      Navigator.pop(context); // Remove loading indicator

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

      clearFields(); // Reset form fields
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }
  }

  // 📸 Fetch images for a specific report
  static Future<List<String>> getImages(String breedingSiteId) async {
    final response = await supabase
        .from('breeding_sites_images')
        .select('image_url')
        .eq('breeding_site_id', breedingSiteId);

    return response.map<String>((img) => img['image_url'] as String).toList();
  }

  // 📋 Fetch all reports with images
  static Future<List<Map<String, dynamic>>> getAllReports() async {
    final response = await supabase
        .from('breeding_sites_reports')
        .select('id, longitude, latitude, description, status, image, breeding_sites_images (image_url)')
        .order('created_at', ascending: false);

    return response;
  }

  static Future<bool> checkDailyReportLimit(BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception("Please log in to submit a report.");
      }

      // Get user_id from auth_id
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception("User profile not found. Please contact support.");
      }

      // Get resident_id from user_id
      final residentResponse = await Supabase.instance.client
          .from('resident')
          .select('id')
          .eq('user_id', userResponse['id'])
          .maybeSingle();

      if (residentResponse == null) {
        throw Exception("Resident profile not found. Please contact support.");
      }

      final residentId = residentResponse['id'];

      // Get today's start and end timestamps
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Format timestamps to match the database format
      final startTimestamp = startOfDay.toUtc().toIso8601String();
      final endTimestamp = endOfDay.toUtc().toIso8601String();

      debugPrint('Checking reports between $startTimestamp and $endTimestamp');

      // Query reports for today
      final response = await Supabase.instance.client
          .from('breeding_sites_reports')
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
    } catch (e) {
      debugPrint('Error checking daily report limit: $e');
      rethrow;
    }
  }
}
