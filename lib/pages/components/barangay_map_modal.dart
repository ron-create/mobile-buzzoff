import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class BarangayMapModal extends StatefulWidget {
  final String barangayName;
  final latlong2.LatLng? initialLocation;
  final Function(latlong2.LatLng) onLocationSelected;

  const BarangayMapModal({
    super.key,
    required this.barangayName,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  _BarangayMapModalState createState() => _BarangayMapModalState();
}

class _BarangayMapModalState extends State<BarangayMapModal> {
  LatLng? center;
  List<LatLng> boundary = [];
  LatLng? selectedLocation;
  GoogleMapController? _mapController;
  bool isLocationInBoundary = true;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      // Set initial boundary check
      isLocationInBoundary = true; // Will be properly checked when boundary loads
    }
    _loadBarangayData();
  }

  Future<void> _loadBarangayData() async {
    try {
      final String geojsonString = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      final geojsonData = json.decode(geojsonString);

      final features = geojsonData['features'] as List;
      for (var feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties['name'] == widget.barangayName) {
          List coordinates = geometry['coordinates'][0];
          List<LatLng> boundaryPoints = coordinates.map((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList();

          double latSum = 0, lngSum = 0;
          for (var point in boundaryPoints) {
            latSum += point.latitude;
            lngSum += point.longitude;
          }
          LatLng calculatedCenter = LatLng(latSum / boundaryPoints.length, lngSum / boundaryPoints.length);

          if (mounted) {
            setState(() {
              boundary = boundaryPoints;
              center = calculatedCenter;
              _updateMapElements();
            });
          }
          return;
        }
      }
    } catch (e) {
      print("❌ Error loading GeoJSON: $e");
    }
  }

  void _updateMapElements() {
    // Update polygons
    _polygons = {
      Polygon(
        polygonId: const PolygonId('barangay_boundary'),
        points: boundary,
        fillColor: const Color(0xFF6A89A7).withOpacity(0.3),
        strokeColor: const Color(0xFF384949),
        strokeWidth: 2,
      ),
    };

    // Update markers
    _markers = {};
    if (selectedLocation != null) {
      // Check if location is within boundary
      bool isInBoundary = _isPointInPolygon(selectedLocation!, boundary);
      isLocationInBoundary = isInBoundary;
      
      if (isInBoundary) {
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: selectedLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Selected Location'),
          ),
        );
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

  void _onMapTap(LatLng point) {
    bool isInBoundary = _isPointInPolygon(point, boundary);
    setState(() {
      selectedLocation = isInBoundary ? point : null;
      isLocationInBoundary = isInBoundary;
    });
    
    // Update markers and polygons immediately
    _updateMapElements();

    if (!isInBoundary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location within the barangay boundary"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
                  appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Select Location - ${widget.barangayName}',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (selectedLocation != null && isLocationInBoundary)
              TextButton(
                onPressed: () {
                  widget.onLocationSelected(latlong2.LatLng(
                    selectedLocation!.latitude,
                    selectedLocation!.longitude,
                  ));
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save Location',
                  style: TextStyle(color: Color(0xFF3A4A5A), fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
          body: _buildFullScreenMap(),
        ),
      ),
    );
  }

  Widget _buildFullScreenMap() {
    return StatefulBuilder(
      builder: (context, setFullscreenState) => Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (selectedLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(selectedLocation!, 15.0),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? center ?? const LatLng(14.4791, 120.8969),
              zoom: 15.0,
            ),
            onTap: (point) {
              _onMapTap(point);
              setFullscreenState(() {}); // Rebuild only fullscreen map
            },
            markers: _markers,
            polygons: _polygons,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
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
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black),
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.zoomIn(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.black),
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.zoomOut(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        ],
      ),
    );
  }

  void _saveLocation() {
    if (selectedLocation != null && isLocationInBoundary) {
      widget.onLocationSelected(latlong2.LatLng(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid location within the barangay boundary"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23272F) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A4A5A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Location",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.barangayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () => _showFullScreenMap(),
                        tooltip: 'Full Screen',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Reminder
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF3A4A5A).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF3A4A5A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Only set a new location if you are in a different area within the barangay. The pin must be placed within the highlighted boundary.",
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A4A5A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: (center == null || boundary.isEmpty)
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation ?? center!,
                        zoom: 15.0,
                      ),
                      onTap: _onMapTap,
                      markers: _markers,
                      polygons: _polygons,
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
            ),

            // Location Details and Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23272F) : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveLocation,
                      icon: Icon(
                        selectedLocation != null && isLocationInBoundary 
                            ? Icons.check_circle 
                            : Icons.save, 
                        color: Colors.white
                      ),
                      label: Text(
                        selectedLocation != null && isLocationInBoundary 
                            ? "Saved Location" 
                            : "Save Location", 
                        style: TextStyle(color: Colors.white)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedLocation != null && isLocationInBoundary 
                            ? Colors.green 
                            : const Color(0xFF3A4A5A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
