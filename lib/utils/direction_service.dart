import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class DirectionsService {
  /// Opens directions to a specific location using the device's default map app
  static Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    try {
      // Get current location for starting point
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        // If we can't get current location, we'll just open the destination
        print('Could not get current location: $e');
      }

      // Create the URL for directions
      String url;
      if (currentPosition != null) {
        // Directions from current location to destination
        url = 'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=$latitude,$longitude';
        if (destinationName != null) {
          url += '&destination_place_id=$destinationName';
        }
      } else {
        // Just open the destination location
        url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
        if (destinationName != null) {
          url += '&query_place_id=$destinationName';
        }
      }

      // Launch the URL
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch directions URL');
      }
    } catch (e) {
      print('Error opening directions: $e');
      rethrow;
    }
  }

  /// Opens directions with explicit origin and destination
  static Future<void> openDirectionsWithOrigin({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    String? destinationName,
  }) async {
    try {
      String url = 'https://www.google.com/maps/dir/?api=1&origin=$originLatitude,$originLongitude&destination=$destinationLatitude,$destinationLongitude';
      if (destinationName != null) {
        url += '&destination_place_id=$destinationName';
      }

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch directions URL');
      }
    } catch (e) {
      print('Error opening directions with origin: $e');
      rethrow;
    }
  }

  /// Opens a location in Google Maps without directions
  static Future<void> openLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      String url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (locationName != null) {
        url += '&query_place_id=$locationName';
      }

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch location URL');
      }
    } catch (e) {
      print('Error opening location: $e');
      rethrow;
    }
  }
}
