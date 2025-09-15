import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../actions/breeding_site_actions.dart';
import '../../utils/responsive.dart';

class BreedingSite extends StatefulWidget {
  const BreedingSite({super.key});

  @override
  _BreedingSiteState createState() => _BreedingSiteState();
}

class _BreedingSiteState extends State<BreedingSite> {
  final TextEditingController _descriptionController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedBarangay;
  List<File> _selectedMedia = [];
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  // Google Maps variables
  GoogleMapController? _mapController; // ignore: unused_field
  GoogleMapController? _fullscreenController; // ignore: unused_field
  Set<Polygon> _boundaryPolygons = {};
  Set<Marker> _markers = {};
  Map<String, dynamic> _barangayJson = {};
  bool _isMapLoading = true;

  // Dasmarinas bounds for Google Maps
  static final LatLngBounds _dasmarinasBounds = LatLngBounds(
    southwest: const LatLng(14.25, 120.90),
    northeast: const LatLng(14.40, 121.05),
  );

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      setState(() => _isMapLoading = true);

      // Load barangay GeoJSON
      final String barangayData = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      _barangayJson = json.decode(barangayData);

      // Convert GeoJSON to polygons
      _boundaryPolygons = _convertGeoJsonToPolygons(_barangayJson);

      // Initialize markers if location is already set
      if (_selectedLocation != null) {
        _updateMarkers();
      }

