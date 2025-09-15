import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../actions/register_page_actions.dart';
import '../utils/responsive.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? selectedBarangay;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isAgreeChecked = false;
  bool isLoading = false;
  List<Map<String, dynamic>> barangays = [];

  @override
  void initState() {
    super.initState();
    fetchBarangays();
  }

  Future<void> fetchBarangays() async {
    final fetchedBarangays = await RegisterPageActions().fetchBarangays();
    setState(() {
      barangays = fetchedBarangays;
    });
  }

 Future<void> signUp() async {
  if (!isAgreeChecked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must agree to the Terms of Service and Privacy Policy.")),
    );
    return;
  }

  final email = emailController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();

  if (email.isEmpty || selectedBarangay == null || password.isEmpty || confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All fields are required.")),
    );
    return;
  }

  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwords do not match.")),
    );
    return;
  }

  setState(() => isLoading = true);

  final error = await RegisterPageActions().registerUser(
    email: email,
    barangayId: selectedBarangay!,
    password: password,
  );

  setState(() => isLoading = false);

  if (error == null) {
    // Navigate to Splash Screen FIRST before Setup Page
    context.go('/registration-success');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            'Create Your Account',
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
                  'Join our community in preventing dengue. Register to report cases, monitor outbreaks, and stay informed about health alerts in your barangay.',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 13),
                    color: const Color(0xFF95A5A6),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 40)),
                
                // Form Fields
                buildTextField("Email Address", Icons.email_outlined, emailController, false, keyboardType: TextInputType.emailAddress),
                buildBarangayDropdown(),
                buildPasswordField("Password", passwordController, isPasswordVisible, () {
                  setState(() => isPasswordVisible = !isPasswordVisible);
                }),
                buildPasswordField("Confirm Password", confirmPasswordController, isConfirmPasswordVisible, () {
                  setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible);
                }),
                buildTermsCheckbox(),
                SizedBox(height: Responsive.vertical(context, 20)),
                buildSignUpButton(),
                SizedBox(height: Responsive.vertical(context, 20)),
                
                // Already have account section
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: const Color(0xFF2C3E50),
                          fontSize: Responsive.font(context, 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Text(
                          "Log in",
                          style: TextStyle(
                            color: const Color(0xFF6A89A7),
                            fontSize: Responsive.font(context, 14),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 40)), // safe space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String hint, IconData icon, TextEditingController controller, bool obscure, {TextInputType keyboardType = TextInputType.text}) {
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
          keyboardType: keyboardType,
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

  Widget buildBarangayDropdown() {
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
          onTap: () => _showBarangaySelectionModal(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 16),
              vertical: Responsive.vertical(context, 16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_city,
                  color: const Color(0xFF6C757D),
                  size: Responsive.icon(context, 20),
                ),
                SizedBox(width: Responsive.horizontal(context, 12)),
                Expanded(
                  child: Text(
                    selectedBarangay != null 
                        ? barangays.firstWhere((b) => b['id'] == selectedBarangay)['name']
                        : "Select Barangay",
                    style: TextStyle(
                      fontSize: Responsive.font(context, 16),
                      color: selectedBarangay != null 
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFFADB5BD),
                    ),
                  ),
                ),
                if (selectedBarangay != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBarangay = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: const Color(0xFF6C757D),
                        size: Responsive.icon(context, 16),
                      ),
                    ),
                  ),
                SizedBox(width: Responsive.horizontal(context, 4)),
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

  void _showBarangaySelectionModal() {
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
          maxHeight: MediaQuery.of(context).size.height * 0.6, // 60% of screen height max
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
                    Icons.location_city,
                    color: const Color(0xFF6A89A7),
                    size: Responsive.icon(context, 24),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 10)),
                  Text(
                    'Select Barangay',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 16)),
            
            // Barangay list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: barangays.length,
                itemBuilder: (context, index) {
                  final barangay = barangays[index];
                  final isSelected = selectedBarangay == barangay['id'];
                  
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isSelected ? const Color(0xFF6A89A7) : const Color(0xFF6C757D),
                      size: Responsive.icon(context, 20),
                    ),
                    title: Text(
                      barangay['name'],
                      style: TextStyle(
                        fontSize: Responsive.font(context, 16),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF6A89A7) : const Color(0xFF2C3E50),
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: const Color(0xFF6A89A7),
                            size: Responsive.icon(context, 20),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedBarangay = barangay['id'];
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget buildPasswordField(String hint, TextEditingController controller, bool isVisible, VoidCallback toggleVisibility) {
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
          obscureText: !isVisible,
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
              Icons.lock_outline,
              color: const Color(0xFF6C757D),
              size: Responsive.icon(context, 20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF6C757D),
                size: Responsive.icon(context, 20),
              ),
              onPressed: toggleVisibility,
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

  Widget buildTermsCheckbox() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: isAgreeChecked,
              onChanged: (value) => setState(() => isAgreeChecked = value!),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "I agree to the ",
                    style: TextStyle(fontSize: Responsive.font(context, 15)),
                  ),
                  GestureDetector(
                    onTap: () => _showTermsModal(context),
                    child: Text(
                      "Terms of Service",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: Responsive.font(context, 15),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    " and ",
                    style: TextStyle(fontSize: Responsive.font(context, 15)),
                  ),
                  GestureDetector(
                    onTap: () => _showPrivacyModal(context),
                    child: Text(
                      "Privacy Policy",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: Responsive.font(context, 15),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 40, // more safe space
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Terms of Service',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.font(context, 20),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This is a placeholder for the Terms of Service.\n\nReplace this with your actual terms.',
              style: TextStyle(fontSize: Responsive.font(context, 15)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 40, // more safe space
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.font(context, 20),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This is a placeholder for the Privacy Policy.\n\nReplace this with your actual privacy policy.',
              style: TextStyle(fontSize: Responsive.font(context, 15)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A89A7),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: Responsive.vertical(context, 16)),
        ),
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                "Sign Up",
                style: TextStyle(color: Colors.white, fontSize: Responsive.font(context, 18)),
              ),
      ),
    );
  }
}
