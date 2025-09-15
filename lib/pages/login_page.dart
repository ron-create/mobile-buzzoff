import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../actions/login_page_actions.dart';
import '../actions/profile_settings_action.dart';
import '../utils/responsive.dart';
import 'flashscreen/pending.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController forgotPasswordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isForgotPasswordLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBDDDFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: Responsive.vertical(context, 50)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo and Title Section
                Container(
                  width: Responsive.horizontal(context, 120),
                  height: Responsive.vertical(context, 120),
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
                SizedBox(height: Responsive.vertical(context, 15)),
                Text(
                  'BuzzOffPH',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 32),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: Responsive.vertical(context, 8)),
                Text(
                  'Dengue Prevention Resident Application',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 14),
                    color: const Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: Responsive.vertical(context, 5)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.padding(context, 20),
                    vertical: Responsive.vertical(context, 8),
                  ),
                  child: Text(
                    'Empowering residents to combat dengue through smart reporting, real-time monitoring, and community awareness',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 12),
                      color: const Color(0xFF95A5A6),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 50)),
                
                // Email Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                  child: _buildInputField(
                    controller: emailController,
                    hintText: "Email Address",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 20)),
                
                // Password Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                  child: _buildInputField(
                    controller: passwordController,
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 15)),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: Responsive.padding(context, 20)),
                    child: TextButton(
                      onPressed: () => _showForgotPasswordBottomSheet(context),
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: const Color(0xFF6A89A7),
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 30)),
                
                // Login Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                  child: SizedBox(
                    width: double.infinity,
                    height: Responsive.vertical(context, 50),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A89A7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: Responsive.horizontal(context, 20),
                              height: Responsive.vertical(context, 20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: Responsive.font(context, 16),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                
                SizedBox(height: Responsive.vertical(context, 30)),
                
                // Sign Up Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: const Color(0xFF2C3E50),
                        fontSize: Responsive.font(context, 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: const Color(0xFF6A89A7),
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: Responsive.vertical(context, 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
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
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: Responsive.font(context, 16),
          color: const Color(0xFF2C3E50),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFFADB5BD),
            fontSize: Responsive.font(context, 16),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF6C757D),
            size: Responsive.icon(context, 20),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF6C757D),
                    size: Responsive.icon(context, 20),
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                )
              : null,
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
    );
  }

  void _showForgotPasswordBottomSheet(BuildContext context) {
    forgotPasswordController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
                     padding: EdgeInsets.only(
             bottom: MediaQuery.of(context).viewInsets.bottom + Responsive.vertical(context, 20),
             left: Responsive.padding(context, 20),
             right: Responsive.padding(context, 20),
             top: Responsive.vertical(context, 20),
           ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: Responsive.horizontal(context, 40),
                height: Responsive.vertical(context, 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: Responsive.vertical(context, 20)),
              
              // Title
              Row(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: const Color(0xFF6A89A7),
                    size: Responsive.icon(context, 24),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 10)),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.vertical(context, 15)),
              
              // Description
              Text(
                'Enter your email address to receive a password reset link.',
                style: TextStyle(
                  fontSize: Responsive.font(context, 14),
                  color: const Color(0xFF7F8C8D),
                ),
              ),
              SizedBox(height: Responsive.vertical(context, 25)),
              
              // Email Input
              TextField(
                controller: forgotPasswordController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  hintStyle: TextStyle(
                    color: const Color(0xFFADB5BD),
                    fontSize: Responsive.font(context, 14),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: const Color(0xFF6C757D),
                    size: Responsive.icon(context, 20),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6A89A7)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Responsive.padding(context, 16),
                    vertical: Responsive.vertical(context, 16),
                  ),
                ),
              ),
              SizedBox(height: Responsive.vertical(context, 25)),
              
              // Buttons
              Row(
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
                        onPressed: isForgotPasswordLoading ? null : _handleForgotPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A89A7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isForgotPasswordLoading
                            ? SizedBox(
                                width: Responsive.horizontal(context, 16),
                                height: Responsive.vertical(context, 16),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Send Reset Link',
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
              SizedBox(height: Responsive.vertical(context, 20)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = forgotPasswordController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isForgotPasswordLoading = true;
    });

    try {
      debugPrint('Sending password reset email to: $email');
      final success = await ProfileSettingsAction().resetPasswordViaEmail(
        context: context,
        email: email,
      );
      debugPrint('Password reset email requested for: $email, success: $success');

      if (success == true) {
        // Wait for the dialog to be dismissed before closing the bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          Navigator.of(context).pop(); // Close bottom sheet after dialog
        }
      } else {
        // Show error if sending failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send password reset email. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isForgotPasswordLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showErrorAlert('Please fill in both email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final response = await LoginPageActions().login(email, password);

      if (response != null && response["success"] == true) {
        // Check if profile setup is incomplete
        if (response["profile_incomplete"] == true) {
          debugPrint('🔄 Profile incomplete - redirecting to setup account page');
          // Redirect to setup page for incomplete profile
          context.go('/setup-account');
        } else {
          debugPrint('🔄 Profile complete - redirecting to login success page');
          // Navigate to login success screen for complete profile
          context.go('/login-success');
        }
      } else if (response != null && response["error"] == "status_error") {
        final status = response["status"]?.toString().toLowerCase();
        
        if (status == 'deleted') {
          // Show red snackbar for deleted status
          _showErrorAlert(
            'Your account has been deleted. Please contact the City Health Office for account restoration.',
            color: const Color(0xFFE53935),
            background: const Color(0xFFFFEBEE),
          );
        } else if (status == 'pending') {
          // Navigate to PendingScreen instead of showing a snackbar
          final userId = response["user_id"] ?? response["id"];
          if (userId != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PendingScreen(userId: userId),
              ),
            );
          } else {
            _showErrorAlert(
              'Your account is currently pending approval. Please wait for your barangay to accept your registration.',
              color: const Color(0xFFFF9800),
              background: const Color(0xFFFFF3E0),
            );
          }
        } else {
          // Show snackbar for other status errors
          _showErrorAlert(response["message"] ?? 'Account status error.');
        }
      } else {
        _showErrorAlert('Incorrect email or password.');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorAlert(String message, {Color color = const Color(0xFFE53935), Color background = const Color(0xFFFFEBEE)}) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + Responsive.vertical(context, 10),
              left: Responsive.padding(context, 16),
              right: Responsive.padding(context, 16),
              bottom: Responsive.vertical(context, 10),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, 16),
                vertical: Responsive.vertical(context, 12),
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: color,
                    size: Responsive.icon(context, 20),
                  ),
                  SizedBox(width: Responsive.horizontal(context, 12)),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 14),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      overlayEntry?.remove();
                    },
                    child: Icon(
                      Icons.close,
                      color: color,
                      size: Responsive.icon(context, 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }
}
