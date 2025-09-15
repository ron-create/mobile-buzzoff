import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class MapQuickAccessAction {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch resident's location
  Future<Map<String, dynamic>?> fetchResidentLocation(String authId) async {
    try {
      // First get the user_id from users table using auth_id
      final userResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_id', authId)
          .single();

      final userId = userResponse['id'];

      // Then get the resident information using user_id
      final residentResponse = await _supabase
          .from('resident')
          .select('latitude, longitude')
          .eq('user_id', userId)
          .single();

      return residentResponse;
    } catch (e) {
      debugPrint('Error fetching resident location: $e');
      return null;
    }
  }

  // Fetch barangay ID from name
  Future<String?> fetchBarangayId(String barangayName) async {
    try {
      final response = await _supabase
          .from('barangay')
          .select('id')
          .eq('name', barangayName)
          .single();
      
      return response['id'];
    } catch (e) {
      debugPrint('Error fetching barangay ID: $e');
      return null;
    }
  }

  // Fetch barangay data with dengue cases and breeding sites
  Future<Map<String, dynamic>> fetchBarangayData(String barangayName) async {
    try {
      // Fetch dengue cases
      final dengueResponse = await _supabase
          .from('dengue_cases')
          .select('*, resident:resident_id(*, barangay:barangay_id(name))')
          .eq('case_status', 'Confirmed')
          .eq('outcome', 'Ongoing');

      // Fetch breeding sites
      final breedingResponse = await _supabase
          .from('breeding_sites_reports')
          .select('*, barangay:barangay_id(name)')
          .neq('status', 'Resolved');

      final List<Map<String, dynamic>> dengueCases = List<Map<String, dynamic>>.from(dengueResponse ?? []);
      final List<Map<String, dynamic>> breedingSites = List<Map<String, dynamic>>.from(breedingResponse ?? []);

      // Filter cases and sites for the specific barangay
      final barangayDengueCases = dengueCases.where((case_) {
        final resident = case_['resident'] as Map<String, dynamic>?;
        final barangay = resident?['barangay'] as Map<String, dynamic>?;
        return barangay?['name'] == barangayName;
      }).toList();

      final barangayBreedingSites = breedingSites.where((site) {
        final barangay = site['barangay'] as Map<String, dynamic>?;
        return barangay?['name'] == barangayName;
      }).toList();

      return {
        'name': barangayName,
        'dengue_cases': barangayDengueCases,
        'breeding_sites': barangayBreedingSites,
      };
    } catch (e) {
      debugPrint('Error fetching barangay data: $e');
      return {
        'name': barangayName,
        'dengue_cases': [],
        'breeding_sites': [],
      };
    }
  }

  // Fetch nearby hospitals
  Future<List<Map<String, dynamic>>> fetchNearbyHospitals(double lat, double lng, double radius) async {
    try {
      // Load hospital GeoJSON data
      final String hospitalData = await rootBundle.loadString('assets/geojson/clinichospital.geojson');
      final Map<String, dynamic> hospitalJson = json.decode(hospitalData);
      
      List<Map<String, dynamic>> nearbyHospitals = [];
      
      // Calculate distance for each hospital
      for (var feature in hospitalJson['features']) {
        try {
          if (feature['geometry'] == null || 
              feature['geometry']['coordinates'] == null || 
              feature['geometry']['coordinates'].length < 2) {
            debugPrint('Invalid hospital coordinates: $feature');
            continue;
          }

          final hospitalLat = feature['geometry']['coordinates'][1];
          final hospitalLng = feature['geometry']['coordinates'][0];
          
          if (hospitalLat == null || hospitalLng == null) {
            debugPrint('Null coordinates for hospital: $feature');
            continue;
          }
          
          // Calculate distance
          final distance = _calculateDistance(lat, lng, hospitalLat, hospitalLng);
          
          if (distance <= radius) {
            // Safely get the name from properties
            String hospitalName = 'Unknown Hospital';
            if (feature['properties'] != null && feature['properties']['name'] != null) {
              hospitalName = feature['properties']['name'].toString();
            }
            
            nearbyHospitals.add({
              'name': hospitalName,
              'lat': hospitalLat,
              'lng': hospitalLng,
              'distance': distance,
            });
          }
        } catch (e) {
          debugPrint('Error processing hospital feature: $e');
          continue;
        }
      }
      
      debugPrint('Found ${nearbyHospitals.length} nearby hospitals');
      return nearbyHospitals;
    } catch (e) {
      debugPrint('Error fetching nearby hospitals: $e');
      return [];
    }
  }

  // Fetch nearby breeding sites
  Future<List<Map<String, dynamic>>> fetchNearbyBreedingSites(
    double latitude,
    double longitude,
    double radius,
  ) async {
    try {
      final response = await _supabase
          .from('breeding_sites_reports')
          .select('*, barangay:barangay_id(name)')
          .neq('status', 'Resolved');

      final List<Map<String, dynamic>> sites = List<Map<String, dynamic>>.from(response);
      return sites.where((site) {
        if (site['latitude'] == null || site['longitude'] == null) return false;
        final distance = _calculateDistance(
          latitude,
          longitude,
          double.parse(site['latitude'].toString()),
          double.parse(site['longitude'].toString()),
        );
        return distance <= radius;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching nearby breeding sites: $e');
      return [];
    }
  }

  // Fetch nearby dengue cases
  Future<List<Map<String, dynamic>>> fetchNearbyDengueCases(
    double latitude,
    double longitude,
    double radius,
  ) async {
    try {
      final response = await _supabase
          .from('dengue_cases')
          .select('*, resident:resident_id(*, barangay:barangay_id(name))')
          .eq('case_status', 'Confirmed')
          .eq('outcome', 'Ongoing');

      final List<Map<String, dynamic>> cases = List<Map<String, dynamic>>.from(response);
      return cases.where((case_) {
        if (case_['latitude'] == null || case_['longitude'] == null) return false;
        final distance = _calculateDistance(
          latitude,
          longitude,
          double.parse(case_['latitude'].toString()),
          double.parse(case_['longitude'].toString()),
        );
        return distance <= radius;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching nearby dengue cases: $e');
      return [];
    }
  }

  // Helper function to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}
