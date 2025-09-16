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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
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
            
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: const Color(0xFF6A89A7),
                    size: Responsive.icon(context, 24),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 10)),
                  Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(context, 20),
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 16)),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermsSection('1. Acceptance of Terms', 
                      'By accessing and using BuzzOffPH, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.'),
                    
                    _buildTermsSection('2. Use License', 
                      'Permission is granted to temporarily download one copy of BuzzOffPH for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• modify or copy the materials\n• use the materials for any commercial purpose or for any public display\n• attempt to reverse engineer any software contained on the website\n• remove any copyright or other proprietary notations from the materials'),
                    
                    _buildTermsSection('3. User Responsibilities', 
                      'As a user of BuzzOffPH, you agree to:\n\n• Provide accurate and truthful information when reporting dengue cases or breeding sites\n• Use the platform responsibly and not submit false or misleading reports\n• Respect the privacy and rights of other users\n• Not use the platform for any illegal or unauthorized purpose\n• Maintain the confidentiality of your account credentials'),
                    
                    _buildTermsSection('4. Data Privacy and Protection', 
                      'We are committed to protecting your privacy and personal information. By using BuzzOffPH, you consent to:\n\n• Collection and processing of your personal data for the purpose of providing our services\n• Sharing of non-personal, aggregated data with health authorities for public health purposes\n• Storage of your data in secure servers with appropriate security measures\n• Use of your contact information for important health alerts and updates'),
                    
                    _buildTermsSection('5. Medical Disclaimer', 
                      'The information provided by BuzzOffPH is for educational and informational purposes only. It is not intended as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.'),
                    
                    _buildTermsSection('6. Limitation of Liability', 
                      'In no event shall BuzzOffPH or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on BuzzOffPH, even if BuzzOffPH or an authorized representative has been notified orally or in writing of the possibility of such damage.'),
                    
                    _buildTermsSection('7. Account Termination', 
                      'We reserve the right to terminate or suspend your account at any time, without prior notice, for conduct that we believe violates these Terms and Conditions or is harmful to other users, us, or third parties, or for any other reason at our sole discretion.'),
                    
                    _buildTermsSection('8. Changes to Terms', 
                      'We reserve the right to modify these terms at any time. We will notify users of any material changes via email or through the platform. Your continued use of the service after such modifications constitutes acceptance of the updated terms.'),
                    
                    _buildTermsSection('9. Contact Information', 
                      'If you have any questions about these Terms and Conditions, please contact us at:\n\nEmail: support@buzzoffph.com\nPhone: (02) 123-4567\nAddress: City Health Office, Dasmariñas City, Cavite'),
                    
                    SizedBox(height: Responsive.vertical(context, 20)),
                  ],
                ),
              ),
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
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
            
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip,
                    color: const Color(0xFF6A89A7),
                    size: Responsive.icon(context, 24),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 10)),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(context, 20),
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vertical(context, 16)),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effective Date: September 16, 2025',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A89A7),
                      ),
                    ),
                    SizedBox(height: Responsive.vertical(context, 16)),
                    
                    _buildTermsSection('1. Introduction', 
                      'BuzzOffPH ("we", "us", "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform.'),
                    
                    _buildTermsSection('2. Information We Collect', 
                      '• Account Information: name, email, barangay, and profile details.\n• Health-related Reports: dengue case reports, breeding site submissions.\n• Device and Usage Data: IP, browser type, pages visited, timestamps.\n• Location Data: when you grant permission for mapping/reporting accuracy.\n• Media and Attachments: files you upload with reports or educational posts.'),
                    
                    _buildTermsSection('3. How We Use Your Information', 
                      '• Provide and maintain services (mapping, reporting, notifications).\n• Verify identity and secure access (authentication, OTP, reCAPTCHA).\n• Analyze trends and improve features (predictive alerts, dashboards).\n• Communicate updates, alerts, and educational content.\n• Comply with legal obligations and public health coordination.'),
                    
                    _buildTermsSection('4. Sharing of Information', 
                      '• Local Health Authorities (CHO, health centers) for public health response.\n• Service Providers (e.g., hosting, email/SMS) under data processing agreements.\n• Legal Requirements: when required by law, court order, or to protect rights.'),
                    
                    _buildTermsSection('5. Data Retention', 
                      'We retain personal data only as long as necessary for service delivery, legal, and reporting purposes. Aggregated or anonymized data may be kept for analytics and research.'),
                    
                    _buildTermsSection('6. Data Security', 
                      'We implement technical and organizational measures to protect your data, including encryption in transit, access controls, and regular reviews. No method of transmission or storage is 100% secure.'),
                    
                    _buildTermsSection('7. Your Rights', 
                      '• Access, correct, or delete your personal data (subject to legal limits).\n• Withdraw consent where processing is based on consent.\n• Object to or restrict certain processing activities.'),
                    
                    _buildTermsSection('8. Children\'s Privacy', 
                      'Our services are not directed to children under 13. We do not knowingly collect personal data from children. If you believe a child has provided data, contact us to remove it.'),
                    
                    _buildTermsSection('9. International Transfers', 
                      'Your data may be processed and stored in locations outside your jurisdiction with appropriate safeguards.'),
                    
                    _buildTermsSection('10. Changes to This Policy', 
                      'We may update this Privacy Policy periodically. Material changes will be notified via email or in-app notice. Continued use means acceptance of updates.'),
                    
                    _buildTermsSection('11. Contact Us', 
                      'For questions or requests, contact: support@buzzoffph.com, (02) 123-4567, City Health Office, Dasmariñas City, Cavite.'),
                    
                    SizedBox(height: Responsive.vertical(context, 20)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.font(context, 16),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: Responsive.vertical(context, 8)),
          Text(
            content,
            style: TextStyle(
              fontSize: Responsive.font(context, 14),
              color: const Color(0xFF5A6C7D),
              height: 1.5,
            ),
          ),
        ],
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
