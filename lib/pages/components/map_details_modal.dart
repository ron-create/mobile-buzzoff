import 'package:flutter/material.dart';

class MapDetailsModal extends StatelessWidget {
  final Map<String, dynamic>? selectedBarangay;
  final Map<String, dynamic>? selectedHospital;
  final VoidCallback onClose;
  final double radius;
  final Function(double) onRadiusChanged;
  final bool showRadiusControl;
  final VoidCallback? onDirectionsFromHome;
  final VoidCallback? onDirectionsFromCurrent;

  const MapDetailsModal({
    super.key,
    this.selectedBarangay,
    this.selectedHospital,
    required this.onClose,
    required this.radius,
    required this.onRadiusChanged,
    this.showRadiusControl = false,
    this.onDirectionsFromHome,
    this.onDirectionsFromCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced handle bar with better drag detection
          GestureDetector(
            onVerticalDragUpdate: (details) {
              // Only close if dragged down significantly
              if (details.delta.dy > 15) {
                onClose();
              }
            },
            onVerticalDragEnd: (details) {
              // Close if velocity is high enough
              if (details.velocity.pixelsPerSecond.dy > 500) {
                onClose();
              }
            },
            child: Center(
              child: Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Enhanced title with better typography
          Text(
            selectedBarangay != null ? 'Barangay Details' : 'Hospital Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF384949),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          // Content with enhanced scroll physics and scroll-to-close
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Close modal if scrolled to top and dragged down
                if (scrollInfo.metrics.pixels <= 0) {
                  if (scrollInfo is ScrollUpdateNotification && scrollInfo.scrollDelta! > 10) {
                    onClose();
                    return true;
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  children: [
                    if (selectedBarangay != null) ...[
                      _buildEnhancedDetailRow(
                        context,
                        'Barangay Name',
                        selectedBarangay!['name']?.toString() ?? 'Unknown Barangay',
                        Icons.info_outline,
                        const Color(0xFF7A9CB6),
                      ),
                      _buildEnhancedDetailRow(
                        context,
                        'Confirmed Dengue Cases',
                        '${selectedBarangay!['dengue_cases']?.length ?? 0}',
                        Icons.coronavirus,
                        Colors.red,
                      ),
                      _buildEnhancedDetailRow(
                        context,
                        'Active Breeding Sites',
                        '${selectedBarangay!['breeding_sites']?.length ?? 0}',
                        Icons.warning,
                        Colors.orange,
                      ),
                    ] else if (selectedHospital != null) ...[
                      _buildEnhancedDetailRow(
                        context,
                        'Name',
                        selectedHospital!['name']?.toString() ?? 'Unknown Hospital',
                        Icons.local_hospital,
                        const Color(0xFF7A9CB6),
                      ),
                    ],
                    if (selectedHospital != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Navigation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF384949),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onDirectionsFromHome,
                              icon: const Icon(Icons.home, color: Colors.white, size: 18),
                              label: const Text(
                                'From Home',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A9CB6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDirectionsFromCurrent,
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text(
                                'From Current',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF384949),
                                side: const BorderSide(color: Color(0xFF7A9CB6)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (showRadiusControl) ...[
                      const SizedBox(height: 30),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search Radius',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF384949),
                            ),
                          ),
                          // Enhanced radius indicator
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A9CB6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7A9CB6).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${radius.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: radius,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFF7A9CB6),
                        onChanged: onRadiusChanged,
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailRow(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
}
