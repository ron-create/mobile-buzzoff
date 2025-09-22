import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../actions/profile_settings_action.dart';
import '../../utils/responsive.dart';
import '../../actions/profile_page_action.dart';


class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Image handling
  XFile? _profileImage;
  String? _profileImageUrl;
  
  // User data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _residentData;
  bool _isLoading = true;
  String? _selectedSex;
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _listenersAttached = false;
  Map<String, String?> _initialValues = {};
  String? _selectedSuffix;
  
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _suffixOptions = ['', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V', 'PhD', 'MD', 'RN', 'CPA', 'Esq.'];
  
  // Action instance
  final ProfileSettingsAction _action = ProfileSettingsAction();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await _action.fetchUserData(context);
      
      setState(() {
        _userData = data['user'];
        _residentData = data['resident'];
        _profileImageUrl = _userData!['profile'];
        
        // Populate form fields
        _firstNameController.text = _residentData!['first_name'] ?? '';
        _middleNameController.text = _residentData!['middle_name'] ?? '';
        _lastNameController.text = _residentData!['last_name'] ?? '';
        _suffixController.text = _residentData!['suffix_name'] ?? '';
        _selectedSuffix = _residentData!['suffix_name'] ?? '';
        _phoneController.text = _residentData!['phone'] ?? '';
        _emailController.text = _userData!['email'] ?? '';
        _addressController.text = _residentData!['address'] ?? '';
        _selectedSex = _residentData!['sex'];
        
        // Format date of birth
        if (_residentData!['date_of_birth'] != null) {
          final DateTime dob = DateTime.parse(_residentData!['date_of_birth']);
          _dobController.text = DateFormat('dd / MM / yyyy').format(dob);
        }
        
        _isLoading = false;
        _captureInitialValues();
        _attachChangeListenersOnce();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  void _attachChangeListenersOnce() {
    if (_listenersAttached) return;
    for (final c in [
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _suffixController,
      _phoneController,
      _emailController,
      _dobController,
      _addressController,
    ]) {
      c.addListener(_checkHasChanges);
    }
    _listenersAttached = true;
  }

  void _captureInitialValues() {
    _initialValues = {
      'firstName': _firstNameController.text,
      'middleName': _middleNameController.text,
      'lastName': _lastNameController.text,
      'suffix': _suffixController.text,
      'selectedSuffix': _selectedSuffix,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'dob': _dobController.text,
      'address': _addressController.text,
      'sex': _selectedSex,
      'profileUrl': _profileImageUrl,
    };
    _hasChanges = false;
  }

  void _checkHasChanges() {
    final current = {
      'firstName': _firstNameController.text,
      'middleName': _middleNameController.text,
      'lastName': _lastNameController.text,
      'suffix': _suffixController.text,
      'selectedSuffix': _selectedSuffix,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'dob': _dobController.text,
      'address': _addressController.text,
      'sex': _selectedSex,
      'profileUrl': _profileImageUrl,
      'profileImagePath': _profileImage?.path,
    };
    final has = current.entries.any((e) => _initialValues[e.key] != e.value);
    if (has != _hasChanges) {
      setState(() {
        _hasChanges = has;
      });
    }
  }


  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse date of birth
      DateTime? dob;
      if (_dobController.text.isNotEmpty) {
        final parts = _dobController.text.split(' / ');
        if (parts.length == 3) {
          dob = DateTime(
            int.parse(parts[2]), 
            int.parse(parts[1]), 
            int.parse(parts[0])
          );
        }
      }
      
      // If a new image was picked, upload it first to obtain a URL
      if (_profileImage != null) {
        final uploaded = await _action.uploadAndUpdateProfilePicture(
          context: context,
          image: _profileImage!,
          userId: _userData!['id'],
        );
        if (!uploaded) {
          setState(() { _isLoading = false; });
          return;
        }
      }

      final success = await _action.updateFullProfile(
        context: context,
        userId: _userData!['id'],
        residentId: _residentData!['id'],
        email: _emailController.text,
        profileUrl: _profileImageUrl, // updated by upload step if any
        profileImage: _profileImage,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        middleName: _middleNameController.text,
        suffixName: _selectedSuffix ?? '',
        phone: _phoneController.text,
        address: _addressController.text,
        sex: _selectedSex!,
        dateOfBirth: dob,
      );
      
      if (success) {
        // Refresh user data to show updated information
        await _fetchUserData();
        setState(() {
          _isEditing = false;
          _profileImage = null;
          _hasChanges = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_isEditing) {
                      // Cancel edits: revert to initial values
                      setState(() {
                        _firstNameController.text = _initialValues['firstName'] ?? '';
                        _middleNameController.text = _initialValues['middleName'] ?? '';
                        _lastNameController.text = _initialValues['lastName'] ?? '';
                        _suffixController.text = _initialValues['suffix'] ?? '';
                        _selectedSuffix = _initialValues['selectedSuffix'] ?? '';
                        _phoneController.text = _initialValues['phone'] ?? '';
                        _emailController.text = _initialValues['email'] ?? '';
                        _dobController.text = _initialValues['dob'] ?? '';
                        _addressController.text = _initialValues['address'] ?? '';
                        _selectedSex = _initialValues['sex'];
                        _profileImageUrl = _initialValues['profileUrl'];
                        _profileImage = null;
                        _isEditing = false;
                        _hasChanges = false;
                      });
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
            child: Text(_isEditing ? 'Cancel' : 'Edit', style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildProfileForm(),
                    // Add extra padding at the bottom to avoid navigation bar
                    SizedBox(height: MediaQuery.of(context).padding.bottom + Responsive.vertical(context, 20)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile image section
        Container(
          padding: EdgeInsets.symmetric(vertical: Responsive.vertical(context, 24)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Profile image
              Container(
                padding: EdgeInsets.all(Responsive.padding(context, 4)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: CircleAvatar(
                  radius: Responsive.icon(context, 65),
                  backgroundColor: const Color(0xFFE7EFFF),
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null
                      ? Icon(Icons.person, size: Responsive.icon(context, 65), color: Color(0xFFAFBBD0))
                      : null,
                ),
              ),
              
              // Remove button overlay - only show if there's a profile image and editing
              if (_isEditing && _profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Mark for removal locally
                        setState(() {
                          _profileImageUrl = null;
                          _profileImage = null;
                        });
                        _checkHasChanges();
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Gallery and Camera controls (visible only in edit mode)
        if (_isEditing)
          Padding(
            padding: EdgeInsets.only(bottom: Responsive.vertical(context, 8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 12)),
                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        
        // Full width separation line (gradient)
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context).dividerColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(File(_profileImage!.path));
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  Widget _buildProfileForm() {
    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.vertical(context, 20),
        left: Responsive.padding(context, 20),
        right: Responsive.padding(context, 20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: Responsive.vertical(context, 12)),
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ),
            
            // Name fields in a row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                          ),
                        ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _middleNameController,
                    label: 'Middle Name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
                children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildDropdownField(
                    label: 'Suffix',
                    value: _selectedSuffix,
                    items: _suffixOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.isEmpty ? 'None' : value),
                      );
                    }).toList(),
                    onChanged: !_isEditing
                        ? null
                        : (String? newValue) {
                            setState(() {
                              _selectedSuffix = newValue;
                              _suffixController.text = newValue ?? '';
                            });
                            _checkHasChanges();
                          },
                  ),
                ),
              ],
                  ),
            const SizedBox(height: 12),
            
            // Gender dropdown
            _buildDropdownField(
              label: 'Gender',
              value: _selectedSex,
              items: _sexOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: null, // Make gender non-editable
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Date of birth
            _buildTextField(
              controller: _dobController,
              label: 'Date of Birth',
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your date of birth';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            
            // Phone number
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 11) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Address
            _buildTextField(
              controller: _addressController,
              label: 'Complete Address',
              prefixIcon: const Icon(Icons.location_on),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                      }
                return null;
                    },
                  ),
            
            const SizedBox(height: 20),
            
            // Update button (only when editing and there are changes)
            if (_isEditing && _hasChanges)
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: Responsive.vertical(context, 52),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5271FF),
                      disabledBackgroundColor: const Color(0xFF5271FF).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            
            const SizedBox(height: 15),
            
            // Change password button (edit mode only)
            if (_isEditing)
              Center(
                child: TextButton(
                  onPressed: () {
                    _showChangePasswordDialog();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5271FF),
                  ),
                  child: const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly || !_isEditing,
          onTap: onTap,
          maxLines: maxLines,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            labelStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
            ),
          ),
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            labelStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down, 
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF666666),
          ),
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
        ),
      ],
    );
  }

  // Take a direct photo using camera
  Future<void> _takePhoto() async {
    debugPrint('Taking photo from camera');
    
    // Check if user data is available
    if (_userData == null) {
      debugPrint('Error: _userData is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available')),
      );
      return;
    }
    
    try {
      final image = await _action.takeProfileImage();
      if (image != null) {
        debugPrint('Camera image captured: ${image.path}');
        setState(() {
          _profileImage = image;
          _isLoading = true;
        });
        
        // Upload immediately
        debugPrint('Uploading image for user ID: ${_userData!['id']}');
        // In edit flow, just mark change; upload will happen on Update Profile
        setState(() {
          _isLoading = false;
        });
        _checkHasChanges();
      } else {
        debugPrint('Camera returned null image');
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }
  
  // Pick image from gallery
  Future<void> _pickFromGallery() async {
    debugPrint('Picking image from gallery');
    
    // Check if user data is available
    if (_userData == null) {
      debugPrint('Error: _userData is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available')),
      );
      return;
    }
    
    try {
      final image = await _action.pickProfileImage();
      if (image != null) {
        debugPrint('Gallery image selected: ${image.path}');
        setState(() {
          _profileImage = image;
          _isLoading = false;
        });
        // Defer upload to Update Profile
        _checkHasChanges();
      } else {
        debugPrint('Gallery returned null image');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  // Show change password dialog
  void _showChangePasswordDialog() {
    // The root context from the page
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext modalContext) {
        return _ChangePasswordModal(
          action: _action,
          parentContext: rootContext, // Pass the page's context here
        );
      },
    );
  }
  

} 

