import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class PendingScreen extends StatefulWidget {
  final String userId;
  const PendingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  bool _isActive = false;
  Timer? _timer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeController.forward();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_isNavigating) return; // Prevent multiple navigation calls
    
    final supabase = Supabase.instance.client;
    try {
      // Check status directly from users table using auth_id
      final userData = await supabase
          .from('users')
          .select('status')
          .eq('auth_id', widget.userId)
          .maybeSingle();
      final status = userData != null ? userData['status'] as String? : null;
      if (status == "Active" && mounted && !_isNavigating) {
        setState(() {
          _isActive = true;
        });
        _controller.stop();
        _timer?.cancel();
        
        // Wait 2 seconds, then navigate to /home
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isNavigating) {
            setState(() {
              _isNavigating = true;
            });
            // Use go_router instead of Navigator
            context.go('/home');
          }
        });
      }
    } catch (e) {
      // Optionally handle error
      print("Error checking status: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBDDDFC),
              Color(0xFFE8F4FD),
              Color(0xFFF5F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeController,
              child: _isActive
                  ? _buildSuccessScreen()
                  : _buildPendingScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success Icon with Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          
          // Success Title
          const Text(
            'Account Verified!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Success Message
          const Text(
            'Your account has been successfully verified by the barangay. You can now access all features of the app.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Proceed Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A89A7), Color(0xFF5A7A9A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A89A7).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go('/home'),
                child: const Center(
                  child: Text(
                    'Proceed to App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingScreen() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo (Static)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6A89A7), Color(0xFF5A7A9A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A89A7).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Title
          const Text(
            'Account Verification',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Subtitle
          const Text(
            'Pending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A89A7),
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    size: 32,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status Message
                const Text(
                  'Your account is currently being verified by the barangay officials.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Additional Info
                const Text(
                  'This process typically takes 24-48 hours. You will be notified once your account is approved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Progress Indicator
          Column(
            children: [
              const Text(
                'Checking status...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6A89A7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF6A89A7).withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Contact Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6A89A7).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6A89A7),
                  size: 24,
                ),
                const SizedBox(height: 12),
                const Text(
                  'For faster processing, you may visit your barangay office directly.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
