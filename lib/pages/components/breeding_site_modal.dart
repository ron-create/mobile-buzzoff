import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BreedingSiteModal extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String?) onLocationSelected;

  const BreedingSiteModal({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  _BreedingSiteModalState createState() => _BreedingSiteModalState();
}

class _BreedingSiteModalState extends State<BreedingSiteModal> {
  LatLng? center;
  List<LatLng> cityBoundary = [];
  List<Map<String, dynamic>> barangayBoundaries = [];
  LatLng? selectedLocation;
  String? selectedBarangay;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    selectedLocation = widget.initialLocation;
    _loadGeoJsonData();
  }

  Future<void> _loadGeoJsonData() async {
    try {
      // Load city boundary
      final String cityGeoJsonString = await rootBundle.loadString('assets/geojson/dasma.geojson');
      final cityGeoJsonData = json.decode(cityGeoJsonString);

      final cityFeatures = cityGeoJsonData['features'] as List;
      for (var feature in cityFeatures) {
        final geometry = feature['geometry'];
        if (geometry['type'] == 'Polygon') {
          List coordinates = geometry['coordinates'][0];

          List<LatLng> boundaryPoints = coordinates.map((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList();

          LatLng calculatedCenter = _calculateCenter(boundaryPoints);

          if (mounted) {
            setState(() {
              cityBoundary = boundaryPoints;
              center = calculatedCenter;
            });
          }
        }
      }

      // Load barangay boundaries
      final String barangayGeoJsonString = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      final barangayGeoJsonData = json.decode(barangayGeoJsonString);

      final barangayFeatures = barangayGeoJsonData['features'] as List;
      List<Map<String, dynamic>> allBarangayBoundaries = [];

      for (var feature in barangayFeatures) {
        final geometry = feature['geometry'];
        final String barangayName = feature['properties']['name'] ?? 'Unknown';

        if (geometry['type'] == 'Polygon') {
          List coordinates = geometry['coordinates'][0];

          List<LatLng> boundaryPoints = coordinates.map((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList();

          allBarangayBoundaries.add({
            'name': barangayName,
            'boundary': boundaryPoints,
          });
        }
      }

      if (mounted) {
        setState(() {
          barangayBoundaries = allBarangayBoundaries;
        });
      }
    } catch (e) {
      print("❌ Error loading GeoJSON: $e");
    }
  }

  /// Calculates the center of given polygon points.
  LatLng _calculateCenter(List<LatLng> points) {
    double latSum = 0, lngSum = 0;
    for (var point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  /// Checks if a point is inside a polygon (Ray-Casting Algorithm)
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1;
    bool inside = false;

    for (i = 0; i < polygon.length; i++) {
      double xi = polygon[i].longitude, yi = polygon[i].latitude;
      double xj = polygon[j].longitude, yj = polygon[j].latitude;

      bool intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  /// Handles map tap event to select a location and detect barangay
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    String? detectedBarangay;

    for (var barangay in barangayBoundaries) {
      if (_isPointInPolygon(point, barangay['boundary'])) {
        detectedBarangay = barangay['name'];
        break;
      }
    }

    setState(() {
      selectedLocation = point;
      selectedBarangay = detectedBarangay;
    });
  }

  void _saveLocation() {
    if (selectedLocation != null) {
      Navigator.pop(context, {
        "location": selectedLocation,
        "barangay": selectedBarangay,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a location first!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Breeding Site",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Map View
            Expanded(
              child: (center == null || cityBoundary.isEmpty)
                  ? Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: selectedLocation ?? center!,
                        initialZoom: 15,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: cityBoundary,
                              color: Colors.blue.withOpacity(0.3),
                              borderColor: Colors.black,
                              borderStrokeWidth: 3,
                            ),
                          ],
                        ),
                        PolygonLayer(
                          polygons: barangayBoundaries.map((barangay) {
                            return Polygon(
                              points: barangay['boundary'],
                              color: Colors.green.withOpacity(0.3),
                              borderColor: Colors.black,
                              borderStrokeWidth: 2,
                            );
                          }).toList(),
                        ),
                        if (selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40.0,
                                height: 40.0,
                                point: selectedLocation!,
                                child: Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),

            if (selectedLocation != null)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "📍 ${selectedBarangay ?? 'Unknown Barangay'}\n${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _saveLocation,
                icon: Icon(Icons.save),
                label: Text("Save Location"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
