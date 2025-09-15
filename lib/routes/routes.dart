import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';

import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/userpages/main_screen.dart';
import '../pages/userpages/breeding_site.dart';
import '../pages/userpages/dengue_case.dart';
import '../pages/userpages/report_page.dart';
import '../pages/flashscreen/registration_success.dart'; // Import RegistrationSuccessPage
import '../pages/flashscreen/login_sucess.dart'; // Import LoginSuccessPage
import '../pages/flashscreen/login_failed.dart'; // Import LoginFailedPage
import '../pages/userpages/notifications_page.dart'; // Add this import
import '../pages/flashscreen/pending.dart'; // Import PendingScreen

import '../pages/set_up.dart';
import '../pages/set_home.dart';
import '../pages/userpages/educational_content.dart';
import '../pages/userpages/barangay_updates.dart';
import '../pages/userpages/map_quick_access.dart';
import '../pages/userpages/profile_settings.dart';
import '../pages/userpages/privacy_policy.dart';
import '../pages/userpages/settings.dart';
import '../pages/userpages/help.dart';
import '../pages/userpages/announcements_page.dart';
import '../pages/userpages/proof_of_residency.dart'; // Correct import for ProofOfResidency

import '../pages/terms_page.dart';
import '../pages/privacy_page.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Check if user is authenticated
    final isAuthenticated = supabase.auth.currentUser != null;
    final isLoginRoute = state.matchedLocation == '/';
    final isRegisterRoute = state.matchedLocation == '/register';
    final isRegistrationSuccessRoute = state.matchedLocation == '/registration-success';
    final isLoginSuccessRoute = state.matchedLocation == '/login-success';
    final isLoginFailedRoute = state.matchedLocation == '/login-failed';
    final isSetupRoute = state.matchedLocation == '/setup-account';
    final isPendingRoute = state.matchedLocation == '/pending';

    // If user is not authenticated and trying to access protected routes
    if (!isAuthenticated && 
        !isLoginRoute && 
        !isRegisterRoute && 
        !isRegistrationSuccessRoute && 
        !isLoginSuccessRoute && 
        !isLoginFailedRoute && 
        !isSetupRoute &&
        !isPendingRoute) {
      return '/';
    }

    // If user is authenticated and trying to access auth routes
    if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
      return '/home';
    }

    return null;
  },
  routes: [
    // Login Page
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),

    // Register Page
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // ✅ Registration Success Page (Splash After Register)
    GoRoute(
      path: '/registration-success',
      builder: (context, state) => const RegistrationSuccessPage(),
    ),

    // ✅ Login Success Page (Splash After Login)
    GoRoute(
      path: '/login-success',
      builder: (context, state) => const LoginSuccess(),
    ),

    // ✅ Login Failed Page (Status Error)
    GoRoute(
      path: '/login-failed',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text("Missing status data")),
          );
        }
        return LoginFailed(
          status: extra['status'] ?? 'unknown',
          message: extra['message'] ?? 'Unknown error occurred',
        );
      },
    ),

    // ✅ Setup Account Page (Step 2)
    GoRoute(
      path: '/setup-account',
      builder: (context, state) => const SetUp(),
    ),


GoRoute(
  path: '/set-home',
  builder: (context, state) {
    final userData = state.extra as Map<String, dynamic>?; // ✅ Kunin ang extra data
    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text("Missing user data")),
      );
    }
    return SetHome(userData: userData); // ✅ I-pass sa SetHome
  },
),



    // Main Screen with Bottom Navigation
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(),
    ),

    // Breeding Site Page
    GoRoute(
      path: '/breeding-site',
      builder: (context, state) => BreedingSite(),
    ),

    // Dengue Case Page
    GoRoute(
      path: '/dengue-case',
      builder: (context, state) => DengueCase(),
    ),

    // Report Page
    GoRoute(
      path: '/report-page',
      builder: (context, state) => ReportPage(),
    ),

    // Educational Content Page
    GoRoute(
      path: '/educational-content',
      builder: (context, state) => const EducationalContentPage(),
    ),

    // Barangay Updates Page
    GoRoute(
      path: '/barangay-updates',
      builder: (context, state) => const BarangayUpdatesPage(),
    ),

    // Map Quick Access Page
    GoRoute(
      path: '/map-quick-access',
      builder: (context, state) => const MapQuickAccessPage(),
    ),

    // Profile Page
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileSettingsPage(),
    ),

    // Profile Settings Page (for settings navigation)
    GoRoute(
      path: '/profile-settings',
      builder: (context, state) => const ProfileSettingsPage(),
    ),

    // Privacy Policy Page
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),

    // Settings Page
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // Help Page
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpPage(),
    ),

    // Announcements Page
    GoRoute(
      path: '/announcements',
      builder: (context, state) {
        final barangayId = state.extra as String?;
        if (barangayId == null) {
          return const Scaffold(
            body: Center(child: Text("Missing barangay ID")),
          );
        }
        return AnnouncementsPage(barangayId: barangayId);
      },
    ),

    // Notifications Page
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    // Terms of Service Page
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsPage(),
    ),
    // Privacy Policy Page
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPage(),
    ),
    GoRoute(
      path: '/proof-of-residency',
      builder: (context, state) {
        final userData = state.extra as Map<String, dynamic>?;
        if (userData == null) {
          return const Scaffold(
            body: Center(child: Text("Missing user data for proof of residency")),
          );
        }
        return ProofOfResidency(userData: userData);
      },
    ),

    // Pending Screen
    GoRoute(
      path: '/pending',
      builder: (context, state) {
        final userId = state.extra as String?;
        if (userId == null) {
          return const Scaffold(
            body: Center(child: Text("Missing user ID for pending screen")),
          );
        }
        return PendingScreen(userId: userId);
      },
    ),
  ],
);
