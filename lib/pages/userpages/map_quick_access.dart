import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../actions/map_quick_access_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/map_details_modal.dart';
import '../../utils/map_service.dart';
import '../../utils/direction_service.dart';
import 'dart:math';

class MapQuickAccessPage extends StatefulWidget {
  const MapQuickAccessPage({super.key});

  @override
  State<MapQuickAccessPage> createState() => _MapQuickAccessPageState();
}

class _MapQuickAccessPageState extends State<MapQuickAccessPage> {
  final MapQuickAccessAction _action = MapQuickAccessAction();
  GoogleMapController? _mapController;
  final SupabaseClient _supabase = Supabase.instance.client;
  // Removed _isLoading since we don't want loading indicators during filter updates
  bool _showHospitals = false;
  bool _showBreedingSites = false;
  bool _showDengueCases = false;
  double _radius = 5.0; // km
  LatLng? _currentLocation;
  Map<String, dynamic>? _selectedBarangay;
  Map<String, dynamic>? _selectedHospital;
  List<Map<String, dynamic>> _nearbyHospitals = [];
  List<Map<String, dynamic>> _nearbyBreedingSites = [];
  List<Map<String, dynamic>> _nearbyDengueCases = [];
  Set<Polygon> _barangayPolygons = {};
  Map<String, dynamic> _barangayJson = {};
  // Removed _mapType and _isBasemapLoading - using Google Maps only

  // Dasmariñas bounds
  static final LatLngBounds _dasmabounds = LatLngBounds(
    southwest: const LatLng(14.28, 120.88), // Southwest corner
    northeast: const LatLng(14.38, 120.98), // Northeast corner
  );

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      debugPrint('Starting to load map data...');
      
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      debugPrint('User found: ${user.id}');

      // Load resident location
      final residentLocation = await _action.fetchResidentLocation(user.id);
      if (residentLocation != null) {
        debugPrint('Resident location found: ${residentLocation['latitude']}, ${residentLocation['longitude']}');
        setState(() {
          _currentLocation = LatLng(
            double.parse(residentLocation['latitude'].toString()),
            double.parse(residentLocation['longitude'].toString()),
          );
        });
      } else {
        debugPrint('No resident location found, using default location');
        // Set default location if no resident location found
        setState(() {
          _currentLocation = const LatLng(14.3297, 120.9372); // Dasmariñas center
        });
      }

      // Load barangay GeoJSON
      debugPrint('Loading barangay GeoJSON...');
      final String barangayData = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      _barangayJson = json.decode(barangayData);
      
      // Convert GeoJSON to polygons
      _barangayPolygons = _convertGeoJsonToPolygons(_barangayJson);
      
      debugPrint('Loaded ${_barangayPolygons.length} polygons');
      
