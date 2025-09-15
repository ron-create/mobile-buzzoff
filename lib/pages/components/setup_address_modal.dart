import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SetupAddressModal extends StatefulWidget {
  final String barangayName;
  final LatLng? initialLocation; // Previously selected location
final Function(String barangayName, LatLng location, String address) onLocationSelected;


  const SetupAddressModal({
    super.key,
    required this.barangayName,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  _BarangayMapModalState createState() => _BarangayMapModalState();
}

class _BarangayMapModalState extends State<SetupAddressModal> {
  LatLng? center;
  List<LatLng> boundary = [];
  LatLng? selectedLocation;
  late MapController _mapController;
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    selectedLocation = widget.initialLocation;
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

        if (properties['name'].toLowerCase() == widget.barangayName.toLowerCase()) {
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
            });
          }
          return;
        }
      }
    } catch (e) {
      print("❌ Error loading GeoJSON: $e");
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      selectedLocation = point;
    });
  }

  void _saveLocation() {
    if (selectedLocation != null && addressController.text.isNotEmpty) {
      widget.onLocationSelected(widget.barangayName, selectedLocation!, addressController.text);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a location and enter an address.")),
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
                    widget.barangayName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: (center == null || boundary.isEmpty)
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
                              points: boundary,
                              color: Colors.blue.withOpacity(0.5),
                              borderColor: Colors.black,
                              borderStrokeWidth: 3,
                            ),
                          ],
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

            // Selected Location & Address Field
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  if (selectedLocation != null)
                    Text(
                      "📍 ${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                ],
              ),
            ),

            // Save Button
            Padding(
              padding: EdgeInsets.all(10),
              child: ElevatedButton.icon(
                onPressed: _saveLocation,
                icon: Icon(Icons.save),
                label: Text("Save Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
