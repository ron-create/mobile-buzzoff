import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase/supabase_config.dart';
import 'package:go_router/go_router.dart';
import '../../actions/home_page_actions.dart'; // Import the actions
import 'dart:math' show pi, cos, sin;
import '../../actions/announcement_actions.dart';
import '../components/announcement_modal.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../../actions/educational_content_actions.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../actions/report_page_actions.dart';
import '../components/report_selection_modal.dart';
import '../components/fading_line.dart';
import '../components/infographics_card.dart';
import '../flashscreen/pending.dart';
import 'chatbot_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final User? user;
  late Map<String, dynamic> userDetails;
  late String barangayName;
  bool isLoading = true;
  List<Map<String, dynamic>> announcements = [];
  int unviewedContentCount = 0;
  int unreadNotificationsCount = 0;
  final EducationalContentAction _educationalAction = EducationalContentAction();

  @override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser;
    userDetails = {};
    barangayName = '';

    if (user != null) {
      fetchUserDetails();
      _checkUnviewedContent();
      _checkUnreadNotifications();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }
  }

  Future<void> fetchUserDetails() async {
    final userDetailsResponse = await HomePageActions.fetchUserDetails(user!.id);
    print('Debug - User Details Response: $userDetailsResponse'); // Debug log
    print('Debug - Barangay ID: ${userDetailsResponse['barangay_id']}'); // Debug log
    
    // Check if profile setup is complete
    final firstName = userDetailsResponse['first_name'];
    final lastName = userDetailsResponse['last_name'];
    
    print('Debug - Profile completion check:');
    print('   - first_name: $firstName (type: ${firstName.runtimeType})');
    print('   - last_name: $lastName (type: ${lastName.runtimeType})');
    print('   - first_name is null: ${firstName == null}');
    print('   - last_name is null: ${lastName == null}');
    print('   - first_name is empty string: ${firstName == ""}');
    print('   - last_name is empty string: ${lastName == ""}');
    
    if (firstName == null || lastName == null || firstName.toString().trim().isEmpty || lastName.toString().trim().isEmpty) {
      print('⚠️ Profile setup incomplete - redirecting to setup account page');
      print('   - Condition met: firstName is null/empty OR lastName is null/empty');
      // Redirect to setup page for incomplete profile
      if (mounted) {
        print('   - Widget is mounted, redirecting to /setup-account');
        print('   - ABOUT TO REDIRECT NOW...');
        context.go('/setup-account');
        print('   - REDIRECT CALLED - if you see this, redirect might not be working');
        return;
      } else {
        print('   - Widget is not mounted, cannot redirect');
      }
    } else {
      print('✅ Profile setup is complete');
      print('   - Both first_name and last_name have valid values');
    }
    
    // Check if user status is pending
    final userStatus = userDetailsResponse['status'];
    print('Debug - User status check:');
    print('   - status: $userStatus (type: ${userStatus.runtimeType})');
    
    if (userStatus == 'Pending') {
      print('⚠️ User status is pending - redirecting to pending screen');
      if (mounted) {
        print('   - Widget is mounted, redirecting to /pending');
        print('   - ABOUT TO REDIRECT NOW...');
        context.go('/pending', extra: user!.id);
        print('   - REDIRECT CALLED - if you see this, redirect might not be working');
        return;
      } else {
        print('   - Widget is not mounted, cannot redirect');
      }
    } else {
      print('✅ User status is not pending: $userStatus');
    }
    
    final barangayNameResponse = await HomePageActions.fetchBarangayName(userDetailsResponse['barangay_id']);
    print('Debug - Barangay Name Response: $barangayNameResponse'); // Debug log

    setState(() {
      userDetails = userDetailsResponse;
      barangayName = barangayNameResponse;
      isLoading = false;
    });

    // Fetch announcements after we have the user details
    await fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    try {
      print('Debug - Fetching announcements with barangay_id: ${userDetails['barangay_id']}'); // Debug log
      
      if (userDetails['barangay_id'] == null) {
        print('Warning: No barangay_id available for user');
        return;
      }

      final fetchedAnnouncements = await AnnouncementActions.fetchAnnouncements(
        barangayId: userDetails['barangay_id'].toString(),
        limit: 3,
      );
      setState(() {
        announcements = fetchedAnnouncements;
      });
    } catch (e) {
      print('Error fetching announcements: $e');
    }
  }

  Future<void> _checkUnviewedContent() async {
    if (user != null) {
      final count = await _educationalAction.getUnviewedContentCount(user!.id);
      if (mounted) {
        setState(() {
          unviewedContentCount = count;
        });
      }
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      // Get user_id from users table
      final userResponse = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', user!.id)
          .maybeSingle();

      if (userResponse == null) return;

      final userId = userResponse['id'];

      // Get resident_id
      final residentResponse = await supabase
          .from('resident')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (residentResponse == null) return;

      final residentId = residentResponse['id'];

      // Count unread notifications
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('resident_id', residentId)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          unreadNotificationsCount = response.length;
        });
      }
    } catch (e) {
      debugPrint('Error checking unread notifications: $e');
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return const Color(0xFFFF6B6B);
      case 'event':
        return const Color(0xFF7A9CB6);
      case 'general':
      default:
        return const Color(0xFF384949);
    }
  }

  void _showAnnouncementModal(Map<String, dynamic> announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnnouncementModal(
        title: announcement['title'],
        body: announcement['body'],
        fullName: announcement['full_name'],
        type: announcement['type'],
        file: announcement['file'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchUserDetails();
                await _checkUnviewedContent();
              },
              color: AppColors.primary,
              backgroundColor: AppColors.white,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Welcome Section (moved from AppBar)
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 20,
                            left: Responsive.padding(context, 20),
                            right: Responsive.padding(context, 20),
                            bottom: Responsive.padding(context, 20),
                          ),
                          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  // Profile Image
                  Container(
                    width: Responsive.screenWidth(context) * 0.12,
                    height: Responsive.screenWidth(context) * 0.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: userDetails['profile'] != null
                          ? Image.network(
                              userDetails['profile'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF384949),
                                        const Color(0xFF7A9CB6),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: Responsive.icon(context, 24),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF384949),
                                    const Color(0xFF7A9CB6),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: Responsive.icon(context, 24),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: Responsive.padding(context, 12)),
                  // Welcome Text
                  Expanded(
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                                            style: AppTextStyles.body.copyWith(color: Colors.black87, fontSize: Responsive.font(context, 14)),
                ),
                Text(
                  "${userDetails['first_name']} ${userDetails['last_name']}",
                  style: AppTextStyles.heading2.copyWith(
                                              color: Colors.black,
                    fontSize: Responsive.font(context, 18),
                  ),
                          overflow: TextOverflow.ellipsis,
                ),
              ],
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                                    icon: Icon(Icons.notifications_outlined, color: Colors.black, size: Responsive.icon(context, 24)),
                  onPressed: () {
                    context.push('/notifications');
                  },
                ),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: Responsive.padding(context, 8),
                    top: Responsive.padding(context, 8),
                    child: Container(
                      padding: EdgeInsets.all(Responsive.padding(context, 4)),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: Responsive.padding(context, 16),
                        minHeight: Responsive.padding(context, 16),
                      ),
                      child: Text(
                        unreadNotificationsCount > 9 ? '9+' : unreadNotificationsCount.toString(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: Responsive.font(context, 10),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
                        


                        // Barangay Info Section
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.padding(context, 20),
                            vertical: Responsive.vertical(context, 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Brgy. $barangayName",
                                style: AppTextStyles.heading2.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF384949),
                                  fontSize: Responsive.font(context, 18),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${HomePageActions.getCurrentMonth()} ${DateTime.now().day}, ${DateTime.now().year}',
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.font(context, 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Fading Line below barangay info section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                          child: FadingLine(
                            height: 2.0,
                            color: const Color(0xFF4FC3F7), // Blue color
                            opacity: 0.7,
                          ),
                        ),
                        SizedBox(height: Responsive.vertical(context, 20)),

                        // Dengue Infographics Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: SupabaseInfographicsService.getDengueInfographics(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              
                              if (snapshot.hasError) {
                                print('Error in FutureBuilder: ${snapshot.error}');
                                return const SizedBox.shrink();
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              final infographics = snapshot.data!;
                              
                              return FlutterCarousel(
                                options: CarouselOptions(
                                  height: 250.0,
                                  viewportFraction: 0.9,
                                  showIndicator: true,
                                  autoPlay: true,
                                  autoPlayInterval: const Duration(seconds: 6),
                                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                  autoPlayCurve: Curves.fastOutSlowIn,
                                ),
                                items: infographics.map((infographic) {
                                  return InfographicsCard(
                                    infographic: infographic,
                                    compact: true,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: Responsive.vertical(context, 16)),

                        // Barangay Announcements Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with title and see all button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Barangay Announcements',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.font(context, 16),
                                      color: const Color(0xFF384949),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => context.push('/announcements', extra: userDetails['barangay_id']),
                                    icon: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: Responsive.icon(context, 14),
                                      color: const Color(0xFF7A9CB6),
                                    ),
                                    label: Text(
                                      'See all',
                                      style: TextStyle(
                                        color: const Color(0xFF7A9CB6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: Responsive.font(context, 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.vertical(context, 8)),
                              
                              // Announcements Carousel
                              if (announcements.isEmpty)
                                Center(
                                  child: Text(
                                    'No announcements yet',
                                    style: TextStyle(
                                      color: Color(0xFF384949),
                                      fontStyle: FontStyle.italic,
                                      fontSize: Responsive.font(context, 14),
                                    ),
                                  ),
                                )
                              else
                                FlutterCarousel(
                                  options: CarouselOptions(
                                    height: 140.0, // Reduced height to save space
                                    viewportFraction: 0.9,
                                    showIndicator: true,
                                    autoPlay: true,
                                    autoPlayInterval: const Duration(seconds: 5),
                                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                    autoPlayCurve: Curves.fastOutSlowIn,
                                  ),
                                  items: announcements.take(3).map((announcement) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 5.0)),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () => _showAnnouncementModal(announcement),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Stack(
                                          children: [
                                            // Background Image or Color
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: announcement['file'] != null
                                                  ? Image.network(
                                                      announcement['file'],
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            _getTypeColor(announcement['type']).withOpacity(0.1),
                                                            Colors.white,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            // Content Overlay
                                            Container(
                                              padding: EdgeInsets.all(Responsive.padding(context, 16)),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.7),
                                                  ],
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    announcement['title'] ?? 'No title',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: Responsive.font(context, 18),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),

                        // Quick Access Section
                        Padding(
                          padding: EdgeInsets.all(Responsive.padding(context, 20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Access',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.font(context, 16),
                                  color: const Color(0xFF384949),
                                ),
                              ),
                              SizedBox(height: Responsive.vertical(context, 16)),
                              // Horizontal scrollable quick access items
                              SizedBox(
                                height: Responsive.vertical(context, 76), // Small height for the cards
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 4)),
                                  itemCount: 4,
                                  itemBuilder: (context, index) {
                                    return _buildQuickAccessItem(context, index);
                                  },
                                ),
                              ),
                              SizedBox(height: Responsive.vertical(context, 30)),
                              // Quick Report Section
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(Responsive.padding(context, 24)),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF384949).withOpacity(0.05),
                                      const Color(0xFF7A9CB6).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF7A9CB6).withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
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
                                        Container(
                                          padding: EdgeInsets.all(Responsive.padding(context, 10)),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF384949),
                                                const Color(0xFF7A9CB6),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF384949).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.flash_on_rounded,
                                            color: Colors.white,
                                            size: Responsive.icon(context, 22),
                                          ),
                                        ),
                                        SizedBox(width: Responsive.padding(context, 16)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Quick Report',
                                                style: TextStyle(
                                                  fontSize: Responsive.font(context, 20),
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF384949),
                                                ),
                                              ),
                                              Text(
                                                'Report dengue cases or breeding sites instantly',
                                                style: TextStyle(
                                                  fontSize: Responsive.font(context, 14),
                                                  color: const Color(0xFF384949).withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: Responsive.vertical(context, 20)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF384949),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: Responsive.padding(context, 24),
                                                vertical: Responsive.vertical(context, 16),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 6,
                                              shadowColor: const Color(0xFF384949).withOpacity(0.3),
                                            ),
                                            icon: Icon(
                                              Icons.add_alert_rounded,
                                              size: Responsive.icon(context, 22),
                                            ),
                                            label: Text(
                                              'Report Now',
                                              style: TextStyle(
                                                fontSize: Responsive.font(context, 16),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                builder: (context) => ReportSelectionModal(
                                                  onSelectReportType: (String reportType) {
                                                    if (reportType == 'Dengue Case') {
                                                      context.push('/dengue-case');
                                                    } else if (reportType == 'Breeding Site') {
                                                      context.push('/breeding-site');
                                                    }
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Removed the information icon here
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chatbot Button (now launches browser directly)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.85,
                              child: const ChatbotSheet(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/buzzAI.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, int index) {
    // Update the itemData and gradients for Quick Access cards:
    final List<Map<String, dynamic>> itemData = [
      {
        'title': 'Report',
        'icon': Icons.report_problem_rounded,
        'color': const Color(0xFF4FC3F7), // Blue (medical/cool)
        'gradient': [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
        'description': 'Report cases',
      },
      {
        'title': 'Map',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF26A69A), // Teal
        'gradient': [const Color(0xFF26A69A), const Color(0xFF80CBC4)],
        'description': 'View hotspots',
      },
      {
        'title': 'Updates',
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF9575CD), // Purple
        'gradient': [const Color(0xFF9575CD), const Color(0xFF7E57C2)],
        'description': 'Barangay activities',
      },
      {
        'title': 'Learn',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF64B5F6), // Lighter blue
        'gradient': [const Color(0xFF64B5F6), const Color(0xFF1976D2)],
        'description': 'Educational content',
      },
    ];

    // Use a consistent, modern rounded border for all cards
    final BorderRadius cardRadius = BorderRadius.circular(16);
    final List<Gradient> gradients = [
      LinearGradient(colors: [itemData[0]['color'], itemData[0]['gradient'][1]]),
      LinearGradient(colors: [itemData[1]['color'], itemData[1]['gradient'][1]]),
      LinearGradient(colors: [itemData[2]['color'], itemData[2]['gradient'][1]]),
      LinearGradient(colors: [itemData[3]['color'], itemData[3]['gradient'][1]]),
    ];

    // Animation controller for tap scale effect
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.96),
          onTapUp: (_) => setState(() => scale = 1.0),
          onTapCancel: () => setState(() => scale = 1.0),
          onTap: () {
            switch (index) {
              case 0:
                context.push('/report-page');
                break;
              case 1:
                context.push('/map-quick-access');
                break;
              case 2:
                context.push('/barangay-updates');
                break;
              case 3:
                context.push('/educational-content');
                _checkUnviewedContent();
                break;
            }
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: Responsive.screenWidth(context) * 0.4,
              height: Responsive.vertical(context, 68), // Even smaller height
              margin: EdgeInsets.only(right: Responsive.padding(context, 12)),
              decoration: BoxDecoration(
                gradient: gradients[index],
                borderRadius: cardRadius,
                boxShadow: [
                  BoxShadow(
                    color: itemData[index]['color'].withOpacity(0.13),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: EdgeInsets.only(
                      left: Responsive.padding(context, 14),
                      right: Responsive.padding(context, 14),
                      top: Responsive.vertical(context, 14),
                      bottom: Responsive.vertical(context, 8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: Responsive.vertical(context, 4)),
                        Text(
                          itemData[index]['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.font(context, 14),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: Responsive.vertical(context, 2)),
                        Text(
                          itemData[index]['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: Responsive.font(context, 10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon circle inside card, top right
                  Positioned(
                    top: 6,
                    right: 8,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: itemData[index]['color'],
                        boxShadow: [
                          BoxShadow(
                            color: itemData[index]['color'].withOpacity(0.25),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          itemData[index]['icon'],
                          color: Colors.white,
                          size: 28, // Bigger icon
                        ),
                      ),
                    ),
                  ),
                  // (Optional) Badge for unviewed content
                  if (index == 3 && unviewedContentCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unviewedContentCount > 9 ? '9+' : unviewedContentCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
      },
    );
  }

  // Show profile menu with options
  void _showProfileMenu(BuildContext context) async {
    final selectedOption = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 50.0, 0.0, 0.0), // Position menu
      items: [
        const PopupMenuItem<String>(
          value: 'settings',
          child: Text('Settings'),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout'),
        ),
      ],
    );

    // Handle the selected option
    if (selectedOption == 'logout') {
      await HomePageActions.logout(context);

      // Add a delay before navigating to prevent UI conflicts
      Future.delayed(Duration(milliseconds: 100), () {
        GoRouter.of(context).go('/'); // ✅ Ensures navigation works
      });
    } else if (selectedOption == 'settings') {
      context.push('/settings'); // ✅ Make sure '/settings' exists in routes
    }
  }
}

// Add this class at the end of the file
class CardPatternPainter extends CustomPainter {
  final Color color;

  CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw hexagon pattern
    final double hexSize = 20.0;
    final double hexWidth = hexSize * 2;
    final double hexHeight = hexSize * 1.732; // sqrt(3) * hexSize

    for (double y = -hexHeight; y < size.height + hexHeight; y += hexHeight * 0.75) {
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth * 0.75) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * (pi / 3);
          final pointX = x + hexSize * cos(angle);
          final pointY = y + hexSize * sin(angle);
          if (i == 0) {
            path.moveTo(pointX, pointY);
          } else {
            path.lineTo(pointX, pointY);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }

    // Draw small dots in the center of some hexagons
    for (double y = -hexHeight; y < size.height + hexHeight; y += hexHeight * 1.5) {
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth * 1.5) {
        if ((x + y) % (hexWidth * 2) < hexWidth) {
          canvas.drawCircle(
            Offset(x, y),
            1.5,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
