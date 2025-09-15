import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class BreedingSiteMap extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String) onLocationSelected;
  final bool showBackButton;

  const BreedingSiteMap({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  _BreedingSiteMapState createState() => _BreedingSiteMapState();
}

class _BreedingSiteMapState extends State<BreedingSiteMap> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String? _selectedBarangay;
  bool _isLoading = false;

  List<LatLng> dasmaBoundary = [];
  List<Map<String, dynamic>> barangayBoundaries = [];

  // Dasmariñas boundaries (approximate)
  static final LatLngBounds dasmarinasBounds = LatLngBounds.fromPoints([
    const LatLng(14.25, 120.90), // Southwest corner
    const LatLng(14.40, 121.05), // Northeast corner
  ]);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    
    if (_selectedLocation != null) {
      _getBarangayFromLocation(_selectedLocation!);
    }
    _loadGeoJsonData();
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final String dasmaString = await rootBundle.loadString('assets/geojson/dasma.geojson');
      final dasmaData = json.decode(dasmaString);

      if (dasmaData['features'].isNotEmpty) {
        List coordinates = dasmaData['features'][0]['geometry']['coordinates'][0];
        setState(() {
          dasmaBoundary = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        });
      }

      final String barangayString = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      final barangayData = json.decode(barangayString);

      final features = barangayData['features'] as List;
      List<Map<String, dynamic>> loadedBarangays = [];

      for (var feature in features) {
        final String barangayName = feature['properties']['name'] ?? "Unknown";
        final geometry = feature['geometry'];

        if (geometry['type'] == 'Polygon') {
          List coordinates = geometry['coordinates'][0];
          List<LatLng> boundaryPoints = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

          loadedBarangays.add({"name": barangayName, "boundary": boundaryPoints});
        }
      }

      setState(() {
        barangayBoundaries = loadedBarangays;
      });

    } catch (e) {
      print("❌ Error loading GeoJSON: $e");
    }
  }

  Future<void> _getBarangayFromLocation(LatLng location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? '';
        
        // Check if user is in Dasmariñas
        if (city.toLowerCase().contains('dasmariñas') || 
            city.toLowerCase().contains('dasmarinas')) {
          setState(() {
            _selectedBarangay = place.subLocality ?? place.locality ?? 'Unknown Barangay';
            _isLoading = false;
          });
          
          // Only call callback if we don't already have a barangay name
          if (_selectedBarangay != null && _selectedBarangay!.isNotEmpty) {
            widget.onLocationSelected(location, _selectedBarangay!);
          }
        } else {
          // Even if outside Dasma, still show the location but mark as outside
          setState(() {
            _selectedBarangay = 'Outside Dasmariñas';
            _isLoading = false;
          });
          
          // Only call callback if we don't already have a barangay name
          if (_selectedBarangay != null && _selectedBarangay!.isNotEmpty) {
            widget.onLocationSelected(location, _selectedBarangay!);
          }
        }
      } else {
        setState(() {
          _selectedBarangay = 'Unknown Location';
          _isLoading = false;
        });
        
        // Only call callback if we don't already have a barangay name
        if (_selectedBarangay != null && _selectedBarangay!.isNotEmpty) {
          widget.onLocationSelected(location, _selectedBarangay!);
        }
      }
    } catch (e) {
      setState(() {
        _selectedBarangay = 'Error getting location';
        _isLoading = false;
      });
      
      // Only call callback if we don't already have a barangay name
      if (_selectedBarangay != null && _selectedBarangay!.isNotEmpty) {
        widget.onLocationSelected(location, _selectedBarangay!);
      }
    }
  }

  bool _isWithinDasmarinas(LatLng location) {
    return dasmarinasBounds.contains(location);
  }

  String _getBarangayName(LatLng point) {
    for (var barangay in barangayBoundaries) {
      if (_isPointInsidePolygon(point, barangay['boundary'])) {
        return barangay['name'];
      }
    }
    return "Unknown";
  }

  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      LatLng p1 = polygon[j];
      LatLng p2 = polygon[j + 1];

      if ((p1.latitude > point.latitude) != (p2.latitude > point.latitude) &&
          point.longitude < (p2.longitude - p1.longitude) * (point.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude) {
        intersectCount++;
      }
    }
    return intersectCount % 2 == 1;
  }

  void _updateMapLocation(LatLng newLocation) {
    setState(() {
      _selectedLocation = newLocation;
    });
    
    // Center map on the new location
    _mapController.move(newLocation, 15.0);
    
  }

  @override
  void didUpdateWidget(BreedingSiteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation && widget.initialLocation != null) {
      _updateMapLocation(widget.initialLocation!);
      _getBarangayFromLocation(widget.initialLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _selectedLocation ?? const LatLng(14.3294, 120.9367),
              zoom: 14.0,
              minZoom: 12.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                print('🗺️ Tapped at: ${point.latitude}, ${point.longitude}');
                
                // Check if location is within Dasmariñas bounds
                if (!_isWithinDasmarinas(point)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a location within Dasmariñas.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                // Allow tapping only within Dasmariñas
                setState(() {
                  _selectedLocation = point;
                  _isLoading = false; // Reset loading state
                });
                
                // First try to get barangay from GeoJSON boundaries
                String barangayName = _getBarangayName(point);
                print('📍 Detected barangay: $barangayName');
                
                if (barangayName != "Unknown") {
                  setState(() {
                    _selectedBarangay = barangayName;
                  });
                  print('✅ Barangay set to: $barangayName');
                  
                  // Call the callback with the detected barangay
                  widget.onLocationSelected(point, barangayName);
                } else {
                  // If no GeoJSON result, set a default and call callback
                  setState(() {
                    _selectedBarangay = 'Unknown Barangay';
                  });
                  
                  // Call the callback with the default barangay
                  widget.onLocationSelected(point, 'Unknown Barangay');
                }
              },
              interactiveFlags: InteractiveFlag.drag |
                  InteractiveFlag.flingAnimation |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.pinchMove |
                  InteractiveFlag.doubleTapZoom,
              keepAlive: true,
              enableScrollWheel: true,
              enableMultiFingerGestureRace: true,
              onMapReady: () {
                _mapController.fitBounds(
                  dasmarinasBounds,
                  options: const FitBoundsOptions(
                    padding: EdgeInsets.all(50.0),
                  ),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.buzzoff',
              ),
              // Dasmariñas City Boundary
              if (dasmaBoundary.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: dasmaBoundary,
                      color: Colors.transparent,
                      borderColor: Colors.black,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              // Barangay Boundaries
              for (var barangay in barangayBoundaries)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: barangay['boundary'],
                      color: Colors.transparent,
                      borderColor: Colors.black.withOpacity(0.7),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Back button
          if (widget.showBackButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: 24,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          if (_isLoading)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5271FF)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to get the nearest valid position within bounds
  LatLng _getNearestValidPosition(LatLng position) {
    double lat = position.latitude;
    double lng = position.longitude;

    // Clamp latitude
    lat = lat.clamp(
      dasmarinasBounds.southWest.latitude,
      dasmarinasBounds.northEast.latitude,
    );

    // Clamp longitude
    lng = lng.clamp(
      dasmarinasBounds.southWest.longitude,
      dasmarinasBounds.northEast.longitude,
    );

    return LatLng(lat, lng);
  }
}