// Separate widget for the change password modal to avoid state management issues
class _ChangePasswordModal extends StatefulWidget {
  final ProfileSettingsAction action;
  final BuildContext parentContext;

  const _ChangePasswordModal({
    required this.action,
    required this.parentContext,
  });

  @override
  State<_ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<_ChangePasswordModal> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();
  
  bool isObscure1 = true;
  bool isObscure2 = true;
  bool isObscure3 = true;
  bool isLoading = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: passwordFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Change Password',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: isObscure1,
                  style: const TextStyle(color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(color: Color(0xFF666666)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5271FF), width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure1 ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscure1 = !isObscure1;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: isObscure2,
                  style: const TextStyle(color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(color: Color(0xFF666666)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5271FF), width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure2 ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscure2 = !isObscure2;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: isObscure3,
                  style: const TextStyle(color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(color: Color(0xFF666666)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5271FF), width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure3 ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscure3 = !isObscure3;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF333333),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (passwordFormKey.currentState!.validate()) {
                                setState(() => isLoading = true);

                                final success = await widget.action.changePassword(
                                  modalContext: context, // Use the modal's context to pop
                                  rootContext: widget.parentContext, // Use the page's context for navigation/snackbar
                                  currentPassword: currentPasswordController.text,
                                  newPassword: newPasswordController.text,
                                );

                                // If the password change fails, re-enable the button
                                if (!success && mounted) {
                                  setState(() => isLoading = false);
                                }
                                // On success, the modal is closed and user is logged out,
                                // so no need to set isLoading to false here.
                              }
                            },


                          style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5271FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Change Password', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
