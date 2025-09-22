import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';

class LoginSuccess extends StatefulWidget {
  const LoginSuccess({super.key});

  @override
  State<LoginSuccess> createState() => _LoginSuccessState();
}

class _LoginSuccessState extends State<LoginSuccess>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Start the animation
    _animationController.forward();

    // Navigate to home after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: Responsive.horizontal(context, 100),
                      height: Responsive.vertical(context, 100),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        size: Responsive.font(context, 50),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: Responsive.vertical(context, 32)),
                    
                    // Success Title
                    Text(
                      'Login Successful',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 26),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E3A59),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: Responsive.vertical(context, 12)),
                    
                    // Welcome Message
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontal(context, 32),
                      ),
                      child: Text(
                        'Welcome back! You have been successfully authenticated.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.font(context, 16),
                          color: const Color(0xFF64748B),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.vertical(context, 48)),
                    
                    // Progress Indicator
                    SizedBox(
                      width: Responsive.horizontal(context, 24),
                      height: Responsive.vertical(context, 24),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5271FF)),
                      ),
                    ),
                    SizedBox(height: Responsive.vertical(context, 16)),
                    
                    // Redirecting Text
                    Text(
                      'Taking you to your dashboard...',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 14),
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}