import 'package:flutter/material.dart';
import '../../actions/dengue_case_actions.dart';
import '../components/barangay_map_modal.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DengueCase extends StatefulWidget {
  const DengueCase({super.key});

  @override
  _DengueCaseState createState() => _DengueCaseState();
}

class _DengueCaseState extends State<DengueCase> {
  final DengueCaseActions _actions = DengueCaseActions();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _homeAddressController = TextEditingController();
  final TextEditingController _streetNameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? residentId;
  String? barangayId;
  String? barangayName;
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic>? residentData;
  List<Map<String, dynamic>> _availableVehicles = [];
  List<Map<String, dynamic>> _allBarangays = [];
  String? _selectedVehicleId;
  String? _selectedBarangayId;
  String? _selectedBarangayName;
  String? _selectedRelationship;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _showVehicleRequest = false;
  bool _isReportingForSelf = true;
  bool _isLocationSaved = false;

  // Bottom sheet map cache
  Set<gmap.Polygon> _sheetPolygons = {};
  List<gmap.LatLng> _sheetBoundary = [];
  Set<gmap.Marker> _sheetMarkers = {};
  gmap.LatLng? _sheetTempPoint;

  @override
  void initState() {
    super.initState();
    _fetchResidentDetails();
    _loadAvailableVehicles();
    _loadAllBarangays();
  }