      setState(() {
        // Map data loading completed successfully
      });
    } catch (e) {
      debugPrint('Error loading map data: $e');
      setState(() {
        // Set default location on error
        _currentLocation = const LatLng(14.3297, 120.9372);
      });
    }
  }

  Set<Polygon> _convertGeoJsonToPolygons(Map<String, dynamic> geojson) {
    Set<Polygon> polygons = {};
    
    final features = geojson['features'] as List;
    for (var feature in features) {
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      
      if (geometry['type'] == 'Polygon') {
        List coordinates = geometry['coordinates'][0];
        List<LatLng> boundaryPoints = coordinates.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
        
        // Check if this is the selected barangay
        bool isSelected = _selectedBarangay != null && 
                         _selectedBarangay!['name'] == properties['name'];
        
        polygons.add(
          Polygon(
            polygonId: PolygonId(properties['name'] ?? 'unknown'),
            points: boundaryPoints,
            fillColor: isSelected ? const Color(0xFF7A9CB6).withOpacity(0.22) : Colors.transparent,
            strokeColor: isSelected ? const Color(0xFF0C4A6E) : const Color(0xFF134E4A),
            strokeWidth: isSelected ? 3 : 2,
          ),
        );
      }
    }
    
    return polygons;
  }

  Future<void> _onBarangayTap(LatLng point) async {
    // Find the polygon that contains the tapped point
    for (var feature in _barangayJson['features']) {
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      
      if (geometry['type'] == 'Polygon') {
        List coordinates = geometry['coordinates'][0];
        List<LatLng> boundaryPoints = coordinates.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
        
        if (_isPointInPolygon(point, boundaryPoints)) {
          // No loading state needed
          
          try {
            final barangayData = await _action.fetchBarangayData(properties['name']);
            
            // Animate map movement to barangay only if controller is initialized
            if (_mapController != null) {
              final bounds = _getBoundsFromPoints(boundaryPoints);
              _mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 40),
              );
            }
            
            // Add delay for smooth animation
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _selectedBarangay = barangayData;
                  _selectedHospital = null;
                  // Update polygons to show highlighting with animation
                  _barangayPolygons = _convertGeoJsonToPolygons(_barangayJson);
                });
              }
            });
          } catch (e) {
            debugPrint('Error fetching barangay data: $e');
            // No loading state needed
          }
          break;
        }
      }
    }
  }

  Future<void> _onHospitalTap(LatLng point) async {
    for (var hospital in _nearbyHospitals) {
      if (hospital['lat'] == point.latitude && hospital['lng'] == point.longitude) {
        setState(() {
          _selectedHospital = hospital;
          _selectedBarangay = null;
        });
        break;
      }
    }
  }

  Future<void> _updateNearbyLocations() async {
    if (_currentLocation == null) return;

    try {
      if (_showHospitals) {
        _nearbyHospitals = await _action.fetchNearbyHospitals(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          _radius,
        );
      }

      if (_showBreedingSites) {
        _nearbyBreedingSites = await _action.fetchNearbyBreedingSites(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          _radius,
        );
      }

      if (_showDengueCases) {
        _nearbyDengueCases = await _action.fetchNearbyDengueCases(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          _radius,
        );
      }

      // Update UI after all data is loaded
      if (mounted) {
        setState(() {
          // This will trigger rebuild of map with updated radius circle
        });
      }
    } catch (e) {
      debugPrint('Error updating nearby locations: $e');
    }
  }

  LatLngBounds _getBoundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return _dasmabounds;
    }
    
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;
    
    for (var point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        title: const SizedBox.shrink(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            child: _buildMapWidget(),
          ),
          Positioned(
            top: 80, // Lowered from 16 to 80
            right: 16,
            child: Card(
                elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconizedControlButton(
                        icon: Icons.local_hospital,
                        isActive: _showHospitals,
                        onTap: () {
                          setState(() {
                            _showHospitals = !_showHospitals;
                        });
                            _updateNearbyLocations();
                        },
                        tooltip: 'Hospitals',
                      ),
                      const SizedBox(height: 8),
                      _buildIconizedControlButton(
                        icon: Icons.warning,
                        isActive: _showBreedingSites,
                        onTap: () {
                          setState(() {
                            _showBreedingSites = !_showBreedingSites;
                        });
                            _updateNearbyLocations();
                        },
                        tooltip: 'Breeding Sites',
                      ),
                      const SizedBox(height: 8),
                      _buildIconizedControlButton(
                        icon: Icons.coronavirus,
                        isActive: _showDengueCases,
                        onTap: () {
                          setState(() {
                            _showDengueCases = !_showDengueCases;
                        });
                            _updateNearbyLocations();
                        },
                        tooltip: 'Dengue Cases',
                      ),
                    ],
                ),
              ),
            ),
          ),
          if (_showHospitals || _showBreedingSites || _showDengueCases)
            Positioned(
              bottom: 120, // Moved higher from 16 to 120
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Radius',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                            '${(_radius * 1000).toStringAsFixed(0)} m',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF7A9CB6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radius,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: const Color(0xFF7A9CB6),
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                        _updateNearbyLocations();
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedBarangay != null || _selectedHospital != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
              child: MapDetailsModal(
                selectedBarangay: _selectedBarangay,
                selectedHospital: _selectedHospital,
                onClose: () {
                  setState(() {
                    _selectedBarangay = null;
                    _selectedHospital = null;
                    _barangayPolygons = _convertGeoJsonToPolygons(_barangayJson);
                  });
                },
                radius: _radius,
                onRadiusChanged: (value) {
                  setState(() {
                    _radius = value;
                    });
                    _updateNearbyLocations();
                },
                showRadiusControl: _showHospitals || _showBreedingSites || _showDengueCases,
                  onDirectionsRequested: () {
                    if (_selectedHospital != null) {
                      _openDirectionsToHospital(_selectedHospital!);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    // Removed _isLoading check
    if (_currentLocation == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.location_off, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Location not available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
                Text(
                'Please check your location permissions\nand try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    try {
      debugPrint('Creating Google Maps widget...');
      debugPrint('Current location: $_currentLocation');
      // Removed _mapType - using Google Maps only
      
      return GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          debugPrint('Google Maps controller created successfully');
          _mapController = controller;
          if (_currentLocation != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
            );
            debugPrint('Camera moved to current location');
          }
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(14.3297, 120.9372),
          zoom: 15.0,
        ),
        minMaxZoomPreference: const MinMaxZoomPreference(12.0, 18.0),
        mapType: MapType.normal, // Fixed map type to prevent rerendering
        onTap: (LatLng point) {
          debugPrint('Map tapped at: ${point.latitude}, ${point.longitude}');
          _onBarangayTap(point);
          _onHospitalTap(point);
        },
        onCameraMove: (CameraPosition position) {
          // Ensure the map stays within bounds
          final currentCenter = position.target;
          if (!_dasmabounds.contains(currentCenter)) {
            // If outside bounds, move back to the nearest valid position
            final boundedLat = currentCenter.latitude.clamp(
              _dasmabounds.southwest.latitude,
              _dasmabounds.northeast.latitude,
            );
            final boundedLng = currentCenter.longitude.clamp(
              _dasmabounds.southwest.longitude,
              _dasmabounds.northeast.longitude,
            );
            // Only animate if controller is initialized
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(LatLng(boundedLat, boundedLng)),
              );
            }
          }
        },
        polygons: _barangayPolygons,
        circles: _getRadiusCircle(), // Add radius circle
        markers: _getMarkers(),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        // Additional optimizations to prevent rerendering
        liteModeEnabled: false,
        mapToolbarEnabled: false,
        indoorViewEnabled: false,
        trafficEnabled: false,
        buildingsEnabled: false,
      );
    } catch (e) {
      debugPrint('Error creating Google Map: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Fallback to a simple container with error message
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
                Text(
                'Map loading error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please check your internet connection\nand try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
                ),
              ],
            ),
      ),
    );
    }
  }

  Widget _buildIconizedControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF1F8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF7A9CB6) : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF384949) : Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomMarker(IconData icon, Color color, String label) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
            ),
          ],
        ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  // Helper function to check if a point is inside a polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
          (point.latitude - polygon[i].latitude) / 
          (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  Set<Marker> _getMarkers() {
    Set<Marker> markers = {};

    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current residence location',
          ),
          flat: true,
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    if (_showHospitals) {
      for (var hospital in _nearbyHospitals) {
        try {
          if (hospital['lat'] == null || hospital['lng'] == null) {
            debugPrint('Invalid hospital coordinates: $hospital');
            continue;
          }

          markers.add(
            Marker(
              markerId: MarkerId('hospital_${hospital['id'] ?? hospital['name']}'),
              position: LatLng(
                double.parse(hospital['lat'].toString()),
                double.parse(hospital['lng'].toString()),
              ),
              // Use custom hospital icon from assets
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: hospital['name'] ?? 'Hospital',
                snippet: hospital['address'] ?? 'Medical facility',
              ),
              onTap: () {
                setState(() {
                  _selectedHospital = hospital;
                  _selectedBarangay = null;
                });
              },
              flat: true,
              anchor: const Offset(0.5, 1.0), // Standard pin anchor
            ),
          );
        } catch (e) {
          debugPrint('Error creating hospital marker: $e');
        }
      }
    }

    if (_showBreedingSites) {
      for (var site in _nearbyBreedingSites) {
        markers.add(
          Marker(
            markerId: MarkerId('breeding_site_${site['id']}'),
            position: LatLng(site['latitude'], site['longitude']),
            // Use Flutter icon - yellow marker for breeding site
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            infoWindow: InfoWindow(
              title: 'Breeding Site',
              snippet: 'Mosquito breeding location',
            ),
            flat: true,
            anchor: const Offset(0.5, 1.0), // Standard pin anchor
          ),
        );
      }
    }

    if (_showDengueCases) {
      for (var case_ in _nearbyDengueCases) {
        markers.add(
          Marker(
            markerId: MarkerId('dengue_case_${case_['id']}'),
            position: LatLng(case_['latitude'], case_['longitude']),
            // Use Flutter icon - orange marker for dengue case
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: 'Dengue Case',
              snippet: 'Reported dengue case location',
            ),
            flat: true,
            anchor: const Offset(0.5, 1.0), // Standard pin anchor
          ),
        );
      }
    }

    return markers;
  }

  Set<Circle> _getRadiusCircle() {
    Set<Circle> circles = {};
    
    // Only show radius circle when any filter is active
    if (_currentLocation != null && 
        (_showHospitals || _showBreedingSites || _showDengueCases)) {
      circles.add(
        Circle(
          circleId: const CircleId('search_radius_circle'),
          center: _currentLocation!,
          radius: _radius * 1000, // Radius in meters
          fillColor: const Color(0xFF7A9CB6).withOpacity(0.08), // Lighter fill
          strokeColor: const Color(0xFF7A9CB6).withOpacity(0.6), // Semi-transparent stroke
          strokeWidth: 3, // Thicker stroke
        ),
      );
    }
    return circles;
  }

  void _showDirectionsDialog(Map<String, dynamic> hospital) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(hospital['name'] ?? 'Hospital'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What would you like to do?'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.directions, color: Colors.blue),
                title: const Text('Get Directions'),
                subtitle: const Text('Open in Google Maps with directions'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openDirectionsToHospital(hospital);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text('View Location'),
                subtitle: const Text('Open location in Google Maps'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openHospitalLocation(hospital);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _openDirectionsToHospital(Map<String, dynamic> hospital) async {
    try {
      if (hospital['lat'] != null && hospital['lng'] != null) {
        await DirectionsService.openDirections(
          latitude: double.parse(hospital['lat'].toString()),
          longitude: double.parse(hospital['lng'].toString()),
          destinationName: hospital['name'],
        );
      }
    } catch (e) {
      debugPrint('Error opening directions: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openHospitalLocation(Map<String, dynamic> hospital) async {
    try {
      if (hospital['lat'] != null && hospital['lng'] != null) {
        await DirectionsService.openLocation(
          latitude: double.parse(hospital['lat'].toString()),
          longitude: double.parse(hospital['lng'].toString()),
          locationName: hospital['name'],
        );
      }
    } catch (e) {
      debugPrint('Error opening location: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
