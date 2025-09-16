import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../actions/setup_account_actions.dart';
import '../utils/responsive.dart';
import 'package:flutter/cupertino.dart';

class SetUp extends StatefulWidget {
  const SetUp({super.key});

  @override
  State<SetUp> createState() => _SetUpState();
}

class _SetUpState extends State<SetUp> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String? selectedSex;
  String? selectedSuffix;
  bool isLoading = true;
  String? barangayName;
  final SetupAccountActions actions = SetupAccountActions();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchBarangayName();
  }

  Future<void> _fetchBarangayName() async {
    final name = await actions.getBarangayName();
    setState(() {
      barangayName = name ?? "Unknown Barangay";
      isLoading = false;
    });
  }

  void _goToSetHome() async {
    if (_isNavigating) return;
    setState(() { _isNavigating = true; });
    final String firstName = firstNameController.text.trim();
    final String middleName = middleNameController.text.trim();
    final String lastName = lastNameController.text.trim();
    final String suffixName = selectedSuffix ?? "";
    final String birthDate = birthDateController.text.trim();
    final String phoneNumber = phoneNumberController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || birthDate.isEmpty || phoneNumber.isEmpty || selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _isNavigating = false; });
      return;
    }

    final selectedDate = DateTime.parse(birthDate);
    if (selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Date of birth cannot be in the future."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _isNavigating = false; });
      return;
    }

    if (phoneNumber.length != 10 || !phoneNumber.startsWith('9')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit phone number starting with 9."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() { _isNavigating = false; });
      return;
    }

    final String formattedPhoneNumber = "0$phoneNumber";

    context.push('/set-home', extra: {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'suffixName': suffixName,
      'birthDate': birthDate,
      'sex': selectedSex,
      'phoneNumber': formattedPhoneNumber,
      'barangayName': barangayName,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 20),
              vertical: Responsive.vertical(context, 30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Title Section (Top Left)
                Row(
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
                            'Complete Your Profile',
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
                
                SizedBox(height: Responsive.vertical(context, 8)),
                
                // Description
                Text(
                  'Please provide your personal information to complete your account setup. This helps us provide better service and accurate reporting.',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 13),
                    color: const Color(0xFF95A5A6),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 20)),
                
                // Barangay Info Card
                if (!isLoading)
                  Container(
                    padding: EdgeInsets.all(Responsive.padding(context, 16)),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          color: const Color(0xFF6A89A7),
                          size: Responsive.icon(context, 20),
                        ),
                        SizedBox(width: Responsive.horizontal(context, 12)),
                        Expanded(
                          child: Text(
                            "Barangay: $barangayName",
                            style: TextStyle(
                              fontSize: Responsive.font(context, 16),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: Responsive.vertical(context, 30)),
                
                // Form Fields
                buildTextField("First Name *", Icons.person_outline, firstNameController, false),
                buildTextField("Middle Name", Icons.person_outline, middleNameController, false),
                buildTextField("Last Name *", Icons.person_outline, lastNameController, false),
                buildSuffixDropdown(),
                buildDateField(),
                buildSexDropdown(),
                buildPhoneField(),
                
                SizedBox(height: Responsive.vertical(context, 30)),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: Responsive.vertical(context, 50),
                  child: ElevatedButton(
                    onPressed: _isNavigating ? null : _goToSetHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A89A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: Responsive.font(context, 16),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 60)), // increased safe space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPhoneField() {
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
          controller: phoneNumberController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            color: const Color(0xFF2C3E50),
          ),
          decoration: InputDecoration(
            hintText: "912 345 6789",
            hintStyle: TextStyle(
              color: const Color(0xFFADB5BD),
              fontSize: Responsive.font(context, 16),
            ),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: const Color(0xFF6C757D),
              size: Responsive.icon(context, 20),
            ),
            prefixText: "+63 ",
            prefixStyle: TextStyle(
              fontSize: Responsive.font(context, 16),
              color: const Color(0xFF2C3E50),
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

  Widget buildSuffixDropdown() {
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
        child: DropdownButtonFormField<String>(
          value: selectedSuffix,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF6C757D),
            size: Responsive.icon(context, 20),
          ),
          items: ["None", "Jr.", "Sr.", "II", "III", "IV"].map((suffix) {
            return DropdownMenuItem(
              value: suffix == "None" ? null : suffix,
              child: Text(
                suffix,
                style: TextStyle(
                  fontSize: Responsive.font(context, 16),
                  color: const Color(0xFF2C3E50),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedSuffix = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Suffix",
            hintStyle: TextStyle(
              color: const Color(0xFFADB5BD),
              fontSize: Responsive.font(context, 16),
            ),
            prefixIcon: Icon(
              Icons.person_outline,
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
          dropdownColor: Colors.white,
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            color: const Color(0xFF2C3E50),
          ),
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

  Widget buildDateField() {
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
        child: InkWell(
          onTap: () => _showCustomDatePicker(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 16),
              vertical: Responsive.vertical(context, 16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: const Color(0xFF6C757D),
                  size: Responsive.icon(context, 20),
                ),
                SizedBox(width: Responsive.horizontal(context, 12)),
                Expanded(
                  child: Text(
                    birthDateController.text.isNotEmpty 
                        ? _formatDate(birthDateController.text)
                        : "Date of Birth *",
                    style: TextStyle(
                      fontSize: Responsive.font(context, 16),
                      color: birthDateController.text.isNotEmpty 
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFFADB5BD),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFF6C757D),
                  size: Responsive.icon(context, 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showCustomDatePicker() {
    DateTime selectedDate = DateTime.now();
    if (birthDateController.text.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(birthDateController.text);
      } catch (e) {
        selectedDate = DateTime.now();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: Responsive.horizontal(context, 40),
              height: Responsive.vertical(context, 4),
              margin: EdgeInsets.only(top: Responsive.vertical(context, 12)),
              decoration: BoxDecoration(
                color: const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 16)),
            
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: const Color(0xFF6A89A7),
                    size: Responsive.icon(context, 24),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 10)),
                  Text(
                    'Select Date of Birth',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 20)),
            
            // Date picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1900),
                onDateTimeChanged: (DateTime newDate) {
                  selectedDate = newDate;
                },
              ),
            ),
            
            // Buttons
            Padding(
              padding: EdgeInsets.all(Responsive.padding(context, 20)),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: Responsive.vertical(context, 12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE9ECEF)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: const Color(0xFF6C757D),
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 12)),
                  Expanded(
                    child: SizedBox(
                      height: Responsive.vertical(context, 44),
                      child: ElevatedButton(
                        onPressed: () {
                          birthDateController.text = selectedDate.toIso8601String().split('T')[0];
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A89A7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget buildSexDropdown() {
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
        child: DropdownButtonFormField<String>(
          value: selectedSex,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF6C757D),
            size: Responsive.icon(context, 20),
          ),
          items: ["Male", "Female", "Other"].map((sex) {
            return DropdownMenuItem(
              value: sex,
              child: Text(
                sex,
                style: TextStyle(
                  fontSize: Responsive.font(context, 16),
                  color: const Color(0xFF2C3E50),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedSex = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Sex *",
            hintStyle: TextStyle(
              color: const Color(0xFFADB5BD),
              fontSize: Responsive.font(context, 16),
            ),
            prefixIcon: Icon(
              Icons.person_outline,
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
          dropdownColor: Colors.white,
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            color: const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }
}
