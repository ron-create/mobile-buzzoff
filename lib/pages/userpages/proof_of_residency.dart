import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../actions/setup_account_actions.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProofOfResidency extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProofOfResidency({super.key, required this.userData});

  @override
  State<ProofOfResidency> createState() => _ProofOfResidencyState();
}

class _ProofOfResidencyState extends State<ProofOfResidency> {
  File? _selectedImage;
  bool _isUploading = false;
  bool _isNavigating = false;
  final ImagePicker _picker = ImagePicker();
  final SetupAccountActions actions = SetupAccountActions();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProof() async {
    if (_selectedImage == null || _isNavigating) return;
    
    setState(() { 
      _isUploading = true; 
      _isNavigating = true;
    });
    
    final result = await actions.uploadProofOfResidency(
      imageFile: _selectedImage!,
      userData: {
        ...widget.userData,
        'address': widget.userData['address'] ?? '',
        'latitude': widget.userData['latitude'] ?? 0.0,
        'longitude': widget.userData['longitude'] ?? 0.0,
        'block_lot': widget.userData['block_lot'] ?? '',
        'street_subdivision': widget.userData['street_subdivision'] ?? '',
      },
    );
    
    setState(() { _isUploading = false; });
    
    if (result == null) {
      await ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof uploaded! Your account is now pending for verification.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      if (mounted) {
        // Use go_router instead of Navigator.pop()
        // Get userId from userData or from authenticated user
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          context.go('/pending', extra: user.id);
        } else {
          // Fallback: use a default or show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not found'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      setState(() { _isNavigating = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    final address = user['address'] ?? '';
    final fullName = [user['firstName'], user['middleName'], user['lastName'], user['suffixName']].where((e) => (e ?? '').toString().trim().isNotEmpty).join(' ');
    final barangay = user['barangayName'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof of Residency', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFBDDDFC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      backgroundColor: const Color(0xFFBDDDFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
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
                        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BuzzOffPH',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Proof of Residency',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF7F8C8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF6A89A7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.home, color: Color(0xFF6A89A7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_city, color: Color(0xFF6A89A7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Barangay: $barangay',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Instructions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Upload a clear photo of any valid ID with your address. This will be confirmed by the barangay. They will check if you are in the barangay database.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)),
                  ),
                ),
                const SizedBox(height: 24),
                // Image Picker Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      _selectedImage == null
                          ? const Text('No image selected.', style: TextStyle(color: Color(0xFF7F8C8D)))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_selectedImage!, height: 200),
                            ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pick Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A89A7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: (_selectedImage == null || _isUploading) ? null : _uploadProof,
                            icon: _isUploading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.upload),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