  Future<void> _loadAllBarangays() async {
    try {
      final response = await Supabase.instance.client
          .from('barangay')
          .select('id, name')
          .order('name');

      setState(() {
        _allBarangays = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      debugPrint('Error loading barangays: $error');
    }
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, // Fixed height for both cards
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3A4A5A).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF3A4A5A) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF3A4A5A) : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF3A4A5A) : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(0xFF3A4A5A).withOpacity(0.8) : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _selectReportingType(bool isSelf) {
    setState(() {
      _isReportingForSelf = isSelf;
      if (isSelf) {
        if (residentData != null) {
          _firstNameController.text = residentData!['first_name'] ?? '';
          _middleNameController.text = residentData!['middle_name'] ?? '';
          _lastNameController.text = residentData!['last_name'] ?? '';
          _suffixController.text = residentData!['suffix_name'] ?? '';
          _dateOfBirthController.text = residentData!['date_of_birth'] ?? '';
          _sexController.text = residentData!['sex'] ?? '';
          _phoneController.text = residentData!['phone'] ?? '';
        }
        _loadAvailableVehicles();
      } else {
        _firstNameController.clear();
        _middleNameController.clear();
        _lastNameController.clear();
        _suffixController.clear();
        _dateOfBirthController.clear();
        _sexController.clear();
        _phoneController.clear();
        _homeAddressController.clear();
        _streetNameController.clear();
        _selectedBarangayId = null;
        _selectedBarangayName = null;
        _selectedRelationship = null;
        _availableVehicles = [];
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A4A5A),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _selectedVehicleId == null ? Colors.grey.shade100 : Colors.white,
            border: Border.all(color: Color(0xFF3A4A5A).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedVehicleId,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF3A4A5A)),
              dropdownColor: Colors.white,
              items: _availableVehicles.map((vehicle) {
                return DropdownMenuItem<String>(
                  value: vehicle['id'] as String,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          vehicle['name'] ?? 'Unknown Vehicle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4A5A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${vehicle['plate_no'] ?? 'N/A'})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    return Row(
      children: [
                                    Expanded(
                              child: ElevatedButton(
                                onPressed: _selectDate,
                                child: Text(
                                  _selectedDate == null
                                      ? 'Select Date'
                                      : DateFormat('MMM d, y').format(_selectedDate!),
                                ),
                                        style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3A4A5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectTime,
                            child: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3A4A5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical:8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
      ],
    );
  }

  Widget _buildDestinationFields() {
    return Column(
      children: [
        // Reason for Request
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF3A4A5A).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Reason for Request',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Destination
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF3A4A5A).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              labelText: 'Destination',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Additional Remarks
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF3A4A5A).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TextField(
            controller: _remarksController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Additional Remarks',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    TextInputType? keyboardType,
    IconData? icon,
    int? maxLines,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        readOnly: readOnly,
        enabled: !readOnly,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: icon != null ? Icon(icon, color: Color(0xFF5271FF)) : null,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Theme.of(context).colorScheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _openMapModal() {
    // Use selected barangay for others, or resident's barangay for self
    String targetBarangayName = _isReportingForSelf 
        ? (barangayName ?? 'Unknown')
        : (_selectedBarangayName ?? 'Unknown');
        
    _prepareSheetPolygon(targetBarangayName).then((_) {
      showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                // polygons and boundary now preloaded into _sheetPolygons/_sheetBoundary

                gmap.LatLng initialCenter = const gmap.LatLng(14.3297, 120.9372);
                if (residentData?['latitude'] != null && residentData?['longitude'] != null) {
                  final lat = double.tryParse(residentData!['latitude'].toString());
                  final lng = double.tryParse(residentData!['longitude'].toString());
                  if (lat != null && lng != null) {
                    initialCenter = gmap.LatLng(lat, lng);
                  }
                }

                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header with current location
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Location in $targetBarangayName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A4A5A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final pos = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
                                final current = gmap.LatLng(pos.latitude, pos.longitude);
                                if (_sheetBoundary.isNotEmpty && !_pointInPolygonGmap(current, _sheetBoundary)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('You are not in the selected barangay.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                _sheetTempPoint = current;
                                setSheetState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pin set to current location.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error getting location: ${e.toString()}'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            icon: const Icon(Icons.my_location, color: Color(0xFF3A4A5A)),
                            label: const Text('Current Location', style: TextStyle(color: Color(0xFF3A4A5A))),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Color(0xFF3A4A5A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Map content
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: gmap.GoogleMap(
                          initialCameraPosition: gmap.CameraPosition(target: initialCenter, zoom: 14.0),
                          polygons: _sheetPolygons,
                          markers: _sheetTempPoint != null ? { gmap.Marker(
                            markerId: const gmap.MarkerId('temp'),
                            position: _sheetTempPoint!,
                            draggable: true,
                            onDragEnd: (p) {
                              if (_sheetBoundary.isNotEmpty && !_pointInPolygonGmap(p, _sheetBoundary)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pin must be inside the selected barangay.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                _sheetTempPoint = p;
                                setSheetState(() {});
                              }
                            },
                          ) } : {},
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          onTap: (point) {
                            if (_sheetBoundary.isNotEmpty && !_pointInPolygonGmap(point, _sheetBoundary)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a location within the selected barangay.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            _sheetTempPoint = point;
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_sheetTempPoint == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please set a pin inside the barangay boundary.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
          setState(() {
                              residentData?['latitude'] = _sheetTempPoint!.latitude.toString();
                              residentData?['longitude'] = _sheetTempPoint!.longitude.toString();
            _isLocationSaved = true;
          });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location saved.'), backgroundColor: Colors.green),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A4A5A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Location', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    });
  }

  Future<void> _prepareSheetPolygon(String targetBarangayName) async {
    try {
      _sheetPolygons = {};
      _sheetBoundary = [];
      final String data = await rootBundle.loadString('assets/geojson/dasmabarangays.geojson');
      final Map<String, dynamic> jsonData = json.decode(data);
      final List features = jsonData['features'] as List;
      for (final feature in features) {
        final props = feature['properties'];
        final geometry = feature['geometry'];
        final name = (props['name'] ?? '').toString();
        if (name.toLowerCase() == targetBarangayName.toLowerCase() && geometry['type'] == 'Polygon') {
          final List coords = geometry['coordinates'][0];
          _sheetBoundary = coords.map<gmap.LatLng>((c) => gmap.LatLng(c[1], c[0])).toList();
          _sheetPolygons = {
            gmap.Polygon(
              polygonId: gmap.PolygonId(name),
              points: _sheetBoundary,
              fillColor: Colors.transparent,
              strokeColor: Colors.black.withOpacity(0.7),
              strokeWidth: 2,
            ),
          };
          break;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _getCurrentLocationAndValidateBarangay(String targetBarangayName) async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      final pos = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
      final placemarks = await geocoding.placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final currentBarangayName = (place?.subLocality ?? place?.locality ?? '').toLowerCase();
      final target = (targetBarangayName).toLowerCase();

      if (currentBarangayName.isNotEmpty && currentBarangayName.contains(target)) {
        setState(() {
          residentData?['latitude'] = pos.latitude.toString();
          residentData?['longitude'] = pos.longitude.toString();
          _isLocationSaved = true;
        });
        if (mounted) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set in $targetBarangayName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not in the selected barangay.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _pointInPolygonGmap(gmap.LatLng point, List<gmap.LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final bool intersect = ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) *
                  (point.latitude - polygon[i].latitude) /
                  (polygon[j].latitude - polygon[i].latitude) +
              polygon[i].longitude);
      if (intersect) isInside = !isInside;
      j = i;
    }
    return isInside;
  }

  Future<void> _loadAvailableVehicles() async {
    try {
      // For self-reporting, use resident's barangay automatically
      if (_isReportingForSelf) {
        final resident = await _actions.fetchResidentDetails();
        final barangayId = resident['barangay_id'];

        final response = await Supabase.instance.client
            .from('vehicles')
            .select()
            .eq('status', 'Available')
            .eq('barangay_id', barangayId)
            .order('name');

        setState(() {
          _availableVehicles = List<Map<String, dynamic>>.from(response);
        });
        
        debugPrint('Loaded ${_availableVehicles.length} vehicles for self-reporting barangay $barangayId');
      }
      // For others, vehicles will be loaded when barangay is selected
    } catch (error) {
      debugPrint('Error loading vehicles: $error');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showDatePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date of Birth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A4A5A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Color(0xFF3A4A5A)),
                  ),
                ],
              ),
            ),
            // Date picker
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CalendarDatePicker(
                initialDate: _dateOfBirthController.text.isNotEmpty 
                    ? DateTime.tryParse(_dateOfBirthController.text) ?? DateTime(2000, 1, 1)
                    : DateTime(2000, 1, 1),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onDateChanged: (date) {
                  setState(() {
                    _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(date);
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchResidentDetails() async {
    try {
      final resident = await _actions.fetchResidentDetails();
      final barangay = await _actions.fetchBarangayName(resident['barangay_id']);
      
      setState(() {
        residentData = resident;
        _firstNameController.text = resident['first_name'] ?? '';
        _middleNameController.text = resident['middle_name'] ?? '';
        _lastNameController.text = resident['last_name'] ?? '';
        _suffixController.text = resident['suffix_name'] ?? '';
        _dateOfBirthController.text = resident['date_of_birth'] ?? '';
        _sexController.text = resident['sex'] ?? '';
        _phoneController.text = resident['phone'] ?? '';
        residentId = resident['id'];
        barangayId = resident['barangay_id'];
        barangayName = barangay;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching resident details: $e");
    }
  }

  void _onBarangaySelected(String barangayId, String barangayName) {
    setState(() {
      _selectedBarangayId = barangayId;
      _selectedBarangayName = barangayName;
    });
    
    // Load vehicles for selected barangay
    _loadVehiclesForBarangay(barangayId);
  }

  Future<void> _loadVehiclesForBarangay(String barangayId) async {
    try {
      final response = await Supabase.instance.client
          .from('vehicles')
          .select()
          .eq('status', 'Available')
          .eq('barangay_id', barangayId)
          .order('name');

      setState(() {
        _availableVehicles = List<Map<String, dynamic>>.from(response);
      });
      
      debugPrint('Loaded ${_availableVehicles.length} vehicles for barangay $barangayId');
    } catch (error) {
      debugPrint('Error loading vehicles for barangay: $error');
    }
  }

  Future<void> _submitDengueReport() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Convert latitude/longitude to double
      double? latitude;
      double? longitude;
      
      if (residentData?['latitude'] != null) {
        latitude = double.tryParse(residentData!['latitude'].toString());
      }
      if (residentData?['longitude'] != null) {
        longitude = double.tryParse(residentData!['longitude'].toString());
      }

      final dengueCase = await _actions.submitDengueCase(
        isReportingForSelf: _isReportingForSelf,
        // For self-reporting
        residentId: _isReportingForSelf ? residentId : null,
        // For reporting others
        firstName: _isReportingForSelf ? null : _firstNameController.text,
        middleName: _isReportingForSelf ? null : _middleNameController.text,
        lastName: _isReportingForSelf ? null : _lastNameController.text,
        suffixName: _isReportingForSelf ? null : _suffixController.text,
        dateOfBirth: _isReportingForSelf ? null : _dateOfBirthController.text,
        sex: _isReportingForSelf ? null : _sexController.text,
        phone: _isReportingForSelf ? null : _phoneController.text,
        barangayId: _isReportingForSelf ? null : _selectedBarangayId,
        homeAddress: _isReportingForSelf ? null : _homeAddressController.text,
        streetName: _isReportingForSelf ? null : _streetNameController.text,
        selectedBarangayName: _isReportingForSelf ? null : _selectedBarangayName,
        relationship: _isReportingForSelf ? null : _selectedRelationship,
        latitude: latitude,
        longitude: longitude,
      );

      if (_showVehicleRequest) {
        if (_selectedDate == null ||
            _selectedTime == null ||
            _selectedVehicleId == null ||
            _reasonController.text.trim().isEmpty ||
            _destinationController.text.trim().isEmpty) {
          setState(() {
            isSubmitting = false;
          });
          _showResultModal(
            isSuccess: false,
            title: "Incomplete Request",
            message: "Please complete the vehicle request details (vehicle, schedule, reason, and destination).",
          );
          return;
        }

        final scheduledTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        await Supabase.instance.client
            .from('vehicle_requests')
            .insert({
              'resident_id': dengueCase['resident_id'],
              'dengue_case_id': dengueCase['id'],
              'reason': _reasonController.text,
              'destination': _destinationController.text,
              'status': 'Pending',
              'requested_at': DateTime.now().toIso8601String(),
              'scheduled_time': scheduledTime.toIso8601String(),
              'vehicle_id': _selectedVehicleId,
              'remarks': _remarksController.text,
            });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Error submitting dengue report: $e");
      String errorMessage = "Failed to submit dengue case. Please try again.";
      if (e.toString().contains("maximum limit of 3 reports per day")) {
        errorMessage = "You have reached the maximum limit of 3 reports per day. Please try again tomorrow.";
      }
      _showResultModal(
        isSuccess: false,
        title: "Error",
        message: errorMessage,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
                    color: isSuccess ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
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
                    backgroundColor: isSuccess ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
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

  Widget _buildVehicleRequestSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: (_showVehicleRequest && _selectedVehicleId == null) ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3A4A5A).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF3A4A5A).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Color(0xFF3A4A5A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                              Text(
                    "Vehicle Request",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                            color: Color(0xFF3A4A5A),
                          ),
                        ),
                      Text(
                        "Request a vehicle for emergency response",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showVehicleRequest,
                  onChanged: (value) {
                    setState(() {
                      _showVehicleRequest = value;
                    });
                    if (value) {
                      _loadAvailableVehicles();
                    }
                  },
                  activeColor: Color(0xFF3A4A5A),
                ),
              ],
            ),
          ),
          
          // Content
          if (_showVehicleRequest) ...[
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // No vehicles warning
                  if (_availableVehicles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "No vehicles available in your barangay",
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                                      // Step 1: Select Vehicle
                  _buildStepHeader('1. Select Vehicle', Icons.directions_car),
                  const SizedBox(height: 16),
                  _buildVehicleSelection(),
                  const SizedBox(height: 24),
                  
                  // Step 2: Schedule Pickup
                  _buildStepHeader('2. Schedule Pickup', Icons.schedule),
                    const SizedBox(height: 16),
                  _buildDateTimeSelection(),
                  const SizedBox(height: 24),
                  
                  // Step 3: Destination & Details
                  _buildStepHeader('3. Destination & Details', Icons.location_on),
                    const SizedBox(height: 16),
                  _buildDestinationFields(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarangaySelection() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
                child: Text(
            'Select Barangay',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF3A4A5A),
                  ),
                ),
              ),
          Container(
            decoration: BoxDecoration(
            color: _selectedBarangayId == null ? Colors.grey.shade100 : Colors.white,
            border: Border.all(color: Color(0xFF3A4A5A).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _allBarangays.any((b) => b['id'] == _selectedBarangayId) ? _selectedBarangayId : null,
              isExpanded: true,
              isDense: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF3A4A5A)),
              hint: Text(
                'Select Barangay',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              dropdownColor: Colors.white,
              menuMaxHeight: 320,
              itemHeight: 48,
              selectedItemBuilder: (context) {
                return _allBarangays.map((barangay) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      barangay['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3A4A5A),
                      ),
                    ),
                  );
                }).toList();
              },
              items: _allBarangays.map((barangay) {
                return DropdownMenuItem<String>(
                  value: barangay['id'] as String,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    barangay['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3A4A5A),
                      ),
                    overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _allBarangays.isEmpty
                  ? null
                  : (value) {
                final selectedBarangay = _allBarangays.firstWhere((b) => b['id'] == value);
                _onBarangaySelected(value!, selectedBarangay['name']);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
                    child: Text(
            'Address Information',
                      style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF3A4A5A),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              // Home Address - underline only style
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF3A4A5A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _homeAddressController,
                  decoration: InputDecoration(
                    labelText: 'Home Address',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Street Name - underline only style
              Container(
      decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF3A4A5A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _streetNameController,
                  decoration: InputDecoration(
                    labelText: 'Street Name',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
          Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                  color: Color(0xFF3A4A5A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF3A4A5A).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complete Address:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                        color: Color(0xFF3A4A5A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_homeAddressController.text.isNotEmpty ? _homeAddressController.text : '[Home Address]'}, ${_streetNameController.text.isNotEmpty ? _streetNameController.text : '[Street Name]'}, $_selectedBarangayName, Dasmariñas, Cavite",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      resizeToAvoidBottomInset: true,
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
        child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please provide complete and accurate details to help us process your dengue report efficiently. Your cooperation is important in ensuring timely action.',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  // --- Reporting For Toggle ---
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A4A5A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildToggleOption(
                                title: 'Self Report',
                                subtitle: 'I am reporting myself as the patient', 
                                icon: Icons.person,
                                isSelected: _isReportingForSelf,
                                onTap: () => _selectReportingType(true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildToggleOption(
                                title: 'Report Others',
                                subtitle: 'I am reporting another person as the patient',
                                icon: Icons.people,
                                isSelected: !_isReportingForSelf,
                                onTap: () => _selectReportingType(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  if (_isReportingForSelf) ...[
                    // --- Self Report Section ---
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF3A4A5A).withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF3A4A5A)),
                              const SizedBox(width: 12),
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3A4A5A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your personal information has been automatically filled from your profile.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (residentData?['latitude'] != null && residentData?['longitude'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Location already set from profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    // --- Barangay Selection for Others ---
                    _buildBarangaySelection(),
                    
                    if (_selectedBarangayId != null) ...[
                      // --- Location Setting for Others ---
                      const SizedBox(height: 24.0),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF3A4A5A).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF3A4A5A).withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Set Location",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                                color: Color(0xFF3A4A5A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Set the exact location where the dengue case was reported",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openMapModal,
                              icon: Icon(
                                _isLocationSaved ? Icons.edit_location : Icons.map,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isLocationSaved ? 'Edit Location' : 'Set Location on Map',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isLocationSaved ? Colors.green : Color(0xFF3A4A5A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (_isLocationSaved) ...[
                              const SizedBox(height: 12),
                    Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                        children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Location saved successfully',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        ],
                      ),
                    ),
                    
                      // --- Address Information for Others ---
                      const SizedBox(height: 24.0),
                      _buildAddressInformation(),

                      // --- Personal Information Section for Others ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
                        child: Text(
                          'Personal Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF3A4A5A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            // First Name - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Middle Name - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _middleNameController,
                                decoration: InputDecoration(
                                  labelText: 'Middle Name',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Last Name - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Suffix - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _suffixController,
                                decoration: InputDecoration(
                                  labelText: 'Suffix (if any)',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            
                            // Date of Birth with bottom sheet picker - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showDatePickerBottomSheet(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dateOfBirthController.text.isNotEmpty 
                                              ? DateFormat('MMM dd, yyyy').format(DateTime.parse(_dateOfBirthController.text))
                                              : 'Select Date of Birth',
                                          style: TextStyle(
                                            color: _dateOfBirthController.text.isNotEmpty 
                                                ? Colors.black 
                                                : Colors.grey.shade500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFF3A4A5A),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Sex dropdown - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                ),
                              ),
                            ),
                              child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _sexController.text.isNotEmpty ? _sexController.text : null,
                                items: ['Male', 'Female'].map((sex) => DropdownMenuItem(
                                  value: sex,
                                  child: Text(sex),
                                )).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _sexController.text = value ?? '';
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Sex',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Phone Number - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            
                            // Relationship dropdown - underline only style
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF3A4A5A).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedRelationship,
                                items: [
                                  DropdownMenuItem(value: 'Family Member', child: Text('Family Member')),
                                  DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                                  DropdownMenuItem(value: 'Neighbor', child: Text('Neighbor')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRelationship = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Your Relationship to the Patient',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      

                    ],
                  ],
                  
                  const SizedBox(height: 32.0),
                  _buildVehicleRequestSection(),
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : _submitDengueReport,
                        icon: isSubmitting 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        label: Text(
                          isSubmitting ? 'Submitting...' : 'Submit Report',
                          style: TextStyle(
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _dateOfBirthController.dispose();
    _sexController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    _streetNameController.dispose();
    _reasonController.dispose();
    _destinationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

