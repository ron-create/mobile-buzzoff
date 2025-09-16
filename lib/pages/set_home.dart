
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../actions/setup_account_actions.dart';
import '../utils/responsive.dart';
import '../utils/map_service.dart';

class SetHome extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SetHome({super.key, required this.userData});

  @override
  State<SetHome> createState() => _SetHomeState();
}

class _SetHomeState extends State<SetHome> {
  final SetupAccountActions actions = SetupAccountActions();
  final TextEditingController _blockLotController = TextEditingController();
  final TextEditingController _streetSubdivisionController = TextEditingController();
  latlong2.LatLng? selectedLocation;
  List<latlong2.LatLng> boundary = [];
  latlong2.LatLng? center;
  GoogleMapController? _googleMapController;
  GoogleMapController? _embeddedMapController;
  Set<Polygon> _boundaryPolygons = {};
  Set<Marker> _markers = {};
  bool isOutsideBoundary = false;
  bool _isNavigating = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _blockLotController.dispose();
    _streetSubdivisionController.dispose();
    _googleMapController?.dispose();
    _embeddedMapController?.dispose();
    super.dispose();
  }

  Future<void> _loadGeoJson() async {
    try {
      final String geojsonString = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      final geojsonData = json.decode(geojsonString);
      final features = geojsonData['features'] as List;

      for (var feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties['name'].toLowerCase() == widget.userData['barangayName'].toLowerCase()) {
          List coordinates = geometry['coordinates'][0];
          List<latlong2.LatLng> boundaryPoints = coordinates.map((coord) {
            return latlong2.LatLng(coord[1], coord[0]);
          }).toList();

          double latSum = 0, lngSum = 0;
          for (var point in boundaryPoints) {
            latSum += point.latitude;
            lngSum += point.longitude;
          }
          latlong2.LatLng calculatedCenter = latlong2.LatLng(latSum / boundaryPoints.length, lngSum / boundaryPoints.length);

          // Create Google Maps polygon
          Set<Polygon> polygons = {
            Polygon(
              polygonId: PolygonId(properties['name'] ?? 'barangay'),
              points: boundaryPoints.map((point) => LatLng(point.latitude, point.longitude)).toList(),
              fillColor: const Color(0xFF6A89A7).withOpacity(0.3),
              strokeColor: const Color(0xFF6A89A7),
              strokeWidth: 3,
            ),
          };

          if (mounted) {
            setState(() {
              boundary = boundaryPoints;
              center = calculatedCenter;
              _boundaryPolygons = polygons;
            });
          }
          return;
        }
      }
    } catch (e) {
      print("❌ Error loading GeoJSON: $e");
    }
  }

  bool _isPointInPolygon(latlong2.LatLng point, List<latlong2.LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) /
                  (polygon[j].latitude - polygon[i].latitude) +
              polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }


  void _onGoogleMapTap(LatLng point) {
    // Convert Google Maps LatLng to latlong2.LatLng
    latlong2.LatLng latlongPoint = latlong2.LatLng(point.latitude, point.longitude);
    bool isInside = _isPointInPolygon(latlongPoint, boundary);
    
    if (isInside) {
      // Only update if location actually changed
      if (selectedLocation == null || 
          selectedLocation!.latitude != latlongPoint.latitude || 
          selectedLocation!.longitude != latlongPoint.longitude) {
        setState(() {
          selectedLocation = latlongPoint;
          isOutsideBoundary = false;
        });
        _updateMarkers();
      }
    } else {
      setState(() {
        isOutsideBoundary = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location within your barangay boundary."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onFullscreenMapTap(LatLng point) {
    // Convert Google Maps LatLng to latlong2.LatLng
    latlong2.LatLng latlongPoint = latlong2.LatLng(point.latitude, point.longitude);
    bool isInside = _isPointInPolygon(latlongPoint, boundary);
    
    if (isInside) {
      // Only update if location actually changed
      if (selectedLocation == null || 
          selectedLocation!.latitude != latlongPoint.latitude || 
          selectedLocation!.longitude != latlongPoint.longitude) {
        selectedLocation = latlongPoint;
        _updateMarkers();
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location selected successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate back to main screen after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location within your barangay boundary."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateMarkers() {
    if (selectedLocation != null) {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(selectedLocation!.latitude, selectedLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Your home location',
          ),
        ),
      };
    } else {
      _markers = {};
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable location services in your device settings.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Please enable location permissions to use this feature.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied. Please enable in app settings.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // If we get here, permission is granted
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? '';
        
        // Check if user is in Dasmariñas
        if (city.toLowerCase().contains('dasmariñas') ||
            city.toLowerCase().contains('dasmarinas')) {
          latlong2.LatLng currentLocation = latlong2.LatLng(position.latitude, position.longitude);
          
          // Check if location is within barangay boundary
          bool isInside = _isPointInPolygon(currentLocation, boundary);
          
          if (isInside) {
            // Only update if location actually changed
            if (selectedLocation == null || 
                selectedLocation!.latitude != currentLocation.latitude || 
                selectedLocation!.longitude != currentLocation.longitude) {
              setState(() {
                selectedLocation = currentLocation;
                isOutsideBoundary = false;
              });
              _updateMarkers();
            }
            
            // Animate camera to current location
            _embeddedMapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(currentLocation.latitude, currentLocation.longitude),
                15.0,
              ),
            );
            _googleMapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(currentLocation.latitude, currentLocation.longitude),
                15.0,
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location set successfully: ${place.subLocality ?? place.locality}'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your current location is outside your barangay boundary. Please select a location within your barangay.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be in Dasmariñas to use this feature.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  String _buildFullAddress() {
    List<String> addressParts = [];
    
    if (_blockLotController.text.trim().isNotEmpty) {
      addressParts.add(_blockLotController.text.trim());
    }
    if (_streetSubdivisionController.text.trim().isNotEmpty) {
      addressParts.add(_streetSubdivisionController.text.trim());
    }
    
    // Always add barangay and city
    addressParts.add("Brgy. ${widget.userData['barangayName']}");
    addressParts.add("Dasmariñas, Cavite");
    
    return addressParts.join(", ");
  }

  Widget _buildFullscreenMap() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFBDDDFC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: Text(
          'Select Home Location',
          style: TextStyle(
            fontSize: Responsive.font(context, 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoadingLocation ? null : _checkLocationPermission,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
                    ),
                  )
                : const Icon(Icons.my_location, color: Color(0xFF2C3E50)),
            tooltip: 'Get Current Location',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFBDDDFC),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
          // Ensure markers are updated for full screen map
          _updateMarkers();
          
          if (selectedLocation != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(selectedLocation!.latitude, selectedLocation!.longitude),
                MapService.defaultZoom,
              ),
            );
          } else if (center != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(center!.latitude, center!.longitude),
                MapService.defaultZoom,
              ),
            );
          }
        },
        initialCameraPosition: CameraPosition(
          target: selectedLocation != null 
              ? LatLng(selectedLocation!.latitude, selectedLocation!.longitude)
              : center != null 
                  ? LatLng(center!.latitude, center!.longitude)
                  : const LatLng(MapService.defaultLat, MapService.defaultLng),
          zoom: MapService.defaultZoom,
        ),
        minMaxZoomPreference: const MinMaxZoomPreference(
          MapService.minZoom,
          MapService.maxZoom,
        ),
        onTap: _onFullscreenMapTap,
        polygons: _boundaryPolygons,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
      ),
    );
  }

  void _goToNextPage() async {
    if (_isNavigating) return;
    setState(() { _isNavigating = true; });
    if (selectedLocation == null || _blockLotController.text.isEmpty || _streetSubdivisionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your home location and enter your Block and Lot, and Street Name/Subdivision."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _isNavigating = false; });
      return;
    }

    // Navigate to proof of residency page with all user data, address, and coordinates
    context.push('/proof-of-residency', extra: {
      ...widget.userData,
      'latitude': selectedLocation!.latitude,
      'longitude': selectedLocation!.longitude,
      'address': _buildFullAddress(),
      'block_lot': _blockLotController.text.trim(),
      'street_subdivision': _streetSubdivisionController.text.trim(),
    });
    setState(() { _isNavigating = false; });
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool obscure, {TextInputType? keyboardType}) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.vertical(context, 15)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType ?? TextInputType.text,
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            color: const Color(0xFF2C3E50),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFFADB5BD),
              fontSize: Responsive.font(context, 16),
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6C757D),
              size: Responsive.icon(context, 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 16),
              vertical: Responsive.vertical(context, 16),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFBDDDFC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      backgroundColor: const Color(0xFFBDDDFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, 20),
                vertical: Responsive.vertical(context, 20),
              ),
              child: Row(
                children: [
                  Container(
                    width: Responsive.horizontal(context, 50),
                    height: Responsive.vertical(context, 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BuzzOffPH',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 24),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Set Your Home Location',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 14),
                            color: const Color(0xFF7F8C8D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Map Section Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _isLoadingLocation ? null : _checkLocationPermission,
                    icon: _isLoadingLocation
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A89A7)),
                            ),
                          )
                        : Icon(Icons.my_location, color: Color(0xFF6A89A7), size: 20),
                    label: Text(
                      "Current Location",
                      style: TextStyle(
                        color: Color(0xFF6A89A7),
                        fontSize: Responsive.font(context, 14),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 8)),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _buildFullscreenMap(),
                        ),
                      );
                      setState(() {
                        if (selectedLocation != null) {
                          _embeddedMapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(selectedLocation!.latitude, selectedLocation!.longitude),
                              15.0,
                            ),
                          );
                        }
                      });
                    },
                    icon: Icon(Icons.fullscreen, color: Color(0xFF6A89A7), size: 20),
                    label: Text(
                      "Full Screen",
                      style: TextStyle(
                        color: Color(0xFF6A89A7),
                        fontSize: Responsive.font(context, 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 10)),
            // Map (fixed height, always interactive)
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _embeddedMapController = controller;
                    _updateMarkers();
                  },
                  initialCameraPosition: CameraPosition(
                    target: selectedLocation != null 
                        ? LatLng(selectedLocation!.latitude, selectedLocation!.longitude)
                        : center != null 
                            ? LatLng(center!.latitude, center!.longitude)
                            : const LatLng(MapService.defaultLat, MapService.defaultLng),
                    zoom: MapService.defaultZoom,
                  ),
                  minMaxZoomPreference: const MinMaxZoomPreference(
                    MapService.minZoom,
                    MapService.maxZoom,
                  ),
                  onTap: _onGoogleMapTap,
                  polygons: _boundaryPolygons,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                ),
              ),
            ),
            // Form and buttons (scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.padding(context, 20),
                    vertical: Responsive.vertical(context, 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Fields
                      Text(
                        "Home Address Details",
                        style: TextStyle(
                          fontSize: Responsive.font(context, 18),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: Responsive.vertical(context, 16)),
                      _buildTextField("Block and Lot (e.g., Blk 5 Lt 10)", Icons.home_outlined, _blockLotController, false),
                      _buildTextField("Street Name and/or Subdivision", Icons.streetview_outlined, _streetSubdivisionController, false),
                      SizedBox(height: Responsive.vertical(context, 30)),
                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: Responsive.vertical(context, 50),
                        child: ElevatedButton(
                          onPressed: _isNavigating ? null : _goToNextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A89A7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            "Next",
                            style: TextStyle(
                              fontSize: Responsive.font(context, 16),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.vertical(context, 60)), // safe space at the bottom
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
