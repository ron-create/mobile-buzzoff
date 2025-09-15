import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';

class LoginFailed extends StatefulWidget {
  final String status;
  final String message;
  
  const LoginFailed({
    super.key,
    required this.status,
    required this.message,
  });

  @override
  State<LoginFailed> createState() => _LoginFailedState();
}

class _LoginFailedState extends State<LoginFailed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBDDDFC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.padding(context, 20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Icon
              Container(
                width: Responsive.horizontal(context, 120),
                height: Responsive.vertical(context, 120),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: Responsive.icon(context, 60),
                ),
              ),
              SizedBox(height: Responsive.vertical(context, 30)),
              
              // Status Title
              Text(
                _getStatusTitle(),
                style: TextStyle(
                  fontSize: Responsive.font(context, 24),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.vertical(context, 15)),
              
              // Status Message
              Container(
                padding: EdgeInsets.all(Responsive.padding(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 16),
                    color: const Color(0xFF2C3E50),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: Responsive.vertical(context, 40)),
              
              // Action Buttons
              if (widget.status.toLowerCase() == 'pending') ...[
                // For pending status, show contact info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Responsive.padding(context, 16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2196F3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFF2196F3),
                        size: Responsive.icon(context, 24),
                      ),
                      SizedBox(height: Responsive.vertical(context, 8)),
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(height: Responsive.vertical(context, 4)),
                      Text(
                        'Barangay Health Center\nPhone: (046) XXX-XXXX',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 12),
                          color: const Color(0xFF1976D2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.vertical(context, 20)),
              ] else if (widget.status.toLowerCase() == 'deleted' || 
                        widget.status.toLowerCase() == 'deactivated') ...[
                // For deleted/deactivated status, show contact info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Responsive.padding(context, 16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9800), width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.contact_support_rounded,
                        color: const Color(0xFFFF9800),
                        size: Responsive.icon(context, 24),
                      ),
                      SizedBox(height: Responsive.vertical(context, 8)),
                      Text(
                        'Contact City Health Office',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                      SizedBox(height: Responsive.vertical(context, 4)),
                      Text(
                        'City Health Office\nPhone: (046) XXX-XXXX\nEmail: health@city.gov.ph',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 12),
                          color: const Color(0xFFE65100),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.vertical(context, 20)),
              ],
              
              // Back to Login Button
              SizedBox(
                width: double.infinity,
                height: Responsive.vertical(context, 50),
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A89A7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 16),
                      fontWeight: FontWeight.bold,
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

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'deleted':
        return const Color(0xFFE53935); // Red
      case 'deactivated':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFFE53935); // Red
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'deleted':
        return Icons.delete_forever_rounded;
      case 'deactivated':
        return Icons.block_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  String _getStatusTitle() {
    switch (widget.status.toLowerCase()) {
      case 'pending':
        return 'Account Pending';
      case 'deleted':
        return 'Account Deleted';
      case 'deactivated':
        return 'Account Deactivated';
      default:
        return 'Access Denied';
    }
  }
}