      setState(() => _isMapLoading = false);
    } catch (e) {
      debugPrint('Error loading map data: $e');
      setState(() => _isMapLoading = false);
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

        polygons.add(
          Polygon(
            polygonId: PolygonId(properties['name'] ?? 'unknown'),
            points: boundaryPoints,
            fillColor: Colors.transparent,
            strokeColor: Colors.black.withOpacity(0.7),
            strokeWidth: 2,
          ),
        );
      }
    }

    return polygons;
  }

  Future<void> _onMapTap(LatLng point) async {
    // Check if location is within Dasmarinas bounds
    if (!_dasmarinasBounds.contains(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location within Dasmarinas.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Update location and markers
    _selectedLocation = point;
    _selectedBarangay = _getBarangayFromLocation(point);
    _updateMarkers();

    // Animate camera to new location in both maps
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(point, 15.0),
      );
    }
    if (_fullscreenController != null) {
      _fullscreenController!.animateCamera(
        CameraUpdate.newLatLngZoom(point, 15.0),
      );
    }

    // Call the update location callback
    _updateLocation(point, _selectedBarangay!);
  }

  String _getBarangayFromLocation(LatLng point) {
    final features = _barangayJson['features'] as List;

    for (var feature in features) {
      final geometry = feature['geometry'];

      if (geometry['type'] == 'Polygon') {
        List coordinates = geometry['coordinates'][0];
        List<LatLng> boundaryPoints = coordinates.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();

        if (_isPointInPolygon(point, boundaryPoints)) {
          return feature['properties']['name'] ?? 'Unknown Barangay';
        }
      }
    }

    return 'Unknown Barangay';
  }

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

  void _updateMarkers() {
    _markers = {
      if (_selectedLocation != null)
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _selectedBarangay ?? 'Unknown Barangay',
          ),
        ),
    };
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
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _selectedBarangay = place.subLocality ?? place.locality ?? 'Unknown Location';
          _updateMarkers();
          
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
              content: Text('You must be in Dasmariñas to use this feature.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _selectedLocation = null;
          _selectedBarangay = null;
          _updateMarkers();
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

  void _updateLocation(LatLng newLocation, String barangay) {
    _selectedLocation = newLocation;
    _selectedBarangay = barangay;
    _updateMarkers();
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      final XFile? media;
      if (isVideo) {
        media = await _picker.pickVideo(source: source);
      } else {
        media = await _picker.pickImage(source: source);
      }

      if (media != null && media.path.isNotEmpty) {
        setState(() {
          _selectedMedia.add(File(media!.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking media: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMediaPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: EdgeInsets.all(Responsive.padding(context, 20)),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Media',
                style: TextStyle(
                  fontSize: Responsive.font(context, 20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF384949),
                ),
              ),
              SizedBox(height: Responsive.vertical(context, 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(ImageSource.camera, false);
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(ImageSource.gallery, false);
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.videocam,
                    label: 'Record Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(ImageSource.camera, true);
                    },
                  ),
                ],
              ),
              SizedBox(height: Responsive.vertical(context, 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            decoration: BoxDecoration(
              color: const Color(0xFF3A4A5A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3A4A5A),
              size: Responsive.icon(context, 32),
            ),
          ),
          SizedBox(height: Responsive.vertical(context, 8)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.font(context, 12),
              color: const Color(0xFF384949),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(File media, int index) {
    if (media.path.endsWith('.mp4') || media.path.endsWith('.mov')) {
      return Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            media,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _showResultModal({
    required bool isSuccess,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF384949),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isSuccess) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : const Color(0xFF3A4A5A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(
                    isSuccess ? "Done" : "Try Again",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (_selectedLocation == null || _selectedBarangay == null || _selectedMedia.isEmpty || _descriptionController.text.trim().isEmpty) {
      _showResultModal(
        isSuccess: false,
        title: "Incomplete Information",
        message: "Please complete all required fields before submitting.",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check daily report limit first
      await BreedingSiteActions.checkDailyReportLimit(context);

      // Convert Google Maps LatLng to latlong2.LatLng
      final latlong2.LatLng? convertedLocation = _selectedLocation != null
          ? latlong2.LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude)
          : null;

      await BreedingSiteActions.submitReport(
        context,
        convertedLocation,
        _selectedBarangay,
        _selectedMedia,
        _descriptionController,
        () {
          _showResultModal(
            isSuccess: true,
            title: "Success",
            message: "Your breeding site report has been submitted successfully!",
          );
        },
      );
    } catch (e) {
      String errorMessage = "Failed to submit report. Please try again.";
      if (e.toString().contains("maximum limit of 3 reports per day")) {
        errorMessage = "You have reached the maximum limit of 3 reports per day. Please try again tomorrow.";
      }
      _showResultModal(
        isSuccess: false,
        title: "Error",
        message: errorMessage,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
    });
    }
  }

  Widget _buildFullscreenMap() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Select Location', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: StatefulBuilder(
        builder: (context, setFullscreenState) => GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _fullscreenController = controller;
            if (_selectedLocation != null) {
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
              );
            } else {
              // Default to Dasmariñas center
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(const LatLng(14.3297, 120.9372), 13.0),
              );
            }
          },
          initialCameraPosition: CameraPosition(
            target: _selectedLocation ?? const LatLng(14.3297, 120.9372),
            zoom: _selectedLocation != null ? 15.0 : 13.0,
        ),
          minMaxZoomPreference: const MinMaxZoomPreference(12.0, 18.0),
          onTap: (point) async {
            await _onMapTap(point);
            setFullscreenState(() {}); // Rebuild only fullscreen map
          },
          polygons: _boundaryPolygons,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  Widget _buildEmbeddedGoogleMap() {
    if (_isMapLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3A4A5A),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setEmbeddedState) => GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          if (_selectedLocation != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
            );
          }
        },
        initialCameraPosition: CameraPosition(
          target: _selectedLocation ?? const LatLng(14.3297, 120.9372),
          zoom: 13.0,
        ),
        minMaxZoomPreference: const MinMaxZoomPreference(12.0, 18.0),
        onTap: (point) async {
          await _onMapTap(point);
          setEmbeddedState(() {}); // Rebuild only embedded map
        },
        polygons: _boundaryPolygons,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        zoomControlsEnabled: false,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(""), // Empty title, just back button
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
              "Please provide accurate details about the breeding site to help us address it promptly. Your report will help prevent potential dengue outbreaks.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.justify,
            ),
              const SizedBox(height: 24),
            
            // Location Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            Text(
              "Location",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _isLoadingLocation ? null : _checkLocationPermission,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A4A5A)),
                                ),
                              )
                            : const Icon(Icons.my_location, color: Color(0xFF3A4A5A)),
                        label: Text(
                          "Current Location",
                          style: TextStyle(color: Color(0xFF3A4A5A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _buildFullscreenMap(),
                            ),
                          );
                          // Force rebuild of embedded map when returning from fullscreen
                          setState(() {});
                        },
                        icon: const Icon(Icons.fullscreen, color: Color(0xFF3A4A5A)),
                        label: const Text(
                          "Full Screen",
                          style: TextStyle(color: Color(0xFF3A4A5A)),
                        ),
                      ),
                    ],
                  ),
                ],
            ),
            const SizedBox(height: 10),
            Container(
                height: MediaQuery.of(context).size.height * 0.35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildEmbeddedGoogleMap(),
              ),
            ),
            if (_selectedBarangay != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A4A5A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3A4A5A).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF3A4A5A), size: 20),
                      const SizedBox(width: 8),
              Text(
                "Selected Barangay: $_selectedBarangay",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
            ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Media Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            Text(
                    "Photos & Videos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
                  ),
                  TextButton.icon(
                    onPressed: _showMediaPickerModal,
                    icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF3A4A5A)),
                    label: const Text(
                      "Add Media",
                      style: TextStyle(color: Color(0xFF3A4A5A)),
                    ),
                  ),
                ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232E3F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (_selectedMedia.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "No media selected",
                      style: TextStyle(
                                color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                          ],
                        ),
                      )
                    else
                    SizedBox(
                        height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                          itemCount: _selectedMedia.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                              child: _buildMediaPreview(_selectedMedia[index], index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

            // Description Section
            Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232E3F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
              ),
              child: TextField(
                controller: _descriptionController,
                  decoration: InputDecoration(
                  hintText: "Enter a detailed description of the breeding site...",
                  border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: Colors.white,
                    hintStyle: TextStyle(color: Colors.black),
                ),
                maxLines: 4,
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 100),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Report',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A4A5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
            ),
        ),
      ),
    );
  }
}
