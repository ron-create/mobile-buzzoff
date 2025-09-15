import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../actions/profile_page_action.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic> userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final details = await ProfilePageAction.fetchUserDetails(user.id);
      setState(() {
        userDetails = details;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Header Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + Responsive.vertical(context, 50),
                    bottom: Responsive.vertical(context, 28),
                    left: Responsive.padding(context, 20),
                    right: Responsive.padding(context, 20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      Container(
                        width: Responsive.screenWidth(context) * 0.22,
                        height: Responsive.screenWidth(context) * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: userDetails['profile_picture'] != null
                              ? Image.network(
                                  userDetails['profile_picture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.white.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        color: AppColors.white,
                                        size: Responsive.icon(context, 40),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: AppColors.white.withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.white,
                                    size: Responsive.icon(context, 40),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: Responsive.padding(context, 20)),
                      // Name, Phone, See personal info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${userDetails['first_name']} ${userDetails['last_name']}",
                              style: TextStyle(
                                fontSize: Responsive.font(context, 20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: Responsive.vertical(context, 6)),
                            Text(
                              userDetails['phone'],
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: Responsive.font(context, 15),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: Responsive.vertical(context, 12)),
                            GestureDetector(
                              onTap: () {
                                ProfilePageAction.navigateToProfile(context);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See personal info',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      fontSize: Responsive.font(context, 14),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu List
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: Responsive.vertical(context, 24)),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        _buildSimpleMenuItem(Icons.lock, "Privacy Policy", context),
                        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                        _buildSimpleMenuItem(Icons.settings, "Settings", context),
                        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                        _buildSimpleMenuItem(Icons.help, "Help", context),
                        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                        _buildSimpleMenuItem(Icons.logout, "Logout", context, isLogout: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSimpleMenuItem(IconData icon, String title, BuildContext context, {bool isLogout = false}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: Responsive.vertical(context, 14), // slightly less vertical padding
      ),
      leading: Padding(
        padding: EdgeInsets.only(left: Responsive.padding(context, 24)),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : Theme.of(context).primaryColor,
          size: 22, // smaller icon
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.font(context, 15), // smaller font
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: !isLogout ? Padding(
        padding: EdgeInsets.only(right: Responsive.padding(context, 24)),
        child: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18), // smaller chevron
      ) : null,
      onTap: () async {
        if (isLogout) {
          final shouldLogout = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + Responsive.vertical(context, 40),
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
                  
                  // Icon
                  Container(
                    width: Responsive.horizontal(context, 60),
                    height: Responsive.vertical(context, 60),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: const Color(0xFFE53935),
                      size: Responsive.icon(context, 30),
                    ),
                  ),
                  SizedBox(height: Responsive.vertical(context, 20)),
                  
                  // Title
                  Text(
                    'Logout Confirmation',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: Responsive.vertical(context, 12)),
                  
                  // Message
                  Text(
                    'Are you sure you want to logout from your account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 14),
                      color: const Color(0xFF7F8C8D),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: Responsive.vertical(context, 30)),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
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
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Logout',
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
            ),
          );
          if (shouldLogout == true) {
            ProfilePageAction.logout(context);
          }
        } else {
          switch (title) {
            case "Privacy Policy":
              ProfilePageAction.navigateToPrivacyPolicy(context);
              break;
            case "Settings":
              ProfilePageAction.navigateToSettings(context);
              break;
            case "Help":
              ProfilePageAction.navigateToHelp(context);
              break;
          }
        }
      },
    );
  }
}
