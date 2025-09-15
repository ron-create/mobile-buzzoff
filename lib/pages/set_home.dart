import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../actions/setup_account_actions.dart';
import '../utils/responsive.dart';

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
  LatLng? selectedLocation;
  List<LatLng> boundary = [];
  LatLng? center;
  late MapController _mapController;
  bool isOutsideBoundary = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _blockLotController.dispose();
    _streetSubdivisionController.dispose();
    _mapController.dispose();
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

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    bool isInside = _isPointInPolygon(point, boundary);
    
    setState(() {
      isOutsideBoundary = !isInside;
      if (isInside) {
        selectedLocation = point;
        // Remove auto-center - let user control the map
      }
    });

    if (!isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select a location within your barangay boundary."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.35 + 20,
            left: 16,
            right: 16,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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

  void _goToNextPage() async {
    if (_isNavigating) return;
    setState(() { _isNavigating = true; });
    if (selectedLocation == null || _blockLotController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your home location and enter your Block and Lot."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _isNavigating = false; });
      return;
    }

    // Navigate to proof of residency page with all user data, address, and coordinates
    context.go('/proof-of-residency', extra: {
      ...widget.userData,
      'latitude': selectedLocation!.latitude,
      'longitude': selectedLocation!.longitude,
      'address': _buildFullAddress(),
      'block_lot': _blockLotController.text.trim(),
      'street_subdivision': _streetSubdivisionController.text.trim(),
    });
    setState(() { _isNavigating = false; });
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
        child: (center == null || boundary.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : Column(
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

                  SizedBox(height: Responsive.vertical(context, 20)),

                  // Map Section
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
                      child: FlutterMap(
                        key: ValueKey(selectedLocation?.toString() ?? 'no-location'),
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: selectedLocation ?? center!,
                          initialZoom: 15,
                          minZoom: 13,
                          maxZoom: 18,
                          onTap: _onMapTap,
                          onMapEvent: (MapEvent event) {
                            // No auto-center logic here, let user control the map
                          },
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
                                color: const Color(0xFF6A89A7).withOpacity(0.3),
                                borderColor: const Color(0xFF6A89A7),
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
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Form Section
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Responsive.padding(context, 20)),
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
                          
                          buildTextField("Block and Lot (e.g., Blk 5 Lt 10)", Icons.home_outlined, _blockLotController, false),
                          buildTextField("Street Name and/or Subdivision", Icons.streetview_outlined, _streetSubdivisionController, false),
                          
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
                          
                          SizedBox(height: Responsive.vertical(context, 40)), // safe space at the bottom
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildTextField(String hint, IconData icon, TextEditingController controller, bool obscure, {TextInputType? keyboardType}) {
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
}
