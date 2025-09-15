import 'package:geolocator/geolocator.dart';
import 'location_permission.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location permission is granted
      final hasPermission = await LocationPermission.isGranted();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<Position?> getLastKnownLocation() async {
    try {
      final hasPermission = await LocationPermission.isGranted();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  static Future<double?> getDistanceFromCurrentLocation(double targetLat, double targetLng) async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) return null;

      return Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }
} 